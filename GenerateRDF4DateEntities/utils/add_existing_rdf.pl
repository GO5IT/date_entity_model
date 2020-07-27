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

# Create a namespace object for the foaf vocabulary
my $foaf = RDF::Trine::Namespace->new( 'http://xmlns.com/foaf/0.1/' );
print Dumper $foaf;

print Dumper $DateRDFUtils::namespacehash->{'foaf'};

print "==nsobjects==\n";
print Dumper %$DateRDFUtils::nsobjects;

# Create a node object for skos-exactMatch property
# my $pred = $foaf->name;
my $skosNS = $DateRDFUtils::nsobjects->{'skos'};
print Dumper $skosNS; exit;

my $skosexact = $DateRDFUtils::namespacehash->{'skos'}->exactMatch;

our ($opt_h, $opt_d, $opt_i,$opt_o,$opt_l,$opt_u,$opt_t);
getopts('hdi:o:l:u:t');


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


if ($opt_t) {
	my $ua = LWP::UserAgent->new;
	my $response = $ua->get($url,
	  'User-Agent' => 'Mozilla/4.76 [en] (Win98; U)',
	  'Accept' => 'application/rdf+xml',
	  'Accept-Charset' => 'utf-8',
	  'Accept-Language' => 'en-US',
	);
	if ($response->is_success) {
	    my $text = $response->content;  # or whatever
          print "erfolg!\n";
	}  else  {
	    print "es gab probleme: " . $response->status_line . "\n";
	}

  exit;
}

my $store      = RDF::Trine::Store::Memory->new();
my $model      = RDF::Trine::Model->new($store);
my $serializer = RDF::Trine::Serializer->new('rdfxml', namespaces => $DateRDFUtils::namespacehash);
my $parser     = RDF::Trine::Parser->new( 'rdfxml' );

# parse some web data into the model, and print the count of resulting RDF statements
my $response;
if ($opt_i) {
    $response = $parser->parse_file_into_model( $base_uri, $fhi, $model );
} else {
    $response = $parser->parse_url_into_model( $url, $model );
}

if ($opt_d && !$fhi) {
  print "== response ==\n";
  print Dumper $response;
  exit;
}

#print $model->size . " RDF statements parsed\n";

if ($fho) {
	print $fho $serializer->serialize_model_to_file ( $fho, $model );
} else {
	print $serializer->serialize_model_to_string ( $model );
}

if ($fhi) { close($fhi); }
if ($fho) { close($fho); }
if ($fhlog) { close($fhlog); }

## get all subjects
my @subjects = $model->subjects(undef, undef);
print "Anzahl subjects: " . scalar(@subjects) . "\n";

foreach my $subject (@subjects) {
  my $iter = $model->get_statements($subject, $skosexact, undef);
  print "==== subject: $subject ====";
  while (my $st = $iter->next) {
    my $sub = $st->subject;
    my $pred = $st->predicate;
    my $obj  = $st->object;
    print "\t$pred\t$obj\n";
  }
}



exit;

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
 
# Create an iterator for all the statements in the model with foaf:name as the predicate
my $iter = $model->get_statements(undef, $skosexact, undef);
 
# Now print the results
print "Names of things:\n";
while (my $st = $iter->next) {
  my $s = $st->subject;
  my $name = $st->object;
   
  # $s and $name have string overloading, so will print correctly
  print "The name of $s is $name\n";
}
