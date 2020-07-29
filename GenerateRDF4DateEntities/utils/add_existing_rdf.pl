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

# my $DEFAULTURL='http://dbpedia.org/resource/563_BC';
## a url with https: I had major problems with this one !!! 
my $DEFAULTURL='https://www.wikidata.org/wiki/Q2485';
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
my $rdfs_label        = $DateRDFUtils::nsobjects->{'rdfs'}->label;
my $skos_exactmatch   = $DateRDFUtils::nsobjects->{'skos'}->exactMatch;
my $owl_sameas        = $DateRDFUtils::nsobjects->{'owl'}->sameAs;
my $dbo_abstract      = $DateRDFUtils::nsobjects->{'dbo'}->abstract;
my $foaf_primarytopic = $DateRDFUtils::nsobjects->{'foaf'}->primaryTopic;

my $checkinDBPedia  = [  $owl_sameas, $rdfs_label, $foaf_primarytopic, $dbo_abstract  ];
my $checkinWikidata = [  $rdfs_label, $foaf_primarytopic, $dbo_abstract  ];


our ($opt_h, $opt_d, $opt_i,$opt_o,$opt_l,$opt_u,$opt_t,$opt_p);
getopts('hdi:o:l:u:tp');

$opt_p = 0 unless $opt_p;

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

if ($opt_d) {
  print "checkinDBPedia:\n";
  print Dumper @$checkinDBPedia;  
  print "checkinWikidata:\n";
  print Dumper @$checkinWikidata;  
  print "\n\n";
}

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

### initialize 
my $store      = RDF::Trine::Store::Memory->new();
my $model      = RDF::Trine::Model->new($store);
my $parser     = RDF::Trine::Parser->new( 'rdfxml' );
my $serializer = RDF::Trine::Serializer->new('rdfxml', namespaces => $DateRDFUtils::namespacehash);

## test mode: test some settings and exit
if ($opt_t) {	
	print "parser->media_type = " . $parser->media_type . "\n";  
	print "parser->media_types = " . $parser->media_types . "\n"; 
 
        print "== Parser for media_type $MEDIATYPE :\n";
        print $parser->parser_by_media_type ( $MEDIATYPE ); 
        exit;
}

# load the -i <infile> into a model, or load from web-source using -u <url>
my $response;
if ($opt_i) {
    $response = $parser->parse_file_into_model( $base_uri, $fhi, $model );
} else {
    my $error = "";
    if ($opt_p) {
       $error = DateRDFUtils::pre_test_url_for_error($url);
    }
    if ($error) {
       ### TODO: write info to logfile
       die "INITIAL HTTP FAILED for: $url\t$error\n";
    } else {
       $response = $parser->parse_url_into_model( $url, $model, content_cb => \&DateRDFUtils::content_callback );
    }
}

## for debug
if ($opt_d && !$fhi) {
  print "== response ==\n";
  print Dumper $response;
  exit;
}

## almost the whole logic is packed into THIS function
## add_triples_from_external_sameAs ( $model, $sameas, $filter, $predstoadd, $pretestURL, $logtag, $opt_d, $log ) 
## call it twice: 
## The first run will search for skos:exactMatch on dbpedia and fetch the appropriate triples from there
## these also include owl:sameAs for wikidata 
my $log = {}; 
## 1st run: dbpedia
DateRDFUtils::add_triples_from_external_sameAs ( $model, $parser, $skos_exactmatch, 'http://dbpedia.org' , $checkinDBPedia, $opt_p, "DBPedia", $opt_d, $log ); 
## 2nd run: wikidata
# DateRDFUtils::add_triples_from_external_sameAs ( $model, $parser, $owl_sameas, '//www.wikidata.org' , $checkinWikidata, $opt_p, "DBPedia", $opt_d, $log ); 

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


