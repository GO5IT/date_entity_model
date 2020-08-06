#!/bin/bash

set ue

# Specify the input file (which will be untouched)
I="sample_year_japansearch_enriched.rdf"

## remove path
IB=$(basename $I)

### LIMIT for testing: set to "0" for NO limit! 
# S = Specify the number of triples to be skipped (RDF subject i.e. Date Entity) from the start of the file
# L = Specify the number of triples to be processed
S="950"
L="100"

DAT=$(date +%F)

add_existing_rdf.pl -i $I \
                    -o out_${DAT}_${S}_${L}_${IB} \
                    -l out_${DAT}_${S}_${L}_${IB}.csv \
                    -L $L -S $S &> log_${DAT}_${S}_${L}_${IB}.txt
 
 
