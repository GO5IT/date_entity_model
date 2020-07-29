#!/usr/bin/perl

use strict;
use warnings;
use RDF::Trine;
use LWP::UserAgent;
use Data::Dumper; 
use utf8;

package DateRDFUtils;

##################################################
## Common variables for RDF::Trine 
##################################################

our $MEDIATYPERDFXML = 'application/rdf+xml';

### used for RDF::Trine::Serializer
our $namespacehash = {
      dc => 'http://purl.org/dc/elements/',
	dcterms => 'http://purl.org/dc/terms/',
	rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
	rdfs => 'http://www.w3.org/2000/01/rdf-schema#',
	skos => 'http://www.w3.org/2004/02/skos/core#',
	time => 'http://www.w3.org/2006/time#',
	xsd => 'http://www.w3.org/2001/XMLSchema#',
	foaf => 'http://xmlns.com/foaf/0.1/' ,
      owl => 'http://www.w3.org/2002/07/owl#',
      dbo => 'http://dbpedia.org/ontology/',
	prov => 'http://www.w3.org/ns/prov#',
};

## for each entry in $namespacehash: automatically create namespace objects trine-namespaces ... 
## from this predicate names can be derived. 
our $nsobjects={};
foreach my $prefix (keys %$DateRDFUtils::namespacehash) {
   $nsobjects->{$prefix} = RDF::Trine::Namespace->new($DateRDFUtils::namespacehash->{$prefix});
}  


###########################################################
### create my own $ua used for pre-testing urls
our $useragent = LWP::UserAgent->new;
        $useragent->default_header('Accept-Charset'  => 'utf-8');
        $useragent->default_header('Accept-Language' => "en");
        $useragent->default_header('Accept' => $MEDIATYPERDFXML );

## add_triples_from_external_sameAs ( $model, $parser, $sameas, $filter, $predstoadd, $pretestURL, $logtag, $opt_d, $log ) 
##
## 1) in $model: look for skos:exactMatch or owl:sameAs pointing to external URL
## 2) retrieve data from external URL
## 3) add selected predicates from external URL to $model 
## 
## Arguments:
## model	      A RDF::Trine::Model
## parser         A RDF::Trine::Parser
## sameas	      Predicate to use for determining "sameness" - e.g. skos:axactMatch or owl:sameAs
## filter         A string used for further filtering down the statements found by searching for $sameas
##	            e.g. "http://dbpedia.org" 
## predstoadd     A arrayref enlisting all the predicates to be added;
##	            iff empty arrayref is added: add ALL predicates
## pretestURL	flag if a separate HTTP-GET will be called on external URLs:
##                this is the only way to detect and handle HTTP-Errors ;-(
##			On the other hand it doubles the number of calls :-(             
## logtag         A string which is just used in the supply a tag which is used in the print-outs of the log. E.g. "DBpedia" 
## opt_d          Debug flag
## log            A logging-object : a hashref holding log-info (NOT YET USED !)
sub add_triples_from_external_sameAs {
   my $model      = shift; 
   my $parser     = shift;  
   my $sameas     = shift;   
   my $filter     = shift;   
   my $predstoadd = shift; 
   my $pretestURL = shift; 
   my $logtag     = shift; 
   my $opt_d      = shift;   
   my $log        = shift;      

   $logtag = "" unless $logtag; # to avoid error messages when uninitialized 

   print "$logtag\tNumber of total RDF - statements in model BEFORE: " . $model->size . "\n";
   ## get all subjects in model
   my @subjects = $model->subjects(undef, undef);
   print "$logtag\tNumber of SUBJECTS in model BEFORE: " . scalar(@subjects) . "\n";
   SUBJECT: foreach my $subject (@subjects) {
       print "$logtag\t==== subject: $subject ====\n";
       my $iter = $model->get_statements($subject, $sameas, undef);       
       SAMEAS: while (my $st = $iter->next) {
          my $sub  = $st->subject;
          my $pred = $st->predicate;
          my $obj  = $st->object;  
          ### only consider objects which match $filter 
          if ($obj->as_string =~ m{$filter}) {
               print "\t$logtag: selected:\t$pred\t$obj\n";
          } else {
             print "\t$logtag: filtered:\t$pred\t$obj\n";
             next SAMEAS; 
          }
          ### fetch the linked stuff in separate temporal model
          my $localmodel  = RDF::Trine::Model->temporary_model();
          my $lresponse;
          my $error = "";
          if ($pretestURL) {
              $error = pre_test_url_for_error($obj->uri_value, $useragent);
          }
          if ($error) {
               ### TODO: write info to logfile
               print "$logtag: LEIDER FEHLGESCHLAGEN:\t" . $obj->uri_value . "\t$error\n";
               next SAMEAS;
          }  else {
                # parse_url_into_model ( $url, $model [, %args] )
                # Retrieves the content from $url and attempts to parse the resulting RDF into $model 
                # using a parser chosen by the associated content media type.
                $lresponse = $parser->parse_url_into_model( $obj->uri_value, $localmodel, content_cb => \&content_callback );
          }
          ### now extract ALL relevant triples for localmodel 
          print "\n$logtag\tNumber of RDF - statements in LOCAL model: " . $localmodel->size . "\n";
          my $localiter = $localmodel->get_statements(undef, undef, undef);
          TRIPLE: while (my $lst = $localiter->next) {
    	        my $lsub  = $lst->subject;
    	        my $lpred = $lst->predicate;
    	        my $lobj  = $lst->object;
 
              if ($opt_d)  {
     	           print "lpred: $lpred\n";
     	           print Data::Dumper::Dumper($lpred);
     	           print "---\n";
              }

              ### filter! Only use those preds enumerated in @interestingpreds
              ### iff @interestingpreds is empty: add ALL triples 
              if ( not(@$predstoadd) or grep { $lpred->equal($_) } @$predstoadd ) {
                   print "$logtag\tHIT:\t\t$lpred\t$lobj\n"; # if ($opt_d);
	             ## add triple to GLOBAL model
                   $model->add_statement( RDF::Trine::Statement->new($subject, $lpred, $lobj) );
              }
           } # TRIPLE
          } # SAMEAS
        print "$logtag\tNumber of RDF - statements in model AFTER: " . $model->size . "\n";
  } # SUBJECT
}

## pre_test_url_for_error ($url, $useragent) 
## uses $useragent to test $url: returns FALSE (empty string) if successful and 
## the HTTP-Error otherwise.
## This is required because that's the only way to catch errors 
## from the HTTP-call: RDF::Trine::Parser->parse_url_into_mode just dies 
## when there is an error.
## If $useragent is not supplied, then $DateRDFUtils::useragent is used as default
sub pre_test_url_for_error {
  my $url = shift;
  my $ua  = shift;
  if ( ! $ua ) {
    $ua = $DateRDFUtils::useragent;
  }
  #  print "== testing $url ...\n";
  #   print "==ua==\n";
  #   print Data::Dumper::Dumper($ua);
  my $response = $ua->get($url);
  #  print "== tested $url ...\n";
  if ($response->is_success) {
    return "";
  }  else { 
    # print "== FAILED: " . $response->status_line . "\n";
    return $response->status_line;
  }
}


#parse_url_into_model ( $url, $model [, %args] )
#Retrieves the content from $url and attempts to parse the resulting RDF into $model using a parser chosen by the associated content media type.
#If %args contains a 'content_cb' key with a CODE reference value, that callback function will be called after a successful response as:
#$content_cb->( $url, $content, $http_response_object )
#If %args contains a 'useragent' key with a LWP::UserAgent object value, that object is used to retrieve the requested URL without any configuration (such as setting the Accept: header) which would ordinarily take place. Otherwise, the default user agent ("default_useragent" in RDF::Trine) is cloned and configured to retrieve content that will be acceptable to any available parser.i
#### Hannes: I tried to use the content_callback to catch Errors, but this does not work, because content_callback is only called 
#### when the UserAgent was SUCCESSFUL! I keep it here for convenience: it can be used for debugging
sub content_callback {
	my $url = shift;
	my $content = shift;
	my $http_response_object = shift;
	##### right now does NOTHING !!
	#  print "\n== cb: url ==\n";
	#  print Dumper $url;

	#  if ($http_response_object->is_success) {
	#    	print "response ist OK!\n";
	#  } else {
	#   	print "response hat ein FAIL:\n";
	#   	print $response->status_line . "\n\n\n";
	#  }

	##  if ($opt_d) {
	##    	print "\n== cb: content ==\n";
	##    	print Dumper $content;
	##  }

	##  if ($opt_d) {
	##  	print "\n== cb: http_response_object ==\n";
	##  	print Dumper $http_response_object;
	##  }

   return 1;
} 


###########################################################
###  Re-usable bits and pieces for Go's Date-to-RDF project

## default language for Month-Names etc.
our $DEFAULT_LANG="en";

## RDF-enclosing elements
our $rdfstart = <<"EOF";
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
   xmlns:dc="http://purl.org/dc/elements/"
   xmlns:dcterms="http://purl.org/dc/terms/"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
   xmlns:skos="http://www.w3.org/2004/02/skos/core#"
   xmlns:time="http://www.w3.org/2006/time#"
   xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
>
EOF
our $rdfend = "</rdf:RDF>";

####
## map month-number to name

my $mm2txt = {
  en => {
      "01" => "January",
      "02" => "February",
      "03" => "March",
      "04" => "April",
      "05" => "May",
      "06" => "June",
      "07" => "July",
      "08" => "August",
      "09" => "September",
      "10" => "October",
      "11" => "November",
      "12" => "December"
   },
   de => {
     "01" => "Januar",
     "02" => "Februar",
     "03" => "März",
     "04" => "April",
     "05" => "Mai",
     "06" => "Juni",
     "07" => "Juli",
     "08" => "August",
     "09" => "September",
     "10" => "Oktober",
     "11" => "November",
     "12" => "Dezember"
   }
};


##
my $wday2txt = {
  en => {
      1 => "Monday",
      2 => "Tuesday",
      3 => "Wednesday",
      4 => "Thursday",
      5 => "Friday",
      6 => "Saturday",
      7 => "Sunday",
   },
   de => {
     1 => "Montag",
     2 => "Dienstag",
     3 => "Mittwoch",
     4 => "Donnerstag",
     5 => "Freitag",
     6 => "Samstag",
     7 => "Sonntag",
   }
};

## map a number to a month-name
## optional language-parameter
sub mm2txt{
  my $mm = shift;
  my $lang = shift;
  $lang = $DEFAULT_LANG unless $lang;
  if (! defined $mm2txt->{$lang}) {
    print "# Error: Language not supported: $lang\n";
    exit;
  }
  ## handle 1 as 01 etc.
  $mm =~ s/^(\d)$/0$1/;
  my $result = $mm2txt->{ $lang }->{ $mm };
  if (! defined $result) {
    print "# Error: Month not valid: $mm\n";
    exit;
  }
  return $result;
}

## map cardinal number to ordinal : 1 -> 1st , 2 -> 2nd etc.
sub numeral2ordinal {
  my $th = shift;
  $th .=  "th";
  ## but make provision for 11th / 12th / 13th
  if ( $th =~ m/(^|[^1])[123]th$/ ) {
    $th =~ s/1th$/1st/;
    $th =~ s/2th$/2nd/;
    $th =~ s/3th$/3rd/;
  }
  return $th;
}


## map year to $decade
## simply remove last digit
sub year2decade{
  my $yyyy = shift;
  $yyyy =~ s/^(.+)\d$/$1/;
  return $yyyy;
}

sub year2semium{
  my $yyyy = shift;
  $yyyy =~ s/\d{2}$//;
  return $yyyy;
}

sub year2onedigit{
  my $yyyy = shift;
  $yyyy =~ s/\d{3}$//;
  return $yyyy;
}

sub year2firsttwo{
  my $yyyy = shift;
  $yyyy =~ s/\d{2}//;
  return $yyyy;
}

sub year2thirdone{
  my $yyyy = shift;
  $yyyy =~ s/\d{1}$//;
  $yyyy =~ s/\d{2}//;
  return $yyyy;
}
