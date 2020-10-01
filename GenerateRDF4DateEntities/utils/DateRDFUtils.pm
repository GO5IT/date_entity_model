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

############### Documentation FROM: https://metacpan.org/pod/RDF::Trine
## Create namespace objects
###   ### now in: $DateRDFUtils::namespacehash;  
#my $dc=RDF::Trine::Namespace->new('http://purl.org/dc/elements/');
#my $dcterms=RDF::Trine::Namespace->new('http://purl.org/dc/terms/');
#my $rdf=RDF::Trine::Namespace->new('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
#my $rdfs=RDF::Trine::Namespace->new('http://www.w3.org/2000/01/rdf-schema#');
#my $skos=RDF::Trine::Namespace->new('http://www.w3.org/2004/02/skos/core#');
#my $time=RDF::Trine::Namespace->new('http://www.w3.org/2006/time#');
#my $xsd=RDF::Trine::Namespace->new('http://www.w3.org/2001/XMLSchema#');
#my $foaf = RDF::Trine::Namespace->new( 'http://xmlns.com/foaf/0.1/' );

#### namespaces in serialisation.
#The valid key-values used in %options are specific to a particular serializer implementation. For serializers that support namespace declarations (to allow more concise serialization), use namespaces => \%namespaces in %options, where the keys of %namespaces are namespace names and the values are (partial) URIs. For serializers that support base URI declarations, use base_uri => $base_uri .

# alternatively:
# my $pred = RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name');
 
############## NAMESPACES: it is important that all NAMESPACE-Prefixes are managed here: 
############## they then can be used by RDF::Trine::Serializer
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
      wdt => 'http://www.wikidata.org/prop/direct/',
      wdtn => 'http://www.wikidata.org/prop/direct-normalized/',
};

## for each entry in $namespacehash: automatically create namespace objects trine-namespaces ... 
## from this, predicate names can be derived. 
our $nsobjects={};
foreach my $prefix (keys %$DateRDFUtils::namespacehash) {
   $nsobjects->{$prefix} = RDF::Trine::Namespace->new($DateRDFUtils::namespacehash->{$prefix});
}  

###########################################################
## substitutions used for tweaking 
## because it seems impossible to store "normal" substitution patterns like "s/PATTERN/SUBSTITUTION/" in a variable 
## we had to resort to storing it in a hash as "{ PATTERN => SUBSTITUTION }";

#### IMPORTANT: the SUBSTITUTION _must_ be written with double-quotes within single quotes, 
#### otherwise  s/PATTERN/SUBSTITUTION/ee will not work properly. 
#### i.e. '"subst"' . This is a feature, not a bug!

#### Format of the hash:   <REGEX-PATTEN> => <SUBSTITUTION> 
## case 1: AD_1 to AD_101 

our $tweak_urls_dbpedia = { 
	qr{http://dbpedia.org/resource/AD_(\d{1,2}|100|101)$} => '"http://dbpedia.org/resource/$1"',
};

### for testing tweak off
#$tweak_urls_dbpedia = { 
#	};

## $tweak object has a <PREDICATE> additional control-option : 
## <PREDICATE_AS_STRING> => {  <REGPATTERN1> =>  <SUBST1>, <REGEXPATTERN2> => <SUBST2> ... }
## for patterns which are to be applied on ALL predicates use "*" as <PREDICATE> 

### note: the keys in the hash must be strings, not objects. 
### therefore the property-URL is provided as string.
###
### btw.: instead of:
###       'http://www.wikidata.org/prop/direct-normalized/P244' 
### we also could write:
###        $DateRDFUtils::nsobjects->{'wdtn'}->P244->uri_value
### which would produce just the same URL-string!

our $tweak_obj_wdata = { 
    'http://www.wikidata.org/prop/direct-normalized/P244'  => {
              qr{/authorities/names/} => '"/authorities/subjects/"',
   },
};

###########################################################
### create my own $useragent used for pre-testing urls
#######  right now this is not used anymore... 
our $useragent = LWP::UserAgent->new(
           protocols_allowed => [ 'http', 'https' ] 
);

$useragent->default_header('Accept-Charset'  => 'utf-8');
$useragent->default_header('Accept-Language' => "en");
$useragent->default_header('Accept' => $DateRDFUtils::MEDIATYPERDFXML );

###################
##### ** THIS is the CENTRAL FUNCTION, which almost does the WHOLE JOB !!! **
###################
## add_triples_from_external_sameAs ( $model, $parser, $sameas, $filter, $predstoadd, $tweak_urls, $tweak_subj, $tweak_pred, $tweak_obj $logtag, $opt_d, $log, $opt_S, $opt_L ) 
##
## How add_triples_from_external_sameAs works:
## 1) in $model: look for all $sameAs (i.e. skos:exactMatch or owl:sameAs) pointing to external URLs
## 2) only proceed with those external URLS which match the string(s) mentioned in $filter 
## 3) retrieve data from external URL
## 4) add the predicates mentioned in $predstoadd from external URL to $model 
## 
## Arguments:
## model	      A RDF::Trine::Model
## parser         A RDF::Trine::Parser
## sameas	      Predicate to use for determining "sameness" - e.g. skos:exactMatch or owl:sameAs
## filter         A string used for further filtering down the statements found by searching for $sameas
##	            e.g. "http://dbpedia.org" 
## predstoadd     A arrayref enlisting all the predicates (found in the external resource) to be added to the $model;
##	            iff empty arrayref is added: add ALL predicates 
## tweak_urls 	A hashref enlisting PATTERN => SUBSTITUTION pairs  which are applied to a URL before fetching it
## tweak_subj     A hashref enlisting PATTERN => SUBSTITUTION pairs  which are applied to a SUBJECTS before adding them to the TripleStore
## tweak_pred     A hashref enlisting PATTERN => SUBSTITUTION pairs  which are applied to a PREDICAT-values before adding them to the TripleStore
## tweak_obj      A hashref enlisting PATTERN => SUBSTITUTION pairs  which are applied to a OBJECT-values   before adding them to the TripleStore          
## logtag         A string which is just used in the supply a tag which is used in the print-outs of the log. E.g. "DBpedia" 
## opt_d          Debug flag
## log            A logging-object : a hashref for collecting the log-info.
## opt_S          Skip number of subjects (for testing)
## opt_L          Limit number of subjects (for testing)
sub add_triples_from_external_sameAs {
   my $model      = shift; 
   my $parser     = shift;  
   my $sameas     = shift;   
   my $filter     = shift;   
   my $predstoadd = shift; 
   my $logtag     = shift;
   my $tweak_urls = shift;
   my $tweak_subj = shift;
   my $tweak_pred = shift;
   my $tweak_obj  = shift; 
   my $opt_d      = shift;   
   my $log        = shift;
   my $opt_S      = shift;
   my $opt_L	= shift;

   my $modelsize_before = 0;
   my $modelsize_after = 0;      

   $logtag = "" unless $logtag; # to avoid error messages when uninitialized 

   $modelsize_before = $model->size;

   print "STATS\t$logtag\tNumber of total RDF - statements in model BEFORE: " . $modelsize_before . "\n";
   ## get all subjects in model - and sort them by year !
   my @subjects = sort compare_subject_years  $model->subjects(undef, undef);
   my $number_of_subjects = scalar(@subjects);
   print "STATS\t$logtag\tNumber of SUBJECTS in model BEFORE: " . $number_of_subjects . "\n";
   my $subjectcount = 0;

   ## if skip AND limit: add skip to limit!
   if ($opt_L) { $opt_L += $opt_S };
   SUBJECT: foreach my $subject (@subjects) { 
       $subjectcount++;
       next SUBJECT if ($opt_S && $subjectcount <= $opt_S); ## skip
       last SUBJECT if ($opt_L && $subjectcount > $opt_L);  ## limit
       print "$logtag\t==== subject $subjectcount / $number_of_subjects : $subject ====\n";
       ## intialize $log   
       ## create a local hash for storing info per subject. 
	#                 '1_error' => "",
	#                 '2_triple-subj'  => ""
	#                 '3_triple-selected' => "",
	#		     '4_triple-actually_inserted' => "",
       my $llog = init_log_fields();
       if ( not defined ( $log->{ $subject->as_string }->{ $logtag }  ) ) { 
		$log->{ $subject->as_string }->{ $logtag } = $llog;
       } else {
	  $llog = $log->{ $subject->as_string }->{ $logtag } ;
       } 

       if ($modelsize_after) { $modelsize_before = $modelsize_after};
       my $iter = $model->get_statements($subject, $sameas, undef); 
      
       SAMEAS: while (my $st = $iter->next) {
          my $sub  = $st->subject;
          my $pred = $st->predicate;
          my $obj  = $st->object;  
          ### only consider objects which match $filter 
          if ($obj->as_string =~ m{$filter}) {
               print join("\t", "\t$logtag: selected as external reference:", $pred->as_string, $obj->as_string, "\n") if ($opt_d);
          } else {
              print join("\t", "\t$logtag: neglected as external reference:", $pred->as_string, $obj->as_string, "\n") if ($opt_d);
             next SAMEAS; 
          }
          ### tweak the url if necessary 
          my $tweaked_obj_uri = $obj->uri_value;
          ## important: apply_tweaks requires a REF ! 
	    my $tweak_url_subj = ""; ## iff url is tweaked - we also need to use the tweaked url for testing SUBJECT 
          my $url_was_tweaked = apply_tweaks( \$tweaked_obj_uri, $tweak_urls );

	    if ( $url_was_tweaked ) {
            if ($opt_d) {
			print join("\t", "$logtag:", "URI was tweaked from:", $obj->uri_value, "to", $tweaked_obj_uri, "\n");
            }
            $tweak_url_subj = new RDF::Trine::Node::Resource( $tweaked_obj_uri );
	    }

          ### fetch the linked stuff in separate temporal model
          $llog->{'0_url_sameAs'}  = $obj->uri_value;
          my $localmodel  = RDF::Trine::Model->temporary_model();
          my $lresponse;
          ## call parse_url_into_model() in a eval-block to catch HTTP exceptions!
          ## cf.  https://perlmaven.com/fatal-errors-in-external-modules
          eval {
		     # code that might throw exception
		     $lresponse = $parser->parse_url_into_model( $tweaked_obj_uri, $localmodel, content_cb => \&content_callback );
                 print "$logtag:\t\tparse_url_into_model() SUCCESS:\t" . $tweaked_obj_uri . "\n";
		     1;  # always return true to indicate success
		}
		or do {
		    # this block executes if eval did not return true (because of an exception)
		 
		    # save the exception and use 'Unknown failure' if the content of $@ was already
		    # removed
		    my $error = $@ || 'Unknown failure';
		    # report the exception and do something about it
		    print "$logtag:\t\tparse_url_into_model() FAILED:\t" . $tweaked_obj_uri . "\t$error\n";
		    $llog->{ '1_error' } .= "|$error|" ;       
		    next SAMEAS;   
		};
          ### now extract ALL relevant triples for localmodel        
          print "\nSTATS\t$logtag\tNumber of RDF - statements in LOCAL model: " . $localmodel->size . "\n" if ($opt_d); 
          my $localiter = $localmodel->get_statements(undef, undef, undef);
          my $triplecount_total = 0;  ## total number of statements
          my $triplecount_subj = 0;  ## number of statements with correct subject
          my $triplecount_selected = 0; ## number of statements with correct subject AND predicate
          TRIPLE: while (my $lst = $localiter->next) {
    	        my $lsub  = $lst->subject;
    	        my $lpred = $lst->predicate;
    	        my $lobj  = $lst->object;
 
              $triplecount_total++; 
#              if ($opt_d)  {
#     	           print "lpred: $lpred\n";
#     	           print Data::Dumper::Dumper($lpred);
#     	           print "---\n";
#              }

              if ( $lsub->equal($obj) or ( $tweak_url_subj && $lsub->equal($tweak_url_subj) ))  {
                      print "\n$logtag\tLSUBJECT MATCHES: ". $lsub->as_string() . "\n" if ($opt_d);          
	      } else {		        
                      print "\t$logtag\tLSUBJECT does not match: ". $lsub->as_string() . " -> ignored\n" if ($opt_d); 
		      next TRIPLE;
              }
            
              $triplecount_subj++;
              ### filter! Only use those preds enumerated in @interestingpreds
              ### iff @interestingpreds is empty: add ALL triples 
              if ( not(@$predstoadd) or grep { $lpred->equal($_) } @$predstoadd ) {
                   $triplecount_selected++;
                   print "$logtag\tHIT:\t\t" . $lpred->as_string . "\t" . $lobj->as_string ."\n" if ($opt_d);
 
                   ## check if $lpred is in $tweak_obj - and tweak the object value if necessary!
                   my $obj_was_tweaked = apply_tweak_obj( $lpred, \$lobj, $tweak_obj );
                   if ( $opt_d && $obj_was_tweaked ) { print "\t$logtag\tobject was tweaked to: " . $lobj->as_string . "\n"; }

	             ## add triple to GLOBAL model
                    
                   $model->add_statement( RDF::Trine::Statement->new($subject, $lpred, $lobj) );
              } else {
		print join("\t", $logtag, "NO hit:", $lpred->as_string, $lobj->as_string, "\n") if ($opt_d);
              }
           } # TRIPLE
           ### statistics:
           $modelsize_after = $model->size;
           my $actually_inserted = $modelsize_after - $modelsize_before;
           print "STATS\t$logtag\t$subject\ttriple-total:$triplecount_total\ttriple-subj:$triplecount_subj\tselected:$triplecount_selected\n" if ($opt_d); 
           print "STATS\t$logtag\t$subject\tactually inserted: $actually_inserted\n" if ($opt_d);           
           $llog->{ '2_triple-subj' }     = $triplecount_subj;
           $llog->{ '3_triple-selected' } = $triplecount_selected;
           $llog->{ '4_triple-actually_inserted' } = $actually_inserted;
          } # SAMEAS  
  } # SUBJECT
 print "STATS\t$logtag\tNumber of RDF - statements in model AFTER: " . $model->size . "\n";
}


########### sort function for sorting subhects per year 
# compare two numbers
sub compare_subject_years{
   ( my $ayear = $a->uri_value ) =~ s{^.+/}{}; 
   ( my $byear = $b->uri_value ) =~ s{^.+/}{};
   $ayear <=> $byear;  # presuming numeric
}

##############################  LOGGING #######################


## initialize a hash for local information on each _external_ link
sub init_log_fields { 
    my $loghash =  { 
                 '0_url_sameAs'      => "",
                 '1_error'           => "",
                 '2_triple-subj'     => "",
                 '3_triple-selected' => "",
		     '4_triple-actually_inserted' => "",
                };
    return $loghash;
} 

### render the log-hash as csv 
sub render_loghash_as_csv {
   my $log = shift;
   my @csv; 
   # my @line = ();
   # push(@csv, join("\t", "subject", "level1", "x", "y", "z", "..."));
   foreach my $s (sort keys %$log) {
       my @line = ();
       push (@line, $s);
       foreach my $level1 ( sort keys %{$log->{$s}} ) {
          push (@line, "$level1:");
          foreach my $level2 ( sort keys %{$log->{$s}->{$level1}} ) {
              push(@line, "$level2:");
              push(@line, $log->{$s}->{$level1}->{$level2});
          }
       }
       push(@csv, join("\t", @line));
   } 
   return(join("\n", @csv));
}


############# RDF::Trine::parse_url_into_model offers to use a callback - function.
############# we just experimented a bit with it, but found it not useful. But we leave it as a dummy! 
#############
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

### important: $x has to be passed in as reference!!!
### $x will be changed in situ
sub apply_tweaks {
  my $xref      = shift; 
  my $tweaks    = shift; 
  my $was_tweaked = 0;
  foreach my $pattern (keys %$tweaks) {
       my $subs = $tweaks->{$pattern};
       if (  $$xref =~ s/$pattern/$subs/ee ) { $was_tweaked = 1 }
  }
  return $was_tweaked;
}


### Attention: returns $obj 
### has to take care whether $obj is a Resource or a Literal !!!
sub apply_tweak_obj {
   my $pred = shift;
   my $obj  = shift; 
   my $tweaks = shift; 
   my $was_tweaked = 0; 
   my $objstr;

   if ( $$obj->is_resource ) { 
      $objstr = $$obj->uri_value;
   } elsif ( $$obj->is_literal ) {
      $objstr = $$obj->as_string;
   } else { 
	return 0; 
   }

   foreach my $p (keys %$tweaks) {
	if ( $pred->uri_value eq $p or $p eq '*' ) {
         if ( apply_tweaks( \$objstr, $tweaks->{ $p } )  ) {
           $was_tweaked = 1;
         } 
      }
   }
   ## iff there was a tweak: change $obj !
   if ($was_tweaked) {
	   if ($$obj->is_resource) { 
	      $$obj = RDF::Trine::Node::Resource->new($objstr);
	   } elsif ($$obj->is_literal) {
	      $$obj = RDF::Trine::Node::Literal->new($objstr);
	   } else { 
		return 0;
	   }
	$$obj = RDF::Trine::Node::Resource->new($objstr);
   } 
  return $was_tweaked;
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
