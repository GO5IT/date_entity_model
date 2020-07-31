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

my $DEFAULTLOG="add_existing.log";
my $MEDIATYPE='application/rdf+xml';
my $BASEURI="";

########## FROM RDF::Trine documentation: 
### Create a namespace object for the foaf vocabulary
##my $foaf = RDF::Trine::Namespace->new( 'http://xmlns.com/foaf/0.1/' );
## 
### Create a node object for the FOAF name property
##my $pred = $foaf->name;
### alternatively:
### my $pred = RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name');
## 
##print "pred as string: " . $pred->as_string . "\n"; # exit; 
#########################################

#### Documentation ACDH:
### we outsources the definition of namespaces to 
### DateRDFUtils::namespacehash 
### It is important that you maintain the namespaces THERE, so they are centrally stored in a HASH.
### from this hash  $DateRDFUtils::nsobjects is automatically derived: 
#my $skosNS = $DateRDFUtils::nsobjects->{'skos'};


#################### The transformation-mapping ####################
### there is a bit of a hassle here, because we need the predicates both as RDF::Trine::Node::Resource-objects as well as as strings!
### KEYS in the hash must be strings: therefore we use the "->uri" function, which returns the uri as string
my $CHANGEPRED = {};
my @PREDSTOCHANGE = ();

$CHANGEPRED = {
   $DateRDFUtils::nsobjects->{'owl'}->sameAs->uri  =>  $DateRDFUtils::nsobjects->{'skos'}->exactMatch,
   $DateRDFUtils::nsobjects->{'rdfs'}->label->uri  =>  $DateRDFUtils::nsobjects->{'skos'}->altLabel,
   $DateRDFUtils::nsobjects->{'wdt'}->P910->uri  =>  $DateRDFUtils::nsobjects->{'skos'}->seeAlso,
   $DateRDFUtils::nsobjects->{'wdtn'}->P244->uri  =>  $DateRDFUtils::nsobjects->{'skos'}->exactMatch,
   $DateRDFUtils::nsobjects->{'wdtn'}->P2581->uri  =>  $DateRDFUtils::nsobjects->{'skos'}->exactMatch,
   $DateRDFUtils::nsobjects->{'wdtn'}->P646->uri  =>  $DateRDFUtils::nsobjects->{'skos'}->exactMatch,
   $DateRDFUtils::nsobjects->{'foaf'}->primaryTopic->uri  =>  $DateRDFUtils::nsobjects->{'rdfs'}->seeAlso,
};

# For PREDSTOCHANGE convert the strings back to RDF::Trine::Node::Resource - objects!
@PREDSTOCHANGE = map { RDF::Trine::Node::Resource->new($_); } keys(%$CHANGEPRED);
#########################################################################

our ($opt_h, $opt_d, $opt_i,$opt_o,$opt_l,$opt_t);
getopts('hdi:o:l:t');

sub usage {
  print <<"EOF";

USAGE $0 (-h) (-d) (-t) (-i <INPUTFILE>) (-o <OUTPUTFILE>) (-l <LOGFILE>) 

-i <INPUTFILE>

-o <OUTPUTFILE>
             If -o is not supplied, will write to <STDOUT>

-l <LOGFILE> Name of logfile.
             DEFAULT: $DEFAULTLOG

-t           TEST-MODE

-d           Debug mode

-h           Print this message

EOF

}

if ($opt_h) {
  usage();
  exit;
}

## option -t : just print transformation-tables and exit
if ($opt_t) {
  print "=== CHANGEPRED ===\n";
  print Dumper %$CHANGEPRED;
  print "=== PREDSTOCHANGE ===\n";
  print Dumper @PREDSTOCHANGE;
  exit;
}


my $fhi;
my $fho; 
my $fhlog;

if ($opt_i) {
  open($fhi, "<:encoding(utf-8)", $opt_i) or die "Cannot open input file $opt_i\n"; 
} else {
  die "Option -i is missing!\n";
}

if ($opt_o) {
  open($fho, ">", $opt_o);
  ### puh! that's the only way I managed to print exotic UTF8 correctly (e.g. "ckb" -> Persian):
  ### open fho as binary and use explicit decoding! 
  binmode($fho) or die "Cannot set fho to binmode!\n";
}

my $logfile = $opt_l ? $opt_l : $DEFAULTLOG;
open($fhlog, '>', $logfile);

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

# load the -i <infile> into a model
my $response;
$response = $parser->parse_file_into_model( $BASEURI, $fhi, $model );

### Print headings for logger
print $fhlog "Subject\tNumber_triples_IN\t\tNumber_triples_OUT\tdiff\n";

### in order to have a clearer logging: do not go over all statements in one pass 
### but fetch each subject in turn

my @subjects = $model->subjects(undef, undef);

my $total_number_of_subjects = scalar(@subjects);
my $subject_counter = 0;

SUBJECT: foreach my $subject (@subjects) { 
   $subject_counter++;
   if ($opt_d) { print join("\t", "SUBJECT: $subject_counter / $total_number_of_subjects:",  $subject->as_string,"\n"); }
   ### loop over ALL triples
   my $iter = $model->get_statements($subject, undef, undef);
   my $number_of_triples_in      = 0;
   my $number_of_triples_renamed = 0;
   my $number_of_triples_out     = 0; 
   my $diff = 0;
   TRIPLE: while (my $statement = $iter->next) { 
         $number_of_triples_in++;
	 my $subj = $statement->subject;
         my $pred = $statement->predicate; 
    	 my $obj  = $statement->object; 
     
         # if ($opt_d) { print "TESTING: " . $statement->as_string . "\n"; }
         
         if ( grep  { $pred->equal($_) }  @PREDSTOCHANGE ) { 
            $number_of_triples_renamed++;
            my $newpred = $CHANGEPRED->{ $pred->uri };
            ## add renamed
            my $newstatement = RDF::Trine::Statement->new( $subj, $newpred, $obj );
            # if ($opt_d) { print "\tNEW       : " . $newstatement->as_string . "\n"; }
            # if ($opt_d) { print "\tDELETE OLD: " . $statement->as_string . "\n"; }
	    $model->add_statement( $newstatement );
            ## delete old
            $model->remove_statement($statement);
          } 
    } ## TRIPLE
  $number_of_triples_out = $model->count_statements ( $subject, undef, undef );
  $diff = $number_of_triples_out - $number_of_triples_in;
  print $fhlog join("\t", $subject->as_string, $number_of_triples_in, $number_of_triples_out, $diff, "\n");
} ## SUBJECT

##### serialize the model to either outfile or to standard-output
## the only way that worked: explicitely decode UTF-8 and write to a 'binary' stream 
## ATTENTION: only "utf8" (the loose, non-strict version) works; the strict "UTF-8" does NOT work:
## Cf.   https://perldoc.perl.org/Encode.html
my $outstring = decode("utf8", $serializer->serialize_model_to_string ( $model ));

if ($fho) {
	print $fho $outstring;
} else {
      ### does NOT work :-( 
      binmode(STDOUT) or die "Cannot set binmode to STDOUT\n";
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


