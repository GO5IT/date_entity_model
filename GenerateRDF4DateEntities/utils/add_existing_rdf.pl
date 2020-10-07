#!/usr/bin/perl 

## -CSD

use strict;
use warnings;
use Data::Dumper;
use DateRDFUtils;
use RDF::Trine;
use RDF::Trine::Serializer;
use Getopt::Std;
use Encode;

use utf8;

## I suspect that the data which we fetch from Store (which probably makes up most of the 
## text printed to STDOUT is binary data encoded in UTF-8. Therfore STDOUT is kept as binary stram.
binmode STDOUT, ":encoding(utf-8)" or die "Cannot set utf-8-mode to STDOUT\n";

my $DEFAULTLOG="add_existing_log.csv";

## not sure what this is supposed to be, but $parser->parse_file_into_model() requires _some_ base_uri as one of its arguments
my $base_uri="http:://foo"; 

## a url with https: I first had major problems with this one -> some apache?-libraries had been missing
my $DEFAULTURL='https://www.wikidata.org/wiki/Q2485';
my $MEDIATYPE='application/rdf+xml';

## processing-steps 
## list of _known_ steps 
my @KNOWNSTEPS=("01_DBPedia", "02_Wikidata");
## default list of steps (comma separated string)
my $DEFAULTSTEPS="01_DBPedia,02_Wikidata";

### Create a namespace object for the foaf vocabulary
##my $foaf = RDF::Trine::Namespace->new( 'http://xmlns.com/foaf/0.1/' );
## 
### Create a node object for the FOAF name property
##my $pred = $foaf->name;
### alternatively:
### my $pred = RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name');

### create useful predicate-names
## Specify predicates to fetch from DBpedia in the two blocks below
my $rdfs_label        = $DateRDFUtils::nsobjects->{'rdfs'}->label;
my $skos_exactmatch   = $DateRDFUtils::nsobjects->{'skos'}->exactMatch;
my $owl_sameas        = $DateRDFUtils::nsobjects->{'owl'}->sameAs;
my $dbo_abstract      = $DateRDFUtils::nsobjects->{'dbo'}->abstract;
my $foaf_primarytopic = $DateRDFUtils::nsobjects->{'foaf'}->isPrimaryTopicOf;
my $skos_altLabel     = $DateRDFUtils::nsobjects->{'skos'}->altLabel;
my $schema_about      = $DateRDFUtils::nsobjects->{'schema'}->about;

my $checkinDBPedia  = [  
   $owl_sameas,
	 $rdfs_label,
	 $dbo_abstract, 
 ];


## Specify below which predicates to fetch from wikidata
my $checkinWikidata = [  
  $rdfs_label,
  $skos_altLabel, 
	$DateRDFUtils::nsobjects->{'wdt'}->P910, 
	$DateRDFUtils::nsobjects->{'wdt'}->P6228,
	$DateRDFUtils::nsobjects->{'wdtn'}->P244,
	$DateRDFUtils::nsobjects->{'wdtn'}->P2581,
	$DateRDFUtils::nsobjects->{'wdtn'}->P646,
 ];

our ($opt_h, $opt_d, $opt_i,$opt_o,$opt_l,$opt_u,$opt_t,$opt_L, $opt_S, $opt_b, $opt_r);
getopts('hdi:o:l:u:tL:S:b:r:');

## make opt_L and opt_S numeric.
$opt_L = 0 unless $opt_L;
$opt_S = 0 unless $opt_S;


sub usage {
  print <<"EOF";

USAGE $0 (-h) (-d) (-i <INPUTFILE>) (-o <OUTPUTFILE>) (-l <LOGFILE>) (-t)

-i <INPUTFILE>
             If -i is not supplied, then
	     URL provided by -u <URL> 
             will be fetched instead

-o <OUTPUTFILE>
             If -o is not supplied, will write to <STDOUT>

-r <STEPStoRUN> Comma separated list of processing steps 
	    DEFAULT: $DEFAULTSTEPS 


-u <URL> 
	    Fetch RDF from URL iff -i <INPUTFILE>
            is not supplied (for testing)
            DEFAULT $DEFAULTURL

-l <LOGFILE> Name of logfile.
             DEFAULT: $DEFAULTLOG

             Actually currently TWO log-files will be written: 
             a csv file and a Dump of the structue. 

-L <LIMIT>   Only process <LIMIT> RDF:Descriptions. (For testing!)

-S <SKIP>    Skip <SKIP> RDF:Descriptions (For testing!). 
             

-t           TEST-MODE: this is _purely_ for testing: 
	     there is NO fetching from external links; 
	     it only will print some settings and exit. 
	     
-d           Debug mode: print excessive information to <STDOUT> 

-h           Print this message

EOF

}

if ($opt_h) {
  usage();
  exit;
}

my @processingsteps = $opt_r ? split(/,/, $opt_r) : split(/,/, $DEFAULTSTEPS); 
my $logfile = $opt_l ? $opt_l : $DEFAULTLOG;
my $logfiledump = "$logfile.dump";  ## name of the dumpfile - will be derived from logfilename
my $url = $opt_u ? $opt_u : $DEFAULTURL;

## check steps: 
foreach my $step (@processingsteps) {
  if ( ! grep(/$step/, @KNOWNSTEPS) ) {
	print "\nProcessing step now known: $step -- it must be one (or more) of " . join(" ", @KNOWNSTEPS) . "\n";
	die;
  }
}

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
my $fhlogdump;

## Trine::Parser::RDFXML.pm docu says:
#Note: The filehandle should NOT be opened with the ":encoding(UTF-8)" IO layer,
#as this is known to cause problems for XML::SAX.
if ($opt_i) {
  open($fhi, $opt_i);
  binmode($fhi) or die "Cannot set fhi to binmode!\n";
}
if ($opt_o) {
#  
  open($fho, ">", $opt_o);
  ## when using serialize_model_to_string + print to file : use  binary 
  binmode($fho) or die "Cannot set fho to binmode!\n";
}
open($fhlog, '>', $logfile);
open($fhlogdump, '>', $logfiledump);

### initialize 
# my $store      = RDF::Trine::Store::Hexastore->new();
my $store      = RDF::Trine::Store::Memory->new();
my $model      = RDF::Trine::Model->new($store);
my $parser     = RDF::Trine::Parser->new( 'rdfxml' );
my $serializer = RDF::Trine::Serializer->new('rdfxml', namespaces => $DateRDFUtils::namespacehash);

## test mode: test some settings and exit
if ($opt_t) {	
	print "parser->media_type = " . $parser->media_type . "\n";  
	print "parser->media_types = " . $parser->media_types . "\n"; 
 
        print "== Parser for media_type $MEDIATYPE :\n";
        print $parser->parser_by_media_type( $MEDIATYPE ) . "\n\n";     
}

# load the -i <infile> into a model, or load from web-source using -u <url>
my $response;
if ($opt_i) {
    $response = $parser->parse_file_into_model( $base_uri, $fhi, $model );
} else { 
    ## call parse_url_into_model() in a eval-block to catch HTTP exceptions!
    ## cf.  https://perlmaven.com/fatal-errors-in-external-modules
    eval {
	     # code that might throw exception
	     $response = $parser->parse_url_into_model( $url, $model, content_cb => \&DateRDFUtils::content_callback );
	     1;  # always return true to indicate success
	}
	or do {
	    # this block executes if eval did not return true (becuse of an exception)
	 
	    # save the exception and use 'Unknown failure' if the content of $@ was already
	    # removed
	    my $error = $@ || 'Unknown failure';
	    # report the exception and do something about it
          ### TODO: write info to logfile
          die "INITIAL HTTP FAILED for: $url\t$error\n";
	};
}

## for debug
if ($opt_d && !$fhi) {
  print "== response ==\n";
  print Dumper $response;
  exit;
}

###################
##### ** THIS is the CENTRAL FUNCTION, which almost does the WHOLE JOB !!! **
###################
## add_triples_from_external_sameAs ( $model, $parser, $sameas, $filterurl, $predstoadd, $tweak_urls, $tweak_subj, $tweak_pred, $tweak_obj $logtag, $opt_d, $log, $opt_S, $opt_L ) 
##
## How add_triples_from_external_sameAs works:
## 1) in $model: look for all $sameAs (i.e. skos:exactMatch or owl:sameAs) pointing to external URLs
## 2) only proceed with those external URLS which match the string(s) mentioned in $filterurl 
## 3) retrieve data from external URL
## 4) add the predicates mentioned in $predstoadd from external URL to $model 
## 
## Arguments:
## model	      A RDF::Trine::Model
## parser         A RDF::Trine::Parser
## sameas	      Predicate to use for determining "sameness" - e.g. skos:exactMatch or owl:sameAs
## filterurl         A regex used for further filtering down the URLS found in $sameas
##	            e.g. qr{http://dbpedia.org} 
## predstoadd     A arrayref enlisting all the predicates (found in the external resource) to be added to the $model;
##	            iff empty arrayref is added: add ALL predicates 
## logtag         A string which is just used in the supply a tag which is used in the print-outs of the log. E.g. "DBpedia" 
## tweak_urls 	A hashref enlisting PATTERN => SUBSTITUTION pairs  which are applied to a URL before fetching it
## tweak_subj     A hashref enlisting PATTERN => SUBSTITUTION pairs  which are applied to a SUBJECTS before adding them to the TripleStore
## tweak_pred     A hashref enlisting PATTERN => SUBSTITUTION pairs  which are applied to a PREDICAT-values before adding them to the TripleStore
## tweak_obj      A hashref enlisting PATTERN => SUBSTITUTION pairs  which are applied to a OBJECT-values   before adding them to the TripleStore 
## add_about      Predicate object: iff supplied then search for <SUBJ> <add_about> <URL>: 
##                                      iff <URL> matches <add_abouts_if_they_match>:                                          
##                                           add <URL> <add_abouts_as> <SUBJ> 
## add_abouts_if_they_match  A regex for filtering down <URLS> found in add_about 
## add_abouts_as  : the predicate name which is to be used for adding predicates when they match add_abouts_if_they_match       
## opt_d          Debug flag
## log            A logging-object : a hashref for collecting the log-info.
## opt_S          Skip number of subjects (for testing)
## opt_L          Limit number of subjects (for testing)
## fho            Filehandle for output: iff it is supplied and iff $opt_d all temporal local models will be printed to $fho  

my $log = {}; 

if ($opt_t) {
   print "\t# Because of -t (test-mode) we are skipping all the fetching of external links and only read- and write the input!\n\n";
} else {
	## 1st run: dbpedia
	if (  grep(/01_DBPedia/,  @processingsteps ))  {
	   DateRDFUtils::add_triples_from_external_sameAs ( $model, $parser, $skos_exactmatch, qr{http://dbpedia.org} , $checkinDBPedia, "01_DBPedia", $DateRDFUtils::tweak_urls_dbpedia, {}, {}, {}, "", "", "", $opt_d, $log, $opt_S, $opt_L, $serializer, $fho ); 
        };

	## 2nd run: wikidata
	if (  grep(/02_Wikidata/,  @processingsteps ))  {
	     #DateRDFUtils::add_triples_from_external_sameAs ( $model, $parser, $owl_sameas, qr{//www.wikidata.org} , $checkinWikidata, "02_Wikidata", {}, {}, {}, $DateRDFUtils::tweak_obj_wdata, $schema_about, qr{(en|de|fr).wikipedia.org/wiki}, $foaf_primarytopic, $opt_d, $log, $opt_S, $opt_L );
             DateRDFUtils::add_triples_from_external_sameAs ( $model, $parser, $owl_sameas, qr{//www.wikidata.org} , $checkinWikidata, "02_Wikidata", {}, {}, {}, $DateRDFUtils::tweak_obj_wdata, $schema_about, qr{(en).wikipedia.org/wiki}, $foaf_primarytopic, $opt_d, $log, $opt_S, $opt_L, $serializer, $fho );
        } 


	## 3rd run; wikipedia (added via the about-mechanism from wikidata 
        ##  if (  grep(/03_Wikipedia/,  @processingsteps ))  {
	## DateRDFUtils::add_triples_from_external_sameAs ( $model, $parser, $foaf_primarytopic, 'wikipedia.org' , $checkinWikidata, "03_Wikipedia", {}, {}, {}, $DateRDFUtils::tweak_obj_wdata, $schema_about, qr{(en|de|fr).wikipedia.org/wiki}, $foaf_primarytopic, $opt_d, $log, $opt_S, $opt_L );
	## }
 }


###### original !!! 
if ($fho) {
      ## RDF::Trine::Serializer::serialize_model_to_string 
      ### invoces "open( my $fh, '>:encoding(UTF-8)', \$string );" !
      ## i.e. the resultring $string is already in UTF-8 and has to be printed to binary
      print $fho $serializer->serialize_model_to_string($model);
} else {
      # for logging STDOUT has to be set to ":encoding(utf-8)" 
      # therefore we need to _decode_ string before is gets encoded again!
      print STDOUT decode("UTF-8", $serializer->serialize_model_to_string($model));
} 

if ($fhlogdump) { 
  print $fhlogdump Dumper $log; 
}

if ($fhlog) { 
  print $fhlog DateRDFUtils::render_loghash_as_csv($log);
}

## close all open files
if ($fhi)   { close($fhi); }; 
if ($fho)   { close($fho); };
if ($fhlog) { close($fhlog); }
if ($fhlogdump) { close($fhlogdump); }


######################## END MAIN #########################


