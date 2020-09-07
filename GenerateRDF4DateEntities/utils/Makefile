## testing utf-encoding

test: rm u1

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
	md5sum $$out 

loopu1:
	echo "" > loopu1.txt;
	for i in 1 2 3 4 5 6 7 8 9 10; do echo "== $$i =="; \
	out=out_BC10_1_$$(date +%F_%Hh%Mm%Ss).rdf; \
	add_existing_rdf.pl -i sample_year_BC10.rdf -o $$out > out.BC10_1.log;  \
	md5sum $$out >> loopu1; \
	done
	grep -c abe1 loopu1

## run in test-mode (-t)
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
