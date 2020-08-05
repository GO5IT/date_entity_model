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

my $DEFAULTLOG="rdf_rename_properties.log";
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
my $SPECIALTREATMENT = {};
my @PREDSTOCHANGESPECIAL = ();

$CHANGEPRED = {
   $DateRDFUtils::nsobjects->{'owl'}->sameAs->uri  =>  $DateRDFUtils::nsobjects->{'skos'}->exactMatch,
   $DateRDFUtils::nsobjects->{'rdfs'}->label->uri  =>  $DateRDFUtils::nsobjects->{'skos'}->altLabel,
   $DateRDFUtils::nsobjects->{'wdt'}->P910->uri  =>  $DateRDFUtils::nsobjects->{'skos'}->seeAlso,
   $DateRDFUtils::nsobjects->{'wdtn'}->P244->uri  =>  $DateRDFUtils::nsobjects->{'skos'}->exactMatch,
   $DateRDFUtils::nsobjects->{'wdtn'}->P2581->uri  =>  $DateRDFUtils::nsobjects->{'skos'}->exactMatch,
   $DateRDFUtils::nsobjects->{'wdtn'}->P646->uri  =>  $DateRDFUtils::nsobjects->{'skos'}->exactMatch,
   $DateRDFUtils::nsobjects->{'foaf'}->primaryTopic->uri  =>  $DateRDFUtils::nsobjects->{'rdfs'}->seeAlso,
   $DateRDFUtils::nsobjects->{'dbo'}->abstract->uri  =>  $DateRDFUtils::nsobjects->{'rdfs'}->comment,
};

## IN ADDITION: note predicates with special treatment and provide special functions.
$SPECIALTREATMENT = {
   $DateRDFUtils::nsobjects->{'wdt'}->P6228->uri => \&treat_p6628, 
};


# For PREDSTOCHANGE convert the strings back to RDF::Trine::Node::Resource - objects!
@PREDSTOCHANGE        = map { RDF::Trine::Node::Resource->new($_); } keys(%$CHANGEPRED);
@PREDSTOCHANGESPECIAL = map { RDF::Trine::Node::Resource->new($_); } keys(%$SPECIALTREATMENT);


#########################################################################

our ($opt_h, $opt_d, $opt_i,$opt_o,$opt_l,$opt_t);
getopts('hdi:o:l:t');

sub usage {
  print <<"EOF";

USAGE $0 (-h) (-d) (-t) (-i <INPUTFILE>) (-o <OUTPUTFILE>) (-l <LOGFILE>) 

Rename properties in RDF.

 
-i <INPUTFILE>

-o <OUTPUTFILE>
             If -o is not supplied, will write to <STDOUT>

-l <LOGFILE> Name of logfile.
             DEFAULT: $DEFAULTLOG

-t           TEST-MODE: just display the conversion-table

-d           Debug mode: extensive: show each and every statement which is changed

-h           Print this message

EOF

}

if ($opt_h) {
  usage();
  exit;
}

## option -t : just print transformation-tables and exit
if ($opt_t) {
   pretty_print_changepred($CHANGEPRED);
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
print $fhlog "Subject\tNumber\tNumber_triples_IN\t\tNumber_triples_OUT\tdiff\n";

### in order to have a clearer logging: do not go over all statements in one pass 
### but fetch each subject in turn

my @subjects = $model->subjects(undef, undef);

my $total_number_of_subjects = scalar(@subjects);
my $subject_counter = 0;

SUBJECT: foreach my $subject (@subjects) { 
   $subject_counter++;
   ## just  print a bit of a progress report to STDOUT 
   print join("\t", "SUBJECT: $subject_counter / $total_number_of_subjects:",  $subject->as_string,"\n"); 
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
     
         if ($opt_d) { print "TESTING: " . $statement->as_string . "\n"; }
         my $newstatement;
         ## special transformation? 
         if ( $SPECIALTREATMENT->{$pred->uri } ) {
                  $newstatement = $SPECIALTREATMENT->{$pred->uri }->($statement);               
             } 
         ## normal transformation? 
         elsif ( $CHANGEPRED->{ $pred->uri } ) { 
            my $newpred =  $CHANGEPRED->{ $pred->uri } ; 
            $newstatement = RDF::Trine::Statement->new( $subj, $newpred, $obj );
         }  else  { 
            ## do nothing 
            next TRIPLE;        
         }

         $number_of_triples_renamed++;
         ## add new  
         if ($opt_d) { print "\tNEW       : " . $newstatement->as_string . "\n"; }
         if ($opt_d) { print "\tDELETE OLD: " . $statement->as_string . "\n"; }
	 $model->add_statement( $newstatement );
         ## delete old
         $model->remove_statement($statement);
    } ## TRIPLE
  $number_of_triples_out = $model->count_statements ( $subject, undef, undef );
  $diff = $number_of_triples_out - $number_of_triples_in;
  print $fhlog join("\t", $subject->as_string, "$subject_counter / $total_number_of_subjects", $number_of_triples_in, $number_of_triples_out, $diff, "\n");
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


## <wdt:P6228>15453</wdt:P6228>
## create... 
sub treat_p6628 {
  my $statement = shift;
  my ($s,$p,$o)  = $statement->nodes();    
  my $newOstring  = "https://regiowiki.at/wiki/?curid=" . $o->literal_value; 
  my $newO = RDF::Trine::Node::Resource->new( $newOstring );
  my $newstatement = RDF::Trine::Statement->new( $s, $DateRDFUtils::nsobjects->{'rdfs'}->seeAlso, $newO );
  return $newstatement;
} 

sub pretty_print_changepred { 
   my $hash = shift;
   print "\n=== TRANSFORMATION-TABLE ===\n";
   foreach my $key (sort keys(%$hash)) { 
     print join("\t", $key, "=>", $hash->{$key}->uri ,"\n");
   } 
   print "\n";
}


