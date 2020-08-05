#!/bin/bash

set ue

I="sample_year_japansearch_enriched.rdf"

## remove path
IB=$(basename $I)

### LIMIT for testing: set to "0" for NO limit!
L="0"
DAT=$(date +%F)

echo $(date +%F) > timestamp_start_${L}_$DAT;
add_existing_rdf.pl -i $I -o out_${DAT}_${L}_${IB} -l out_${DAT}_${L}_${IB}.csv -L $L &> log_${DAT}_${L}_${IB}.txt
echo $(date +%F) > timestamp_end_${L}_$DAT;

