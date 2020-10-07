#!/bin/bash

### LIMIT for testing: set to "0" for NO limit! 
# S = Specify the number of triples to be skipped (RDF subject i.e. Date Entity) from the start of the file
# L = Specify the number of triples to be processed
## DEFAULT VALUES for L and S
S="0"
L="0"


## maximum size of log-file in MB 
## iff it is bigger, it will be split!
MAXSIZE=50

## 
SCRIPT="add_existing_rdf.pl"

## DEBUG option
DEBUG="" 

DAT=$(date +%F_%Hh%Mm)

usage() 
{
cat << EOF

Usage: $0  (-h) (-d) (-S <SKIP_N>) (-L <LIMIT_M>) (-r <PROCESSING_STEP>) <RDF-XML-FILE>

Run $SCRIPT on <RDF-XML-FILE>

OPTIONS:

-r  <PROCESSING_STEP> 
		    Choose from: 01_DBPedia, 02_Wikidata
		    Will be passed: to $SCRIPT

-S  <SKIP_N>         Skip <SKIP_N> years before starting to process
		
-L  <LIMIT_M>        Limit processing to a total of <LIMIT_M> years
                     "0" means: there is NO limit

-d                   Debug mode

-h                   Print this message

ALSO SEE:
 
 $SCRIPT

EOF
}

OPTR="";

while getopts "S:L:dhr:" OPTION; do
        case $OPTION in
	        r)
	                OPTR=$OPTARG
			;;      
                S)
                        S=$OPTARG       
                        ;;
                L)
                        L=$OPTARG       
                        ;;
                d)
                        DEBUG="-d"
                        ;;
                h) 
                        usage
                        exit 1
                        ;;
                \?)
                        usage
                        exit 1

        esac
done

## remove all command-line options
shift $(($OPTIND - 1))

I=$1;

if [[ ! -s $I ]]; then 
   echo -e "\nInput not specified or not a file or empty: $I\n"; 
   exit
fi

if [[ -z "$OPTR" ]]; then 
   echo -e "\nOption -r <PROCESSINGSTEP> is missing!\n";
   exit;
fi


## remove path
IB=$(basename $I)

logcsv="out_${OPTR}${DAT}_${S}_${L}_${IB}.csv"
log="log_${OPTR}${DAT}_${S}_${L}_${IB}.txt"

$SCRIPT $DEBUG      -i $I \
                    -o out_$OPTR${DAT}_${S}_${L}_${IB} \
		    -r $OPTR \
                    -l $logcsv \
                    -L $L -S $S &> $log

############ should not happen anymore 
### iff size of logfile exceeds maxsize (in MB ): split it!

actualsize=$(du -m "$logcsv" | cut -f 1)
if [ $actualsize -gt $MAXSIZE ]; then
    echo "size of logfile is $actualsize MB i.e. it exceeds $MAXSIZE MB"
    echo -e "\n## Because the log - csv is WAY too big: split it in chunks of ${MAXSIZE}M each ...\n";
    split --additional-suffix .csv -a 3 -d -C ${MAXSIZE}M $logcsv out_${DAT}_${S}_${L}_${IB}_ 
else
	echo ""
   # echo -e "\n## Size of logfile is smaller than MAXSIZE of $MAXSIZE MB; it does not require splitting\n"
fi

 
