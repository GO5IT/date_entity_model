#!/usr/bin/perl 

## -CSD

use strict;
use warnings;
use DateRDFUtils;
use Data::Dumper;
use RDF::Trine;
use RDF::Trine::Serializer;
use Getopt::Std;
use Encode;

use utf8;

my $DEFAULT_I  = 'rdfxml'; 
my $DEAFAULT_O = 'rdfxml';

## I suspect that the data which we fetch from Store (which probably makes up most of the 
## text printed to STDOUT is binary data encoded in UTF-8. Therfore STDOUT is kept as binary stram.
binmode STDOUT, ":encoding(utf-8)" or die "Cannot set utf-8-mode to STDOUT\n";

## not sure what this is supposed to be, but $parser->parse_file_into_model() requires _some_ base_uri as one of its arguments
my $base_uri="http:://foo"; 

## a url with https: I first had major problems with this one -> some apache?-libraries had been missing
my $DEFAULTURL='https://www.wikidata.org/wiki/Q2485';
my $MEDIATYPE='application/rdf+xml';


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


our ($opt_h, $opt_d, $opt_o,$opt_I, $opt_O, $opt_t);
getopts('hdo:I:O:t');

sub usage {
  print <<"EOF";

USAGE $0 (-h)  -I <INPUTFORMAT> -O <OUTPUTFORMAT> -o <OUTPUTFILE> <INPUTFILE>+ 

Join all <INPUTFILE>s into ONE <OUTPUTFILE>

-I <INPUTFORMAT>  rdfxml, turtle
                DEFAULT: $DEFAULT_I

-O <OUTPUTFORMAT> rdfxml, turtle
                DEFAULT: $DEAFAULT_O

-o <OUTPUTFILE>
             If -o is not supplied, will write to <STDOUT>

-f <OUTPUTFORMAT> xml or turtle 
	    		
	     
-d           Debug mode: print excessive information to <STDOUT> 

-h           Print this message

EOF

}

if ($opt_h) {
  usage();
  exit;
}

my $itype = $opt_I ? $opt_I : $DEFAULT_I;
my $otype = $opt_O ? $opt_O : $DEAFAULT_O;

if ($itype !~ m/^(rdfxml|turtle)$/) {
  die "\ninput type not valid: $itype\n";
}
if ($otype !~ m/^(rdfxml|turtle)$/) {
  die "\ninput type not valid: $otype\n";
}


my $fhi;
my $fho; 

if ($opt_o) {  
  open($fho, ">", $opt_o) or die "Cannot open output files $opt_o\n";
  ## when using serialize_model_to_string + print to file : use  binary 
  binmode($fho) or die "Cannot set fho to binmode!\n";
}

### initialize 
# my $store      = RDF::Trine::Store::Hexastore->new();
my $store      = RDF::Trine::Store::Memory->new();
my $model      = RDF::Trine::Model->new($store);
my $parser     = RDF::Trine::Parser->new( $itype );
my $serializer = RDF::Trine::Serializer->new($otype, namespaces => $DateRDFUtils::namespacehash);


## 1) read all the infiles into the model
IN: foreach my $infile (@ARGV) { 
    ## Trine::Parser::RDFXML.pm docu says:
    #Note: The filehandle should NOT be opened with the ":encoding(UTF-8)" IO layer,
    #as this is known to cause problems for XML::SAX.
    open($fhi, $infile) or die "Cannot open file $infile\n";
    binmode($fhi) or die "Cannot set fhi to binmode!\n";
    print "==== reading: $infile ... ====\n";
    my $response = $parser->parse_file_into_model( $base_uri, $fhi, $model );
    ## for debug 
    if ($opt_d) {
        print "== response ==\n";
        print Dumper $response;
    }
    close($fhi);
}

## 2) serialize the model to outfile
if ($fho) {
    ## RDF::Trine::Serializer::serialize_model_to_string 
    ### invoces "open( my $fh, '>:encoding(UTF-8)', \$string );" !
    ## i.e. the resultring $string is already in UTF-8 and has to be printed to binary
    print "\n==== writing format $otype to $opt_o ... ====\n";
    print $fho $serializer->serialize_model_to_string($model);
    close($fho);
} else {
      # for logging STDOUT has to be set to ":encoding(utf-8)" 
      # therefore we need to _decode_ string before is gets encoded again!
      print STDOUT decode("UTF-8", $serializer->serialize_model_to_string($model));
} 

######################## END MAIN #########################


