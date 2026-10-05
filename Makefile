# HCC Assay Tree Makefile
#
# This Makefile is used to build an ontology artifact for
# the Human Immune Project Consortium's terminology
# browser.
#
### Configuration
#
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:
.SECONDARY:

### Definitions
# 
SHELL := /bin/bash
OBO := http://purl.obolibrary.org/obo
OBI := $(OBO)/OBI_
TODAY := $(shell date +%Y-%m-%d)
TS := $(shell date +'%d:%m:%Y %H:%M')

### Directories
#
build:
	mkdir -p $@

### ROBOT
# 
build/robot.jar: | build
	curl -L -o $@ https://github.com/ontodev/robot/releases/download/v1.9.8/robot.jar

build/robot: build/robot.jar
	curl -L -o $@ https://raw.githubusercontent.com/ontodev/robot/master/bin/robot
	chmod +x $@

ROBOT := java -jar build/robot.jar --prefix 'REO: http://purl.obolibrary.org/obo/REO_'

### Assays from OBI
# 
build/obi.owl: | build
	curl -L -o $@ http://purl.obolibrary.org/obo/obi.owl

src/ontology/robot_outputs/assays_from_obi.owl: build/obi.owl src/ontology/robot_inputs/assays_from_obi.txt | build/robot
	$(ROBOT) extract \
	--method subset \
	--input $< \
	--term-file $(word 2,$^) \
	remove \
	--axioms logical \
	annotate \
	--ontology-iri https://raw.githubusercontent.com/sebastianduesing/hcc_assay_tree/refs/heads/main/src/ontology/robot_outputs/assays_from_obi.owl \
	--output $@

### Merge in new terms for HCC and remove labels of OBI terms to be relabeled
# 
src/ontology/robot_outputs/hcc_hierarchy.owl: src/ontology/robot_outputs/assays_from_obi.owl src/ontology/robot_inputs/hcc_hierarchy.tsv src/ontology/robot_inputs/relabel.txt
	$(ROBOT) template \
	--merge-before \
	--input $< \
	--template $(word 2,$^) \
	remove \
	--term-file $(word 3,$^) \
	--axioms annotation \
	--trim false \
	--preserve-structure false \
	--output $@

### Assay tree file: merge in custom labels for relabeled OBI terms and annotate with IRI
# 
hcc_assays.owl: src/ontology/robot_outputs/hcc_hierarchy.owl src/ontology/robot_inputs/hcc_labels.tsv
	$(ROBOT) template \
	--merge-before \
	--input $< \
	--template $(word 2,$^) \
	annotate \
	--ontology-iri https://raw.githubusercontent.com/sebastianduesing/hcc_assay_tree/refs/heads/main/hcc_assays.owl \
	--annotation owl:versionInfo "$(TODAY)" \
	--output $@

### All
# 
.PHONY: all
	all: hcc_assays.owl
