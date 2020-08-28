#!/bin/bash

set ue

# Specify the input file (which will be untouched)
#I="sample_year_japansearch_enriched.rdf"
I="sample_year.rdf"

## remove path
IB=$(basename $I)

### LIMIT for testing: set to "0" for NO limit! 
# S = Specify the number of triples to be skipped (RDF subject i.e. Date Entity) from the start of the file
# L = Specify the number of triples to be processed
S="0"
L="0"

## DEBUG??
DEBUG="-d" 

DAT=$(date +%F_%Hh%Mm)

add_existing_rdf.pl $DEBUG -i $I \
                    -o out_${DAT}_${S}_${L}_${IB} \
                    -l out_${DAT}_${S}_${L}_${IB}.csv \
                    -L $L -S $S &> log_${DAT}_${S}_${L}_${IB}.txt


############ should not happen anymore 
### if size of logfile exceeds maxsize (in MB ): split it!
MAXSIZE=50
actualsize=$(du -m "out_${DAT}_${S}_${L}_${IB}.csv" | cut -f 1)
if [ $actualsize -gt $MAXSIZE ]; then
    echo "size of logfile is $actualsize MB i.e. it exceeds $MAXSIZE MB"
    echo -e "\n## Because the log - csv is WAY too big: split it in chunks of 100MB each ...\n";
    split --additional-suffix .csv -a 3 -d -C ${MAXSIZE}M out_${DAT}_${S}_${L}_${IB}.csv out_${DAT}_${S}_${L}_${IB}_ 
else
    echo "size of logfile is under $MAXSIZE MB"
fi

 
