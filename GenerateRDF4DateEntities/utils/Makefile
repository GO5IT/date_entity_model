export SHELL := /bin/bash

## testing utf-encoding

## run ONLY dbpedia
01dbp:
	nohup run_add_existing_stepbystep.sh -d -r 01_DBPedia sample_year.rdf 

## run 02_Wikidata _only_ for the first 2.100 years; these should be unproblematic!
02base:
	nohup run_add_existing_stepbystep.sh -d -r 02_Wikidata \
	       -S 0 -L 2100 \
       	       out_01_DBPedia2020-10-07_14h34m_0_0_sample_year.rdf

### continue running 02_Wikidata on result of 02base
02cont:
	nohup run_add_existing_stepbystep.sh -d -r 02_Wikidata \
               -S 2099  -L 0 \
	       out_02_Wikidata2020-10-08_10h01m_0_2100_out_01_DBPedia2020-10-07_14h34m_0_0_sample_year.rdf

## look for foreign characters
peek:
	grep '\@m' log_02_Wikidata2020-10-08_12h02m_2099_0_out_02_Wikidata2020-10-08_10h01m_0_2100_out_01_DBPedia2020-10-07_14h34m_0_0_sample_year.rdf.txt | tail
	
test: rm u1

y74:
	add_existing_rdf.pl -d -i sample_year_74AD.xml -o out_sample_year_74AD.xml > out_sample_year_74AD.log 


utf:
	run_add_existing.sh -d -S 0 -L 0 sample_year.rdf

s:
	@echo " "
	@grep -P '(abstract xml:lang="ar"|skos:altLabel.*"mr")' out*BC10*rdf
	md5sum out*BC10*rdf
	@echo " "

rm:
	rm out*BC10* log*BC10* || exit 0

u1:
	out=out_BC10_1_$$(date +%F_%Hh%Mm%Ss).rdf && \
	add_existing_rdf.pl -i sample_year_BC10.rdf -o $$out > out.BC10_1.log && \
	grep 'lang="mr"' $$out; \
	md5sum $$out; 

test10fetch:
	dat=$$(date +%F_%Hh%Mm); m5=test10_md5_$$dat.txt; he=test10_mr_$$dat.txt; \
	echo "" > $$m5; echo "" > $$he; \
	for i in {1..10}; do \
	echo "== $$i =="; \
	out=out_test10_AD74_$${dat}_$${i}.rdf; \
	add_existing_rdf.pl -d -i sample_year_74AD.xml  -o $$out > out_test10_AD74_$${dat}_$${i}.log;  \
	md5sum $$out >> $$m5; \
	done; \
	grep 'xml:lang="mr"' out_test10_AD74_$${dat}_*.rdf > $$he; \
	echo -e "\n== Summary mr =="; \
	cat $$he | cut -f 2 | sort | uniq -c; \
	echo -e "\n== Summary md5 =="; \
	cat $$m5 | cut -d ' ' -f 1 | grep -P '...' | sort | uniq -c; \
	echo -e "\n\n"; \
	

test10sum:
	@echo -e "\n== Global Summary mr ==";
	@cut -f 2 test10_mr*txt |  sort | uniq -c; 
	@echo -e "\n== Global Summary md5 ==";
	@cut -d " " -f 1 test10_md5*txt | grep -P '...' |  sort | uniq -c;
	@echo -e

test10clean:
	@echo -e "\n== Cleaning temporal files from test10 ...\n";
	rm -v rm out_test10_* 
	

test10: test10fetch test10sum

t:
	out=out_BC10_JUSTECHO_$$(date +%F_%Hh%Mm%Ss).rdf && \
	add_existing_rdf.pl -t -i BC10earlier_result.rdf -o $$out | tee out.BC10_JUSTECHO.log && \
	md5sum $$out 

u:
	 add_existing_rdf.pl -d -i sample_year_BC10.rdf -o out_BC10_1_$$(date +%F_%Hh%Mm%Ss).rdf > out.BC10_1.log
	 add_existing_rdf.pl -d -i sample_year_BC10.rdf -o out_BC10_2_$$(date +%F_%Hh%Mm%Ss).rdf > out.BC10_2.log
	 add_existing_rdf.pl -d -i sample_year_BC10.rdf -o out_BC10_3_$$(date +%F_%Hh%Mm%Ss).rdf > out.BC10_3.log
	 add_existing_rdf.pl -d -i sample_year_BC10.rdf -o out_BC10_4_$$(date +%F_%Hh%Mm%Ss).rdf > out.BC10_4.log


ux:
	 add_existing_rdf.pl -d -i sample_year_BC10.rdf -o out_BC10_1_$$(date +%F_%Hh%Mm%Ss).rdf > out.BC10_1.log
	 @grep 'skos:altLabel.*"mr"' out*BC10*rdf
	 rm out*BC10*
	 add_existing_rdf.pl -d -i sample_year_BC10.rdf -o out_BC10_2_$$(date +%F_%Hh%Mm%Ss).rdf > out.BC10_2.log
	 @grep 'skos:altLabel.*"mr"' out*BC10*rdf
	rm out*BC10*
	 add_existing_rdf.pl -d -i sample_year_BC10.rdf -o out_BC10_3_$$(date +%F_%Hh%Mm%Ss).rdf > out.BC10_3.log
	 @grep 'skos:altLabel.*"mr"' out*BC10*rdf
	rm out*BC10*
