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
	--ontology-iri https://raw.githubusercontent.com/sebastianduesing/hcc_assay_tree/refs/heads/master/src/ontology/robot_outputs/assays_from_obi.owl \
	--output $@

### Custom terms for HCC
# 
src/ontology/robot_outputs/hcc_hierarchy.owl: src/ontology/robot_inputs/hcc_hierarchy.tsv
	$(ROBOT) template \
	--template $< \
	--output $@

### Assay tree file
# 
hcc_assays.owl: src/ontology/robot_outputs/assays_from_obi.owl src/ontology/robot_outputs/hcc_hierarchy.owl
	$(ROBOT) merge \
	--input $< \
	--input $(word 2,$^) \
	annotate \
	--ontology-iri https://raw.githubusercontent.com/sebastianduesing/hcc_assay_tree/refs/heads/master/hcc_assays.owl \
	--annotation owl:versionInfo "$(TODAY)" \
	--output $@

### All
# 
.PHONY: all
	all: hcc_assays.owl
