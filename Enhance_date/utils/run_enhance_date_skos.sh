#!/bin/bash

# perl basics:

# perl -p -i.bak -e :
#  -p means :  read line by line from input file, perform all commands, print result.
#  -i.bak   :  modify the input file but keep a backup-copy of the original with the extension .bak
#  -e       :  the "program-code" follows directly on the command line

## substitution in perl: s/FROM/TO/;
## or more readable    : s{FROM}{TO};

# "binding" in substitutions:
## everything inside "( )" in the FROM-expression will be bound to a variable $1, $2, ... which can be used the TO-expression

# Specify the folder which contains data files below
INDIR="./dump_anno"
OUTDIR="./dump_out"

SCRIPT="./enhance_date_skos.pl"

if [[ ! -x "$SCRIPT" ]]; then
  echo -e "\nscript $SCRIPT is missing or is not executable!\n";
  exit;
fi

if [[ ! -d "$INDIR" ]]; then
  echo -e "Folder INDIR does not exist: $INDIR!\n";
  exit
fi

echo -e "\nProcessing files in folder: ${INDIR}\n"
echo -e "\n\n==========\nStarting: $(date) ...\n=================\n"

## first find all subdirectories of indir and create them ...
echo -e "\n## checking subdirectories in $INDIR and creating them in $OUTDIR if necessary ..."
find "$INDIR" -type d -print0 |\
xargs --null -I{} sh -c 'newdir="$(echo "$1" | perl -pe "s|$2|$3|;")"; mkdir -vp "$newdir"'  -- {}  "$INDIR" "$OUTDIR"  


#############
## all the "real" processing was moved to a separate perl-script ... run it on each file
#############
echo -e "\n## find all files in $INDIR and run script $SCRIPT on them ..."  
find "$INDIR"  -maxdepth 1 -name "*.rdf" -print0 |\
xargs --null -I{} sh -c 'perlscript=$4; infile=$1; newfile="$(echo "$infile" | perl -pe "s|$2|$3|;")"; $perlscript "$infile" > "$newfile"'  -- {}  "$INDIR" "$OUTDIR" "$SCRIPT"


# If backup files (.bak) should be created, use the following:
# xargs -0 perl -pi.bak -e 's{<dc:date>(.*?(\d{4}).*)<\/dc:date>}{<dc:date>$1<\/dc:date>\n\t\t\t\t<skos:changeNote>Date enrichment by Go</skos:changeNote>\n\t\t\t\t<dc:date>http://dbpedia.org/resource/$2</dc:date>};'


echo -e "\n\n==========\nFinished: $(date) ...\n=================\n"

# Below is set to display the statistics of the data processing by this script
echo -e "Total number of files   in ${INDIR}: $(find ${INDIR} -maxdepth 1 -name '*.rdf' | wc -l)\n"
echo -e "Total number of files   in ${OUTDIR}: $(find ${OUTDIR} -maxdepth 1 -name '*.rdf' | wc -l)\n"

echo -e "Number of DCMI namaspace changed in ${OUTDIR}: $(find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -l '<rdf:RDF xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:rdf' | wc -l)\n"
echo -e "Number of GND http changed in ${OUTDIR}: $(find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -l 'https://d-nb.info/gnd/' | wc -l)\n"
echo -e "Number of GeoNames / changed in ${OUTDIR}: $(find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -l -P 'http://sws.geonames.org/.*/' | wc -l)\n"
echo -e "Number of Type changed in ${OUTDIR}: $(find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -l 'Newspaper type enrichment by Go 2019-12-05' | wc -l)\n"
echo -e "Number of 2 digit Date changed in ${OUTDIR}: $(find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -l '2 digit Date enrichment by Go 2019-12-05' | wc -l)\n"
echo -e "Number of 4 digit Date changed in ${OUTDIR}: $(find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -l '4 digit Date enrichment by Go 2019-12-05' | wc -l)\n"
echo -e "Number of EDM Type changed in ${OUTDIR}: $(find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -l 'edm:type TEXT enrichment by Go 2019-12-05' | wc -l)\n"
echo -e "Number of EDM Provider changed in ${OUTDIR}: $(find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -l 'EDM Provider enrichment by Go 2019-12-05' | wc -l)\n"

#echo -e "Number of Type changed in ${OUTDIR}: $(find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -l 'Type enrichment by Go' | wc -l)\n"
#echo -e "Number of Newspaper Type changed in ${OUTDIR}: $(find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -l 'Newspaper type enrichment by Go' | wc -l)\n"
echo -e "List of unchanged DCMI namespace are "
find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -L '<rdf:RDF xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:rdf' | head -n 100 | tee list_of_unchanged_$(date +%F).txt
echo -e "List of unchanged GND http are "
find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -L 'https://d-nb.info/gnd/' | head -n 100 | tee list_of_unchanged_$(date +%F).txt
echo -e "List of unchanged Newspaper Type are "
find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -L 'Newspaper type enrichment by Go 2019-12-05' | head -n 100 | tee list_of_unchanged_$(date +%F).txt
echo -e "List of unchanged Date are "
find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -L 'Date enrichment by Go 2019-12-05' | head -n 100 | tee list_of_unchanged_$(date +%F).txt
echo -e "List of unchanged EDM Type are "
find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -L 'edm:type TEXT enrichment by Go 2019-12-05' | head -n 100 | tee list_of_unchanged_$(date +%F).txt
echo -e "List of unchanged EDM Provider are "
find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -L 'EDM Provider enrichment by Go 2019-12-05' | head -n 100 | tee list_of_unchanged_$(date +%F).txt

#echo -e "List of unchanged Type are "
#find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -L 'Type enrichment by Go' | head -n 100 | tee list_of_unchanged_$(date +%F).txt
#echo -e "List of unchanged Newspaper Type are "
#find ${OUTDIR} -maxdepth 1 -name '*.rdf' -print0  | xargs -0 grep -L 'Newspaper type enrichment by Go' | head -n 100 | tee list_of_unchanged_$(date +%F).txt


