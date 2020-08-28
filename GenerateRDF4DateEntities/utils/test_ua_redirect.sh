#!/bin/bash

mkdir -p TESTREDIRECT;
#rm TESTREDIRECT/*

# for u in  orig redirect rdf ; do 
for u in  rdf ; do 
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

wget --header='Accept:application/rdf+xml' -O TESTREDIRECT/wget_dbpediaORIG_AD1965.rdf 'http://dbpedia.org/resource/AD_1969'


wget --header='Accept:application/rdf+xml' -O TESTREDIRECT/wget_dbpediaREDIRECT_page2.rdf 'http://dbpedia.org/page/2'
wget --header='Accept:application/rdf+xml' -O TESTREDIRECT/wget_dbpediaRDF_page2.rdf 'http://dbpedia.org/data/2.rdf'

wget --header='Accept:application/rdf+xml' -O TESTREDIRECT/wget_dbpediaRESOURCE2.rdf 'http://dbpedia.org/resource/2'

## 222 
wget --header='Accept:application/rdf+xml' -O TESTREDIRECT/wget_dbpediaRESOURCE333.rdf 'http://dbpedia.org/resource/333'

