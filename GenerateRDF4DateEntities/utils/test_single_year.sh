#!/bin/bash

## set resource-name - everything else should work  
R="AD_2"

## OF COURSE you NEED a file called: 
## sample_$R.rdf
## e.g.
## R="AD_2" ==> file:  sample_AD_2.rdf

I=sample_${R}.rdf

if [[ ! -s $I ]]; then
  echo -e "\nInput file is missing or is empty: $I\n"
fi

add_existing_rdf.pl -i$I -o out.$I -l log.$I -d &> log.$I.stderr.txt

## also fetch AD2-data from dbpedia for inspection
##  <skos:exactMatch rdf:resource="http://dbpedia.org/resource/AD_2"/>
wget --header='Accept:application/rdf+xml' -O sample_${R}_from_dbpdia.rdf "http://dbpedia.org/resource/$R"

