#!/usr/bin/perl

use strict;
use warnings;
use RDF::Trine;
use utf8;

package DateRDFUtils;

### used for RDF::Trine::Serializer
our $namespacehash = {
      dc=>'http://purl.org/dc/elements/',
	dcterms=>'http://purl.org/dc/terms/',
	rdf=>'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
	rdfs=>'http://www.w3.org/2000/01/rdf-schema#',
	skos=>'http://www.w3.org/2004/02/skos/core#',
	time=>'http://www.w3.org/2006/time#',
	xsd=>'http://www.w3.org/2001/XMLSchema#',
	foaf => 'http://xmlns.com/foaf/0.1/' ,
      owl => 'http://www.w3.org/2002/07/owl#',
      dbo => 'http://dbpedia.org/ontology/',
	prov => 'http://www.w3.org/ns/prov#',
};

## automatically create namespace objects trine-namespaces ... 
my $nsobject={};
foreach my $prefix (keys %$DateRDFUtils::namespacehash) {
   $nsobject->{$prefix} = RDF::Trine::Namespace->new($DateRDFUtils::namespacehash->{$prefix});
}  
 

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
