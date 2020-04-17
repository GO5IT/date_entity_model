#!/usr/bin/perl 

use Date::Calc qw(:all);
use RDF::Simple::Serialiser;
use RDF::Simple::Serialiser::NT;
use RDF::Simple::Serialiser::N3;
use warnings;
use strict;


my $ser = RDF::Simple::Serialiser->new(
  # OPTIONAL: Supply your own bNode id prefix:
  nodeid_prefix => 'a:',
  );

# OPTIONAL: Add your namespaces:
$ser->addns(
            foaf => 'http://xmlns.com/foaf/0.1/',
           );

#<rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/day"/>
#        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
#        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
#        <skos:prefLabel xml:lang="en">1001-02-28</skos:prefLabel>

my $node1 = $ser->genid;
my $node2 = $ser->genid;
my $daynode = 'https://vocabs.acdh.oeaw.ac.at/date/2020-01-01';
my @triples = (
               ['http://example.com/url#', 'dc:creator', 'zool@example.com'],
               ['http://example.com/url#', 'foaf:Topic', '_id:1234'],
               ['_id:1234','http://www.w3.org/2003/01/geo/wgs84_pos#lat','51.334422'],
               [$node1, 'foaf:name', 'Jo Walsh'],
               [$node1, 'foaf:knows', $node2],
               [$node2, 'foaf:name', 'Robin Berjon'],
               [$node1, 'rdf:type', 'foaf:Person'],
               [$node2, 'rdf:type','http://xmlns.com/foaf/0.1/Person'],
               [$node2, 'foaf:url', 'http://server.com/NOT/an/rdf/uri.html'],
               ['https://vocabs.acdh.oeaw.ac.at/date/2020-01-01', 'rdf:type', 'http://www.w3.org/2004/02/skos/core#Concept']
              );



my $rdf = $ser->serialise(@triples);
print "$rdf\n";
 

