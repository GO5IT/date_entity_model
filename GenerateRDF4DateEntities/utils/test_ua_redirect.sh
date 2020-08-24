#!/bin/bash

mkdir -p TESTREDIRECT;
#rm TESTREDIRECT/*

for u in  orig ; do 
 for a in html rdf; do
 for r in 0 1 2 3; do
       echo -e "u=$u\ta=$a\tr=$r ...";
       test_ua_redirect.pl -u $u -a $a -r $r > TESTREDIRECT/testredirect_${u}_${r}.$a
   done
 done 
done

wc -l TESTREDIRECT/*

### alternatively use wget:
#orig: http://dbpedia.org/resource/AD_2
#wird im browser redirectet zu: http://dbpedia.org/page/2

wget --header='Accept:application/rdf+xml' -O TESTREDIRECT/wget_dbpediaORIG_AD2.rdf 'http://dbpedia.org/resource/AD_2'
wget --header='Accept:application/rdf+xml' -O TESTREDIRECT/wget_dbpediaREDIRECT_page2.rdf 'http://dbpedia.org/page/2'
