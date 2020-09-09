#!/usr/bin/perl -CSD

use warnings;
use strict;
use utf8;

use DateTime qw(:all);
use DateTime::Calendar::Julian qw(:all);
use DateRDFUtils;
use Getopt::Std;

my $DEFAULT_FROM = "-3000-01-01";
my $DEFAULT_TO   = "3000-01-01";

our ($opt_h, $opt_l, $opt_t, $opt_H, $opt_f, $opt_d);
getopts('hl:Hdf:t:');

sub usage {
  print <<"EOF";
USAGE $0 (-h) (-l <LIMIT>) (-H) (-d) (-f <DATE_FROM>) (-t <DATE_TO>)

-f <DATE_FROM>  Start with this date
               Format: (-)YYYY-MM-DD
             ( DEFAULT: $DEFAULT_FROM )
-t <DATE_TO>   End  with this date
             ( DEFAULT: $DEFAULT_TO )

-l <LIMIT>   Process at most <LIMIT> days

-H           Do NOT print RDF-headerder

-d           Debug mode: print list of dates - and NO RDF

     e.g.

    -1500-01-01 Friday  julian: -1500-01-15
    -1500-01-02 Saturday  julian: -1500-01-16
    -1500-01-03 Sunday  julian: -1500-01-1

-h           Print this message

EOF

}

if ($opt_h) {
  usage();
  exit;
}


my $datefrom    = $opt_f ? $opt_f : $DEFAULT_FROM;
my $datemax     = $opt_t ? $opt_t : $DEFAULT_TO;


## parse $datefrom
my ($year, $month, $day) = ($datefrom =~ m/^(-?\d{1,4})-(\d\d)-(\d\d)$/);
my $dt = DateTime->new( year => $year, month => $month, day => $day );

## parse $datemax
my ($yearmax, $monthmax, $daymax) = ($datemax =~ m/^(-?\d{1,4})-(\d\d)-(\d\d)$/);
my $dtmax = DateTime->new( year => $yearmax, month => $monthmax, day => $daymax );

### print header unless -H
print $DateRDFUtils::rdfstart unless ($opt_H || $opt_d);

###################
# Forward declarations
my $n = 0;
my $prevdate;
my $nextdate;
my $prevyear;
my $nextyear;
my $start;
my $end;
my $decade_label;
my $decade_duration_from;
my $decade_duration_to;
my $decade_duration3;
my $decade_duration4_from;
my $decade_duration4_to;
my $skosbroader;
my $decade_label_dbpedia;
my $decade_dbpedia;

## get $datefrom - 10 for the FIRST day in the line... 
my $dtprev = $dt; 
$dtprev->add(years=>-10);
$prevdate = $dtprev->date();

## increment again!
$dt->add(years => 10);


DAY: while ( DateTime->compare( $dt, $dtmax ) <= 0 ) {
   ## limit with -l ?
   last DAY if ( $opt_l && ($opt_l <= $n++) );
      my $date    = $dt->date();
      ## derive all others automatically
      my ($yyyy, $mm, $dd) = ($date =~ m/^(-?\d\d\d\d)-(\d\d)-(\d\d)$/);

      ## separate $yyyy and its possible "-" 
      my $bcsign = "";
      my $nosignyyyy = $yyyy; 
      if ( $nosignyyyy =~ s/^-// or $nosignyyyy == "0000") {
         $bcsign = "-"
      }

      ### remove leading "0" in years
      ## 0001 => 1 , -0001 => -1
      (my $nosignyyyyx = $nosignyyyy) =~ s/^0{1,3}//;
      my $yyyyx;
      if ($bcsign) {
         $yyyyx = $bcsign . $nosignyyyyx;
      } else {
         $yyyyx = $nosignyyyyx;
      }

      ## for debugging / testing
      ## print "$yyyy - $yyyyx - $nosignyyyyx\n"; $dt->add(days => 1); next DAY;
      my $nosignyyyyplus = $nosignyyyy + 1;
      my $nosignyyyyminus = $nosignyyyy - 1;

      ## handle previous and next ...        
      ## increment date ...
      $dt->add(years=>10);
      $nextdate = $dt->date();  
      
      ## increate next and previous year
      $nextyear = $nextdate;  
      my ($nextyyyy, $mm_unuse_next, $dd_unuse_next) = ($nextyear =~ m/^(-?\d\d\d\d)-(\d\d)-(\d\d)$/);
      my $nextdecade = DateRDFUtils::year2decade($nextyyyy);
      $prevyear = $prevdate;
      my ($prevyyyy, $mm_unuse_prev, $dd_unuse_prev) = ($prevyear =~ m/^(-?\d\d\d\d)-(\d\d)-(\d\d)$/);
      my $prevdecade = DateRDFUtils::year2decade($prevyyyy);

      my $decade = DateRDFUtils::year2decade($yyyy);
      my $decadeplus = $decade + 1;
      my $decadeplus3digit = sprintf("%+.3d", $decadeplus);
      $decadeplus3digit =~ s/^\+//;

      my $decadex = DateRDFUtils::year2decade($yyyyx);
      (my $decadex_nominus = $decadex) =~ s/^-//;
      my $semium = DateRDFUtils::year2semium($yyyy);
      my $semiumplus = $semium + 1;
      my $semiumplus2digit = sprintf("%+.2d", $semiumplus);
      $semiumplus2digit =~ s/^\+//;
      my $semiumminus = $semium - 1;
      my $semiumminus2digit = sprintf("%+.2d", $semiumminus);
      $semiumminus2digit =~ s/^\+//;

      my $semiumx = DateRDFUtils::year2semium($yyyyx);
      my $century = DateRDFUtils::year2firsttwo($yyyy);
      my $centuryx = DateRDFUtils::year2firsttwo($yyyyx);

      ## make altLabel depending on BC and AD:
      if ($yyyy > 0000){
          $decade_label = "" . qq{${decadex}0s};
      }
      else { 
          $decade_label = "" . qq{${decadex_nominus}0s BC};  
      }

      ## make duration (/) for altLabel, depending on AD (normal order) and BC (reverse order):
      if ($yyyy == "0000"){
          $decade_duration_from = "" . qq{0000};
          $decade_duration_to = "" . qq{0009};    
      }
      elsif ($yyyy == "-0010"){
          $decade_duration_from = "" . qq{-0008};
          $decade_duration_to = "" . qq{0000};    
      }
      elsif ($yyyy > 0000){
          $decade_duration_from = "" . qq{${decade}0};
          $decade_duration_to = "" . qq{${decade}9};    
      }
      else { 
          $decade_duration_from = "" . qq{${decade}8};  
          $decade_duration_to = "" . qq{${decadeplus3digit}9};  
      }

      ## make duration (-) for altLabel, depending on AD and BC (omitted, as double minus is confusing):
      my $decade_duration2 = "";
      if ($yyyy > 0000){
          $decade_duration2 = "" . qq{<skos:altLabel xml:lang="en">${decade}0-${decade}9</skos:altLabel>};
      }
      else {
      }

      ## make duration (-) for altLabel without prefix 0, depending on AD and BC (omitted, as double minus is confusing):
      $decade_duration3 = "";
      if ($yyyy > 0000){
          $decade_duration3 = "" . qq{<skos:altLabel xml:lang="en">${decadex}0 - ${decadex}9</skos:altLabel>};
      }
      else {
      }

      ## make duration with BC and AD for altLabel without prefix 0, depending on AD and BC:
      if ($yyyy == "0000"){
          $decade_duration4_from = "" . qq{AD 1};
          $decade_duration4_to = "" . qq{AD 9};
      }
      elsif ($yyyy == "-0010"){
          $decade_duration4_from = "" . qq{9 BC};
          $decade_duration4_to = "" . qq{1 BC};
      }
      elsif ($yyyy > 0000){
          $decade_duration4_from = "" . qq{AD ${decadex}0};
          $decade_duration4_to = "" . qq{AD ${decadex}9};
      }
      else {
          $decade_duration4_from = "" . qq{${decadex_nominus}9 BC};
          $decade_duration4_to = "" . qq{${decadex_nominus}0 BC};
      }

      # skos:broader depending on Before -0100, Between -0099 and 0000, and AD
      if ($yyyy <= 1) {
          $skosbroader = "" . qq{${semiumminus2digit}}; 
      }
      else { 
          $skosbroader = "" . qq{${semiumplus2digit}};  
      }

      ## DBpedia and YAGO links, depending on their URI syntax naming conditions:
      # Set up for the syntax depending on AD and BC
      if ($yyyy > 0000){
          $decade_label_dbpedia = "" . qq{${decadex}0s};
      }
      else { 
          $decade_label_dbpedia = "" . qq{${decadex_nominus}0s_BC};  
      }
      # Year xx00 (eg 1800) both in BC and AD always have _(decade) suffix for disambiguation
	  if ($yyyy =~ /00$/){
          $decade_dbpedia = "" . qq{${decade_label_dbpedia}_(decade)};  
      }
      # Entities are available between 1790 BC and 2090s in YAGO, decades outside this range are created for the future
      else { 
          $decade_dbpedia = "" . qq{${decade_label_dbpedia}};  
      }

############################ fill TEMPLATE and print
my $output;
	if ($yyyy == "-0010") {
	$output =  << "EOF";
	  <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/-001">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/decade"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">-001</skos:prefLabel>
        <rdfs:label xml:lang="en">-001</rdfs:label>
        <skos:altLabel xml:lang="en">10s BC</skos:altLabel>
        <skos:altLabel xml:lang="en">-0018/-0009</skos:altLabel>
        <skos:altLabel xml:lang="en">19 BC - 10 BC</skos:altLabel>
        <skos:definition xml:lang="en">A decade from -0018 to -0009 in ISO8601 (the Gregorian and proleptic Gregorian calendar). From 19 BC to 10 BC.</skos:definition>
        <skos:note>With regard to Date Entity modelling, documentation should be consulted at https://vocabs.acdh.oeaw.ac.at/date/. It includes information about URI syntax, ISO8601 conventions, and data enrichment among others.</skos:note>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <skos:exactMatch rdf:resource="http://dbpedia.org/resource/10s_BC"/>
        <skos:exactMatch rdf:resource="http://yago-knowledge.org/resource/10s_BC"/> 
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/-01"/>
        <time:intervalMeets rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/-000"/>
        <time:intervalMetBy rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/-002"/>
      </rdf:Description>
EOF
  	}
	elsif ($yyyy == "0000") {
	  $output =  << "EOF";
	  <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/-000">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/decade"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">-000</skos:prefLabel>
        <rdfs:label xml:lang="en">-000</rdfs:label>
        <skos:altLabel xml:lang="en">0s BC</skos:altLabel>
        <skos:altLabel xml:lang="en">-0008/0000</skos:altLabel>
        <skos:altLabel xml:lang="en">9 BC - 1 BC</skos:altLabel>
        <skos:definition xml:lang="en">A decade from -0008 to 0000 in ISO8601 (the Gregorian and proleptic Gregorian calendar). From 9 BC to 1 BC.</skos:definition>
        <skos:note>This entity concerns the period between 9 BC and 1 BC, the last nine years of the before Christ era. It is one of the two "0-to-9" decade-like timespans (along with 0s AD) that contain 9 years, and are not decades (10 years). With regard to Date Entity modelling, documentation should be consulted at https://vocabs.acdh.oeaw.ac.at/date/. It includes information about URI syntax, ISO8601 conventions, and data enrichment among others.</skos:note>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <skos:exactMatch rdf:resource="http://dbpedia.org/resource/0s_BC"/>
        <skos:exactMatch rdf:resource="http://yago-knowledge.org/resource/0s_BC"/> 
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/-01"/>
        <time:intervalMeets rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/000"/>
        <time:intervalMetBy rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/-001"/>
      </rdf:Description>
      
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/000">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/decade"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">000</skos:prefLabel>
        <rdfs:label xml:lang="en">000</rdfs:label>
        <skos:altLabel xml:lang="en">0s</skos:altLabel>
        <skos:altLabel xml:lang="en">0001/0009</skos:altLabel>
        <skos:altLabel xml:lang="en">0001-0009</skos:altLabel>
        <skos:altLabel xml:lang="en">1 - 9</skos:altLabel>
        <skos:altLabel xml:lang="en">AD 1 - AD 9</skos:altLabel>
        <skos:definition xml:lang="en">A decade from 0001 to 0009 in ISO8601 (the Gregorian and proleptic Gregorian calendar). From AD 1 to AD 9.</skos:definition>
        <skos:note>The 0s cover the first nine years of the Anno Domini era, which began on January 1, 1 AD and ended on December 31st, 9 AD. It is one of the two "0-to-9" decade-like timespans (along with 0s BC) that contain 9 years, and are not decades (10 years). With regard to Date Entity modelling, documentation should be consulted at https://vocabs.acdh.oeaw.ac.at/date/. It includes information about URI syntax, ISO8601 conventions, and data enrichment among others.</skos:note>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <skos:exactMatch rdf:resource="http://dbpedia.org/resource/0s"/>
        <skos:exactMatch rdf:resource="http://yago-knowledge.org/resource/0s"/> 
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/01"/>
        <time:intervalMeets rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/001"/>
        <time:intervalMetBy rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/-000"/>
      </rdf:Description>
EOF
	}
	else {
      $output =  << "EOF";
      <rdf:Description rdf:about="https://vocabs.acdh.oeaw.ac.at/date/${decade}">
        <rdf:type rdf:resource="https://vocabs.acdh.oeaw.ac.at/unit_of_time/decade"/>
        <rdf:type rdf:resource="http://www.w3.org/2004/02/skos/core#Concept"/>
        <skos:inScheme rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/conceptScheme"/>
        <skos:prefLabel xml:lang="en">${decade}</skos:prefLabel>
        <rdfs:label xml:lang="en">${decade}</rdfs:label>
        <skos:altLabel xml:lang="en">${decade_label}</skos:altLabel>
        <skos:altLabel xml:lang="en">${decade_duration_from}/${decade_duration_to}</skos:altLabel>
        ${decade_duration2}
        ${decade_duration3}
        <skos:altLabel xml:lang="en">${decade_duration4_from} - ${decade_duration4_to}</skos:altLabel>
        <skos:definition xml:lang="en">A decade from ${decade_duration_from} to ${decade_duration_to} in ISO8601 (the Gregorian and proleptic Gregorian calendar). From ${decade_duration4_from} to ${decade_duration4_to}.</skos:definition>
        <skos:note>With regard to Date Entity modelling, documentation should be consulted at https://vocabs.acdh.oeaw.ac.at/date/. It includes information about URI syntax, ISO8601 conventions, and data enrichment among others.</skos:note>
        <time:hasTRS rdf:resource="http://www.opengis.net/def/uom/ISO-8601/0/Gregorian"/>
        <skos:exactMatch rdf:resource="http://dbpedia.org/resource/${decade_dbpedia}"/>
        <skos:exactMatch rdf:resource="http://yago-knowledge.org/resource/${decade_dbpedia}"/> 
        <skos:broader rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/${skosbroader}"/>
        <time:intervalMeets rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$nextdecade"/>
        <time:intervalMetBy rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$prevdecade"/>
      </rdf:Description>
EOF
	}
      ## beautify $output -> remove empty lines!
      $output =~ s/\n\s+\n/\n/g; 

      print "$output\n";

      $prevdate = $date;  ## store current date as $prevdate
   #}

}

###################
print $DateRDFUtils::rdfend unless ($opt_H || $opt_d);
