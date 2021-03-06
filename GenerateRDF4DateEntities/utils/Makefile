export SHELL := /bin/bash

### To call a function (i.e. scripts listed below) in the command line, for example, type: make generate_day
### To follow the entire Workflow, please read the documentation and excute the corresponding script in the given order

######################################################################################  
################## Date Entities generation ##########################################
######################################################################################
### This is a script to generate Date Entities (rdf/xml). To create the complete range of entities from millannia to days,
### you need to run dozens of customised scripts one by one for different levels of entities. See https://redmine.acdh.oeaw.ac.at/issues/17311
### 
### The following files are required in the same folder: /home/go/Date_Entity_Model/GenerateRDF4DateEntities/utils:
### 1. run_generate_tests.sh, the main script to run
### 2. generate_xxxx_rdf.pl (e.g. generate_year_rdf.pl), which configure the data generation for the level of entity (year, month etc)
### 3. DateRDFUtils.pm, a module which is imported to pl
### 
### Before running a script, configure the target script (generate_xxxx_rdf.pl) and run_generate_tests.sh
### sample_${type}.rdf (name specified run_generate_tests.sh) will be generated as output
generate:
	nohup run_generate_tests.sh


generate_day:
	generate_day_rdf.pl -l 0 > sample_day.rdf

generate_month:
	generate_month_rdf.pl -l 0 > sample_month.rdf

generate_year:
	generate_year_rdf.pl -l 0 > sample_year.rdf

generate_decade:
	generate_decade_rdf.pl -l 0 > sample_decade.rdf

generate_century:
	generate_century_rdf.pl -l 0 > sample_century.rdf

generate_millennium:
	generate_millennium_rdf.pl -l 0 > sample_millennium.rdf


## test: using file-name as rule-name: then this rule will only be called 
##       if file does not yet exist
##   Otherwise it will say: 
# make sample_millennium.rdf
# make: 'sample_millennium.rdf' is up to date.
sample_millennium.rdf:
	generate_millennium_rdf.pl -l 0 > sample_millennium.rdf

generate_all: generate_day generate_month generate_year generate_decade generate_century generate_millenium


## use xml_split + xml_merge to split final result into chunks of 500 MB. 
## xml_split produces a "meta-file" ...
#<?xml version="1.0" encoding="utf-8"?>
#<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:dbo="http://dbpedia.org/ontology/" xmlns:dc="http://purl.org/dc/elements/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:owl="http://www.w3.org/2002/07/owl#" xmlns:prov="http://www.w3.org/ns/prov#" xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:schema="http://schema.org/" xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:time="http://www.w3.org/2006/time#" xmlns:wdt="http://www.wikidata.org/prop/direct/" xmlns:wdtn="http://www.wikidata.org/prop/direct-normalized/" xmlns:xsd="http://www.w3.org/2001/XMLSchema#">
#<?merge subdocs = 0 :split-01.rdf?>
#<?merge subdocs = 0 :split-02.rdf?>
#<?merge subdocs = 0 :split-03.rdf?>
#<?merge subdocs = 0 :split-04.rdf?>
#</rdf:RDF>

## remove older results!
cleansplit:
	rm -f splitted_large_xml*

## for processing **another** large XML file ONLY change the filename - 
## the output(s) will be called: "splitted_large_xml ..." 
## rename these to a convenient name afterwards
split:
	xml_split -s 500M -n 3 -b splitted_large_xml  quickskosified_M-C-D-Y-M-D_PRODUCTION_URI_archive_MORExmlns.rdf ; 
	## will produce splitted_large_xml-000.rdf as META-file.
	## minimal cleanup
	perl -pi -e 's{></rdf:RDF>}{>\n</rdf:RDF>}' splitted_large_xml-000.rdf

# xml_split produces "fragments" whithout xml-header which are to be merged into the "original" 
# by xml_merge. 
standalone:
	## take the merge-config produced by xml_split and make a temporary merge-config for 
	## every "sub-file" found there, and perform xml_merge
	for f in $$(perl -ne 'if (m{:(split.*rdf)\?>}) { print "$$1\n"; }' splitted_large_xml-000.rdf ); do \
		echo "$$f ..."; \
		grep -P "(^>|xml version|rdf:RDF|xmlns:|$$f)" splitted_large_xml-000.rdf > $$f.merge; \
		xml_merge $$f.merge > $$f.FULL.xml; \
	done;

splitfull: cleansplit split standalone


######################################################################################  
################## Date Entities enrichment (adding external links) ##################
######################################################################################
### This is the script to enrich Date Entities by adding more info from Linked Open Data (eg DBpedia and Wikidata)
### See details: https://redmine.acdh.oeaw.ac.at/issues/17474 (The success rate of this script is 50%+ for unknown technical problems for chracter encoding. It would be best to split the complete task into a couple of subtasks in order to avoid repeating them. In particular, DBpedia and Wikdiata can be done step by step) 
### 
### Run the script with options
### 	./run_add_existing.sh (-h) (-d) (-S <SKIP_N>) (-L <LIMIT_M>) <INPUT RDF-FILE>
### 	(example command: ./run_add_existing.sh -d -S 50 -L 5 sample_year.rdf)
### 
### 	OPTIONS:
### 	-S  <SKIP_N>         Skip <SKIP_N> years before starting to process
### 	-L  <LIMIT_M>        Limit processing to a total of <LIMIT_M> years
###     	                 "0" means: there is NO limit
### 	-d                   Debug mode
### 	-h                   Print this message
### 
### The new script generates the following files with the timestamp of their creation:
### 	1. .rdf : generated RDF file
### 	2. .csv log-info provide info about statistics of processing
### 	3. csv.dump : the same info as .csv but in a format similar to .json -> useers can ignore / DELETE
### 	4. log...txt : most detailed logging during processing: it records many of the decisions and is valuable in the case Hannes need to debug. -> Users can ignore / but NOT delete

enrich_year:
	@echo "## Running add_existing_rdf.pl for year ..."
	nohup run_add_existing.sh -d -S 0 -L 0 sample_year.rdf

enrich_month:
	@echo "## Running add_existing_rdf.pl for month ..."
	nohup run_add_existing.sh -d -S 0 -L 0 mon4.rdf

######################################################################################  
################## SKOS validation (adding missing property links)  ##################
######################################################################################
### SKOSMOS requries skos:broader and skos:narrower both directions (parents and children).
### But the data created above do not have all property links, so we have to validate SKOS. 
### For the validation, we need to compile all files (from millennia to days) into one file by using JOIN command (1). 
### Then, we use SKOSFIY to fill all missing links (2).


######################################################################################  
################## SKOS validation (1) JOIN ##########################################
######################################################################################
### joining all .rdf files in enriched_data folder (i.e. enriched_data/*rdf) 
### Input format: -I rdfxml
### Output format: -O rdfxml
### Output file name: enriched_data/joined_M-C-D-Y3.rdf
### Input files: enriched_data/*rdf
join:
	# output rfdfxml
	time join_rdf_files.pl -I rdfxml -O rdfxml -o enriched_data/productionM-C-D-Y-M-D/joined_M-C-D-Y-M-D.rdf enriched_data/productionM-C-D-Y-M-D/*rdf

######################################################################################  
################## SKOS validation (1) JOIN ##########################################
## quickjoin: just concatenate out*rdf 
### Input files: enriched_data/*rd
quickjoin:
	# 1 joined - just without the _last_ line
	head -n -1 enriched_data/productionM-C-D-Y-M-D/joined_M-C-D-Y3_2.rdf > quickjoin_M-C-D-Y-M-D.rdf
	# 2 out ...
	for f in $$(ls enriched_data/productionM-C-D-Y-M-D/out*rdf); do \
		echo "$$f ..."; \
		cat  $$f |  tail -n +3 | head -n -1  >> quickjoin_M-C-D-Y-M-D.rdf; \
	done;
	## 3 sample ...
	for f in $$(ls enriched_data/productionM-C-D-Y-M-D/sample*rdf); do \
		echo "$$f ..."; \
		cat  $$f | tail -n +14 |  head -n -1  >> quickjoin_M-C-D-Y-M-D.rdf; \
	done;
     ## closing element: 
	echo '</rdf:RDF>' >> quickjoin_M-C-D-Y-M-D.rdf;
	wc -l quickjoin_M-C-D-Y-M-D.rdf;



######################################################################################  
################## SKOS validation (2) SKOSIFY #######################################
######################################################################################
### Input format: -f xml
### Output format: -F xml
### Output file name: ./enriched_data/skosified_M-C-D-Y3.rdf
### Input files: ./enriched_data/joined_M-C-D-Y3.rdf
skosifyxml:
	skosify -f xml -F xml -o ./enriched_data/productionM-C-D-Y-M-D/skosified_M-C-D-Y-M-D.rdf ./enriched_data/productionM-C-D-Y-M-D/joined_M-C-D-Y-M-D.rdf 2>&1 | tee skosify_$$(date +%F_%Hh%Mm).log


quickskosify:
	nohup skosify -f xml -F xml -o quickskosified_M-C-D-Y-M-D.rdf quickjoin_M-C-D-Y-M-D.rdf > quickskosify_$$(date +%F_%Hh%Mm).log

## run skosify on ttl input + output
skosifyttl:
	skosify -f turtle -F turtle -o skosified_joined_M-C-D-Y.ttl joined_M-C-D-Y.ttl 2>&1 | tee skosifyttl_$$(date +%F_%Hh%Mm).log

######################################################################################  
########### Date Entities format conversion (XML to TTL) (if needed) #################
######################################################################################
### After rdf/xml is generated, it could be transformed to another format such as turtle (ttl) that would be handier. There are 2 ways to do it.
### 
### 1. Preinstalled Jena/Fuseki riot tool 
### 	See the bottom of https://redmine.acdh.oeaw.ac.at/projects/acdh-oeaw/wiki/Managing_SKOS_vocabularies_with_Skosmos
### 	riot format transformation tool is preinstalled in Jena Fuseki which works with a command line
### 
### 2. rdfpipe (see MakeFile for a shortcut functionality by MakeFile)(very fast! and simple)
### Input format: -i turtle
### Output format: -o xml
### Input files: enriched_data/YearsEnrichedWithLinks_ingest.ttl
### Output file name: enriched_data/YearsEnrichedWithLinks_ingest.rdf
convert:
	@echo -e "\n# Converting rdfxml to ttl using rdfpipe...\n"
	rdfpipe -i turtle -o xml enriched_data/CenturyEnriched_date3_PercentCenturiesExcluded.ttl > enriched_data/CenturyEnriched_date3_PercentCenturiesExcluded.rdf



#### No need (temporally held below) 
## joining mon*rdf into MonAll.rdf 
joinmon:
	# output rfdfxml
	time join_rdf_files.pl -O rdfxml -o MonAll.rdf  mon*rdf


