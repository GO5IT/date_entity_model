#!/usr/bin/perl 

use strict;
use warnings;
use Getopt::Std;

our ($opt_h, $opt_d);
getopts('hd');

if ($opt_h) {
 usage();
 exit;
}


### new: with the "x" option (at the end of the substitution pattern) you are allowed to use newline and comments in the substitution 
###      in order to improve readability

## MAIN LOOP 
LINE: while(<>) {
   
  ## on each input line: perform your substitutions
	s{<rdf:RDF.*xmlns:rdf}
         {<rdf:RDF xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:rdf}gx;

	s{"http:\/\/sws\.geonames\.org\/?(.*)"}
         {"http://sws.geonames.org/$1/"}gx;

	s{"http:\/\/d-nb\.info\/gnd\/?(.*)"}
         {"https://d-nb.info/gnd/$1"}gx;

	s{<edm:provider>Austrian National Library<\/edm:provider>}
         {<edm:provider>Austrian National Library</edm:provider>\n\n\t\t\t\t<skos:changeNote>EDM Provider enrichment by Go 2019-12-05</skos:changeNote>\n\t\t\t\t<edm:provider rdf:resource="https://d-nb.info/gnd/2020893-5"/>\n\t\t\t\t<edm:provider rdf:resource="http://viaf.org/viaf/136765452"/>\n\t\t\t\t<edm:provider rdf:resource="http://www.wikidata.org/entity/Q304037"/>\n\t\t\t\t<edm:provider rdf:resource="http://dbpedia.org/resource/Austrian_National_Library"/>\n\t\t\t\t<edm:provider rdf:resource="http://de.dbpedia.org/resource/Österreichische_Nationalbibliothek"/>\n}gx;

	s{<dc:date>?(\d{4})<\/dc:date>}
          {<dc:date>$1</dc:date>\n\n\t\t\t\t<skos:changeNote>2 digit Date enrichment by Go 2019-12-05</skos:changeNote>\n\t\t\t\t<dc:date rdf:datatype="http://www.w3.org/2001/XMLSchema#date">$1</dc:date>\n\t\t\t\t<dc:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1"/>\n\t\t\t\t<dc:date rdf:resource="http://dbpedia.org/resource/$1"/>\n}gx;

	s{<dc:date>?(\d{4})-?(\d{2})-?(\d{2})<\/dc:date>}
          {<dc:date>$1-$2-$3</dc:date>\n\n\t\t\t\t<skos:changeNote>4 digit Date enrichment by Go 2019-12-05</skos:changeNote>\n\t\t\t\t<dc:date rdf:datatype="http://www.w3.org/2001/XMLSchema#date">$1-$2-$3</dc:date>\n\t\t\t\t<dc:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1-$2-$3"/>\n\t\t\t\t<dc:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1-$2"/>\n\t\t\t\t<dc:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1"/>\n\t\t\t\t<dc:date rdf:resource="http://dbpedia.org/resource/$1"/>\n}gx;

	s{<dc:type>newspaper<\/dc:type>}
         {<dc:type>newspaper</dc:type>\n\n\t\t\t\t<skos:changeNote>Newspaper type enrichment by Go 2019-12-05</skos:changeNote>\n\t\t\t\t<dc:type rdf:resource="http://iconclass.org/46D3"/>\n}gx;

	s{<edm:type>TEXT<\/edm:type>}
          {<edm:type>TEXT</edm:type>\n\n\t\t\t\t<skos:changeNote>edm:type TEXT enrichment by Go 2019-12-05</skos:changeNote>\n\t\t\t\t<dcmitype:type rdf:resource="http://purl.org/dc/dcmitype/Text"/>\n}gx;





# Regular Expression can be specified and repeated as follows. "g" means for all occurences
# 's{REGEX 1 to match}{REGEX 1 to replace}gx;s{REGEX 2 to match}{REGEX 2 to replace}gx;'
# Script part should be in one line!!

## Script for ANNO Enrichment (2019-12-05)
#xargs -0 perl -pi -e 's{<rdf:RDF.*xmlns:rdf}{<rdf:RDF xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:rdf}gx;s{"http:\/\/sws\.geonames\.org\/?(.*)"}{"http://sws.geonames.org/$1/"}gx;s{"http:\/\/d-nb\.info\/gnd\/?(.*)"}{"https://d-nb.info/gnd/$1"}gx;s{<edm:provider>Austrian National Library<\/edm:provider>}{<edm:provider>Austrian National Library</edm:provider>\n\n\t\t\t\t<skos:changeNote>EDM Provider enrichment by Go 2019-12-05</skos:changeNote>\n\t\t\t\t<edm:provider rdf:resource="https://d-nb.info/gnd/2020893-5"/>\n\t\t\t\t<edm:provider rdf:resource="http://viaf.org/viaf/136765452"/>\n\t\t\t\t<edm:provider rdf:resource="http://www.wikidata.org/entity/Q304037"/>\n\t\t\t\t<edm:provider rdf:resource="http://dbpedia.org/resource/Austrian_National_Library"/>\n\t\t\t\t<edm:provider rdf:resource="http://de.dbpedia.org/resource/Österreichische_Nationalbibliothek"/>\n}gx;s{<dc:date>?(\d{4})<\/dc:date>}{<dc:date>$1</dc:date>\n\n\t\t\t\t<skos:changeNote>2 digit Date enrichment by Go 2019-12-05</skos:changeNote>\n\t\t\t\t<dc:date rdf:datatype="http://www.w3.org/2001/XMLSchema#date">$1</dc:date>\n\t\t\t\t<dc:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1"/>\n\t\t\t\t<dc:date rdf:resource="http://dbpedia.org/resource/$1"/>\n}gx;s{<dc:date>?(\d{4})-?(\d{2})-?(\d{2})<\/dc:date>}{<dc:date>$1-$2-$3</dc:date>\n\n\t\t\t\t<skos:changeNote>4 digit Date enrichment by Go 2019-12-05</skos:changeNote>\n\t\t\t\t<dc:date rdf:datatype="http://www.w3.org/2001/XMLSchema#date">$1-$2-$3</dc:date>\n\t\t\t\t<dc:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1-$2-$3"/>\n\t\t\t\t<dc:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1-$2"/>\n\t\t\t\t<dc:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1"/>\n\t\t\t\t<dc:date rdf:resource="http://dbpedia.org/resource/$1"/>\n}gx;s{<dc:type>newspaper<\/dc:type>}{<dc:type>newspaper</dc:type>\n\n\t\t\t\t<skos:changeNote>Newspaper type enrichment by Go 2019-12-05</skos:changeNote>\n\t\t\t\t<dc:type rdf:resource="http://iconclass.org/46D3"/>\n}gx;s{<edm:type>TEXT<\/edm:type>}{<edm:type>TEXT</edm:type>\n\n\t\t\t\t<skos:changeNote>edm:type TEXT enrichment by Go 2019-12-05</skos:changeNote>\n\t\t\t\t<dcmitype:type rdf:resource="http://purl.org/dc/dcmitype/Text"/>\n}gx;'

# Script for AKON Enrichment (2019-12-04)
#xargs -0 perl -pi -e 's{<rdf:RDF.*xmlns:rdf}{<rdf:RDF xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:rdf}gx;s{"http:\/\/sws\.geonames\.org\/?(.*)"}{"http:\/\/sws\.geonames\.org\/$1/"}gx;s{<dc:type>postcard<\/dc:type>}{<dc:type>postcard</dc:type>\n\n\t\t\t\t<skos:changeNote>Type enrichment by Go 2019-12-04</skos:changeNote>\n\t\t\t\t<dc:type rdf:resource="https://d-nb.info/gnd/4046902-5"/>\n}gx;s{<dc:date>?(\d{4})<\/dc:date>}{<dc:date>$1</dc:date>\n\n\t\t\t\t<skos:changeNote>Date enrichment by Go 2019-12-04</skos:changeNote>\n\t\t\t\t<dc:date rdf:resource="http://dbpedia.org/resource/$1"/>\n\t\t\t\t<dc:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1"/>\n}gx;s{<edm:type>IMAGE<\/edm:type>}{<edm:type>IMAGE</edm:type>\n\n\t\t\t\t<skos:changeNote>EDM Type enrichment by Go 2019-12-04</skos:changeNote>\n\t\t\t\t<edm:type rdf:resource="https://d-nb.info/gnd/4006568-6"/>\n\t\t\t\t<dcmitype:type rdf:resource="http://purl.org/dc/dcmitype/Image"/>\n}gx;s{<edm:provider>Austrian National Library<\/edm:provider>}{<edm:provider>Austrian National Library</edm:provider>\n\n\t\t\t\t<skos:changeNote>EDM Provider enrichment by Go 2019-12-04</skos:changeNote>\n\t\t\t\t<edm:provider rdf:resource="https://d-nb.info/gnd/2020893-5"/>\n\t\t\t\t<edm:provider rdf:resource="http://viaf.org/viaf/136765452"/>\n\t\t\t\t<edm:provider rdf:resource="http://www.wikidata.org/entity/Q304037"/>\n\t\t\t\t<edm:provider rdf:resource="http://dbpedia.org/resource/Austrian_National_Library"/>\n\t\t\t\t<edm:provider rdf:resource="http://de.dbpedia.org/resource/Österreichische_Nationalbibliothek"/>\n}gx;'

#Scripts for Date Enrichment
#Script for YYYY-DD-YY
#xargs -0 perl -pi -e 's{<szd:when>.*?(\d{4})-?(\d{2})-?(\d{2}).*<\/szd:when>}{<szd:when>$1-$2-$3<\/szd:when>\n\n<rdfs:comment>Date enriched by Go</rdfs:comment>\n<dcterms:date rdf:resource="http://dbpedia.org/resource/$1"/>\n<dcterms:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1"/>\n<dcterms:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$2"/>\n<dcterms:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$3"/>\n<dcterms:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1-$2"/>\n<dcterms:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1-$2-$3"/>\n}gx;'
#Script for YYYY-DD
#xargs -0 perl -pi -e 's{<szd:when>?(\d{4})-?(\d{2})<\/szd:when>}{<szd:when>$1-$2<\/szd:when>\n\n<rdfs:comment>Date enriched by Go</rdfs:comment>\n<dcterms:date rdf:resource="http://dbpedia.org/resource/$1"/>\n<dcterms:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1"/>\n<dcterms:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$2"/>\n<dcterms:date rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1-$2"/>\n}gx;'

#Scripts for Place Enrichment
#1st run to extract places from <szd:head> (any places including Wien)
#xargs -0 perl -pi -e 's{<szd:head>?(.*), ?(.*)<\/szd:head>}{<szd:head>$1, $2<\/szd:head>\n\n<rdfs:comment>Place enriched by Go</rdfs:comment>\n<dcterms:spatial>$1</dcterms:spatial>\n}gx;'
#2nd script to create additional info (ie GND) only for Wien
#xargs -0 perl -pi -e 's{<dcterms:spatial>Wien<\/dcterms:spatial>}{<dcterms:spatial>Wien<\/dcterms:spatial>\n<dcterms:spatial>Vienna</dcterms:spatial>\n<dcterms:spatial rdf:resource="http://d-nb.info/gnd/4066009-6"/>}gx;'

#Bibliothek.rdf (Stefan Zweig data)
#1st extract YYYY and manually modify small exceptions (YYYY-YYYY)
#xargs -0 perl -pi -e 's{<szd:dateOfPublication>?(.*)?(S\d{4})<\/szd:dateOfPublication>}{<szd:dateOfPublication>$1$2<\/szd:dateOfPublication>\n\n<rdfs:comment>Date enriched by Go</rdfs:comment>\n<dcterms:issued rdf:resource="http://dbpedia.org/resource/$2"/>\n<dcterms:issued rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$2"/>\n}gx;'

#Personen.rdf (Stefan Zweig data)
# Add dbo namespace
#<rdf:RDF xmlns:dbo="http://dbpedia.org/ontology/"
#BirthDate
#1st extract YYYY (1375 cases)
#xargs -0 perl -pi -e 's{<gnd:dateOfBirth rdf:datatype="http:\/\/www.w3.org\/2001\/XMLSchema#date">?(\d{4})?(.*)<\/gnd:dateOfBirth>}{<gnd:dateOfBirth rdf:datatype="http://www.w3.org/2001/XMLSchema#date">$1$2</gnd:dateOfBirth>\n\n<rdfs:comment>Date enriched by Go</rdfs:comment>\n<dbo:birthDate rdf:resource="http://dbpedia.org/resource/$1"/>\n<dbo:birthDate rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1"/>\n}gx;'
#2nd extract YYYY-MM-DD (975 cases) done with text editor (script does not work)
#xargs -0 perl -pi -e 's{<gnd:dateOfBirth rdf:datatype="http:\/\/www.w3.org\/2001\/XMLSchema#date">?(\d{4})-?(\d{2})-?(\d{2})<\/gnd:dateOfBirth>\n\n<rdfs:comment>Date enriched by Go<\/rdfs:comment>}{<gnd:dateOfBirth rdf:datatype="http://www.w3.org/2001/XMLSchema#date">$1-$2-$3</gnd:dateOfBirth>\n\n<rdfs:comment>Date enriched by Go</rdfs:comment>\n<dbo:birthDate rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1-$2"/>\n<dbo:birthDate rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1-$2-$3"/>\n<dbo:birthDate rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$2"/>\n<dbo:birthDate rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$3"/>}gx;'
#Manual enrichment for YYYY-MM (4 cases) done with text editor
#<gnd:dateOfBirth rdf:datatype="http:\/\/www.w3.org\/2001\/XMLSchema#date">?(\d{4})-?(\d{2})<\/gnd:dateOfBirth>\n\n<rdfs:comment>Date enriched by Go<\/rdfs:comment>
#Manual enrichment for -YYYY (11 cases) done with text editor
#<gnd:dateOfBirth rdf:datatype="http:\/\/www.w3.org\/2001\/XMLSchema#date">-\d{4}<\/gnd:dateOfBirth>\n\n<rdfs:comment>Date enriched by Go<\/rdfs:comment>
#DeathDate
#1st extract YYYY (1358 cases)
#xargs -0 perl -pi -e 's{<gnd:dateOfDeath rdf:datatype="http:\/\/www.w3.org\/2001\/XMLSchema#date">?(\d{4})?(.*)<\/gnd:dateOfDeath>}{<gnd:dateOfDeath rdf:datatype="http:\/\/www.w3.org\/2001\/XMLSchema#date">$1$2<\/gnd:dateOfDeath>\n\n<rdfs:comment>Date enriched by Go</rdfs:comment>\n<dbo:deathDate rdf:resource="http://dbpedia.org/resource/$1"/>\n<dbo:deathDate rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1"/>\n}gx;'
#2nd extract YYYY-MM-DD (958 cases) done with text editor (script does not work)
#xargs -0 perl -pi -e 's{<gnd:dateOfDeath rdf:datatype="http:\/\/www.w3.org\/2001\/XMLSchema#date">?(\d{4})-?(\d{2})-?(\d{2})<\/gnd:dateOfDeath>\n\n<rdfs:comment>Date enriched by Go<\/rdfs:comment>}{<gnd:dateOfDeath rdf:datatype="http://www.w3.org/2001/XMLSchema#date">$1-$2-$3</gnd:dateOfDeath>\n\n<rdfs:comment>Date enriched by Go</rdfs:comment>\n<dbo:deathDate rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1-$2"/>\n<dbo:deathDate rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$1-$2-$3"/>\n<dbo:deathDate rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$2"/>\n<dbo:deathDate rdf:resource="https://vocabs.acdh.oeaw.ac.at/date/$3"/>}gx;'
#Manual enrichment for YYYY-MM (2 cases) done with text editor
#<gnd:dateOfDeath rdf:datatype="http:\/\/www.w3.org\/2001\/XMLSchema#date">?(\d{4})-?(\d{2})<\/gnd:dateOfDeath>\n\n<rdfs:comment>Date enriched by Go<\/rdfs:comment>
#Manual enrichment for -YYYY (11 cases) done with text editor
#<gnd:dateOfBirth rdf:datatype="http:\/\/www.w3.org\/2001\/XMLSchema#date">-\d{4}<\/gnd:dateOfBirth>\n\n<rdfs:comment>Date enriched by Go<\/rdfs:comment>


 ## everything done? print
  print;
}





sub usage {
  print <<EOF

USAGE: $0 (-h) (-d) <RDF_FILE>

Enhance the content of <RDF_FILE> 

Reads from file or <STDIN> and writes to <STDOUT>

OPTIONS: 

-h		Print this message
-d              Debug mode

EOF
}


