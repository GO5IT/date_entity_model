#!/usr/bin/perl

use strict;
use warnings;

use RDF::Trine::Namespace;
my $foaf = RDF::Trine::Namespace->new( 'http://xmlns.com/foaf/0.1/' );
my $pred = $foaf->name;
#my $type = $rdf->type;
print $pred->as_string; # '[http://xmlns.com/foaf/0.1/name]'
