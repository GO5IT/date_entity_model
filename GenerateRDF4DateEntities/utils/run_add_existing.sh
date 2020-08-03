#!/bin/bash

set ue

I="sample_year_japansearch_enriched.rdf"

## remove path
IB=$(basename $I)

### LIMIT for testing: set to "0" for NO limit!
L="5"
DAT=$(date +%F)

nohup add_existing_rdf.pl -i $I -o out_${DAT}_${L}_${IB} -l out_${DAT}_${L}_${IB}.csv -L $L &> log_${DAT}_${L}_${IB}.txt

