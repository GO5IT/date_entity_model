#!/usr/bin/perl 

## -CSD

use strict;
use warnings;
use Data::Dumper;
use DateRDFUtils;
use RDF::Trine;
use RDF::Trine::Serializer;
use Getopt::Std;

my $DEFAULTLOG="add_existing.log";
my $base_uri="http:://foo"; ## ?  

my $DEFAULTURL='http://dbpedia.org/resource/563_BC';

my $MEDIATYPE='application/rdf+xml';

### Create a namespace object for the foaf vocabulary
##my $foaf = RDF::Trine::Namespace->new( 'http://xmlns.com/foaf/0.1/' );
## 
### Create a node object for the FOAF name property
##my $pred = $foaf->name;
### alternatively:
### my $pred = RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name');
## 
##print "pred as string: " . $pred->as_string . "\n"; # exit; 

###print Dumper $DateRDFUtils::namespacehash->{'foaf'};

#print "==nsobjects==\n";
#print Dumper %$DateRDFUtils::nsobjects;

# Create a node object for skos-exactMatch property
# my $pred = $foaf->name;
#my $skosNS = $DateRDFUtils::nsobjects->{'skos'};


### create useful predicate-names
my $rdfs_label = $DateRDFUtils::nsobjects->{'rdfs'}->label;
my $skos_exact = $DateRDFUtils::nsobjects->{'skos'}->exactMatch;
my $owl_sameas = $DateRDFUtils::nsobjects->{'owl'}->sameAs;
my $dbo_abstract = $DateRDFUtils::nsobjects->{'dbo'}->abstract;
my $foaf_primarytopic = $DateRDFUtils::nsobjects->{'foaf'}->primaryTopic;


my @checkinDBPedia  = (  $owl_sameas, $rdfs_label, $foaf_primarytopic, $dbo_abstract  );
my @checkinWikidata = (  $rdfs_label, $foaf_primarytopic, $dbo_abstract  );

print "checkinDBPedia:\n";
print Dumper @checkinDBPedia;  


our ($opt_h, $opt_d, $opt_i,$opt_o,$opt_l,$opt_u,$opt_t,$opt_p);
getopts('hdi:o:l:u:tp');


sub usage {
  print <<"EOF";

USAGE $0 (-h) (-d) (-i <INPUTFILE>) (-o <OUTPUTFILE>) (-l <LOGFILE>) (-t)

-i <INPUTFILE>
             If -i is not supplied, then
	     URL provided by -u <URL> 
             will be fetched instead

-o <OUTPUTFILE>
             If -o is not supplied, will write to <STDOUT>

-u <URL> 
	    Fetch RDF from URL iff -i <INPUTFILE>
            is not supplied (for testing)
            DEFAULT $DEFAULTURL

-l <LOGFILE> Name of logfile.
             DEFAULT: $DEFAULTLOG

-t           TEST-MODE

-d           Debug mode: print list of dates - and NO RDF

-p           pre-test each \$url with your own UserAgent - this seems to be the only way to 
	     fetch errors without dying!  

-h           Print this message

EOF

}

if ($opt_h) {
  usage();
  exit;
}

my $logfile = $opt_l ? $opt_l : $DEFAULTLOG;
my $url = $opt_u ? $opt_u : $DEFAULTURL;


my $fhi;
my $fho; 
my $fhlog;

if ($opt_i) {
  open($fhi, '<', $opt_i);
}
if ($opt_o) {
  open($fho, '>', $opt_o);
}
if ($opt_l) {
  open($fhlog, '>', $logfile);
}

### create my own $ua used for pre-testing urls -> probably NOT required!!!
my $ua = LWP::UserAgent->new;
        $ua->default_header('Accept-Charset' => 'utf-8');
        $ua->default_header('Accept-Language' => "en");
        $ua->default_header('Accept' => $MEDIATYPE);

### initialize 
my $store      = RDF::Trine::Store::Memory->new();
my $model      = RDF::Trine::Model->new($store);
my $serializer = RDF::Trine::Serializer->new('rdfxml', namespaces => $DateRDFUtils::namespacehash);
my $parser     = RDF::Trine::Parser->new( 'rdfxml' );

## testing some settings
if ($opt_t) {	
	print "parser->media_type = " . $parser->media_type . "\n";  
	print "parser->media_types = " . $parser->media_types . "\n"; 
 
        print "== Parser for media_type $MEDIATYPE :\n";
        print $parser->parser_by_media_type ( $MEDIATYPE ); 
        exit;
}

# parse some web data into the model, and print the count of resulting RDF statements
my $response;
if ($opt_i) {
    $response = $parser->parse_file_into_model( $base_uri, $fhi, $model );
} else {
#    $response = $parser->parse_url_into_model( $url, $model, ua => $ua, content_cb => \&content_callback, useragent => $ua );
    my $error = "";
    if ($opt_p) {
       $error = pre_test_url_for_error($url, $ua);
    }
    if ($error) {
       ### TODO: write info to logfile
       print "LEIDER FEHLGESCHLAGEN: $url\t$error\n";
    } else {
       $response = $parser->parse_url_into_model( $url, content_cb => \&content_callback );
    }
}

## debug
if ($opt_d && !$fhi) {
  print "== response ==\n";
  print Dumper $response;
  exit;
}

print "Number of RDF - statements in model BEFORE: " . $model->size . "\n";

## get all subjects in model
my @subjects = $model->subjects(undef, undef);
print "Number of subjects: " . scalar(@subjects) . "\n";

## loop over subjects
YEAR: foreach my $subject (@subjects) {
  my $iter = $model->get_statements($subject, $skos_exact, undef);
  print "==== subject: $subject ====\n";
  SAMEAS: while (my $st = $iter->next) {
    my $sub  = $st->subject;
    my $pred = $st->predicate;
    my $obj  = $st->object;  
    ### only consider dbpedia and wikidata
    if ($obj->as_string =~ m{http://dbpedia.org|https?://www.wikidata.org}) {
       print "\tselected:\t$pred\t$obj\n";
    } else {
       print "\tfiltered:\t$pred\t$obj\n";
       next SAMEAS; 
    }

    ### fetch the linked stuff in separate temporal model
#    my $localstore     = RDF::Trine::Store::Memory->new();
    my $localmodel      = RDF::Trine::Model->new($store);
    my $lresponse;
    my $error = "";
    if ($opt_p) {
       $error = pre_test_url_for_error($obj->uri_value, $ua);
    }
    if ($error) {
       ### TODO: write info to logfile
       print "LEIDER FEHLGESCHLAGEN:\t" . $obj->uri_value . "\t$error\n";
    } else {
       $lresponse = $parser->parse_url_into_model( $obj->uri_value, $localmodel, content_cb => \&content_callback );
    }
    ### now extract ALL relevant triples for localmodel 
    print "\nNumber of RDF - statements in LOCAL model: " . $localmodel->size . "\n";
    my $localiter = $localmodel->get_statements(undef, undef, undef);
    TRIPLE: while (my $lst = $localiter->next) {
    	my $lsub  = $lst->subject;
    	my $lpred = $lst->predicate;
    	my $lobj  = $lst->object;
 
     if ($opt_d)  {
     	print "lpred: $lpred\n";
     	print Dumper $lpred;
     	print "---\n";
     }

     ### filter! Only use those preds enumerated in @checkinDBPedia
     if ( grep { $lpred->equal($_) } @checkinDBPedia ) {
           print "HIT:\t\t$lpred\t$lobj\n"; # if ($opt_d);
	## add triple to store!
        $model->add_statement( RDF::Trine::Statement->new($subject, $lpred, $lobj) );
     }
  } # TRIPLE
} # SAMEAS
print "Number of RDF - statements in model AFTER: " . $model->size . "\n";
} # YEAR

##### serialize the model to either outfile or to standard-output
my $outstring =  $serializer->serialize_model_to_string ( $model );
if ($fho) {
	print $fho $outstring;
} else {
	print $outstring;
}

## close all open files
if ($fhi)   { close($fhi); }
if ($fho)   { close($fho); }
if ($fhlog) { close($fhlog); }

## ======================= END MAIN ==============================

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
 
######################## END MAIN #########################
#parse_url_into_model ( $url, $model [, %args] )
#Retrieves the content from $url and attempts to parse the resulting RDF into $model using a parser chosen by the associated content media type.

#If %args contains a 'content_cb' key with a CODE reference value, that callback function will be called after a successful response as:

#$content_cb->( $url, $content, $http_response_object )
#If %args contains a 'useragent' key with a LWP::UserAgent object value, that object is used to retrieve the requested URL without any configuration (such as setting the Accept: header) which would ordinarily take place. Otherwise, the default user agent ("default_useragent" in RDF::Trine) is cloned and configured to retrieve content that will be acceptable to any available parser.
sub content_callback {
  my $url = shift;
  my $content = shift;
  my $http_response_object = shift;

#  print "\n== cb: url ==\n";
#  print Dumper $url;

  if ($http_response_object->is_success) {
    	print "response ist OK!\n";
  } else {
   	print "response hat ein FAIL:\n";
   	print $response->status_line . "\n\n\n";
  }

#  if ($opt_d) {
#    	print "\n== cb: content ==\n";
#    	print Dumper $content;
#  }

#  if ($opt_d) {
#  	print "\n== cb: http_response_object ==\n";
#  	print Dumper $http_response_object;
#  }
} 

## test a url: returns FALSE if successful and 
## the HTTP-Error if not.
sub  pre_test_url_for_error {
  my $url = shift;
  my $ua  = shift;
  print "== testing $url ...\n";
  my $response = $ua->get($url);
  print "== tested $url ...\n";
  if ($response->is_success) {
    return "";
  }  else { 
    print "== FAILED: " . $response->status_line . "\n";
    return $response->status_line;
  }
}


