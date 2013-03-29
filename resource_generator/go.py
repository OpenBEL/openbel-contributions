#!/usr/bin/env python3
# coding: utf-8

from lxml import etree
import csv
import operator
import sys
import uuid

if len(sys.argv) is not 3:
    sys.stderr.write("usage: go.py [TERMDB_OBO_FILE] [MESH_MAPPING_FILE]\n")
    sys.exit(1)

# open file argument for reading
gofile = open(sys.argv[1])

mg_eq = {}
with open(sys.argv[2]) as meshf:
    mg_eq = dict([(rec[2], rec[3]) for rec in csv.reader(meshf, delimiter=',', quotechar='"')])

# parse xml tree using lxml
parser = etree.XMLParser(ns_clean=True, recover=True, encoding="UTF-8")
root = etree.parse(gofile, parser)

# initialize empty dictionaries using tuple assignment
parents, accession_dict, term_dict = {}, {}, {}

# for each term, find immediate parents, and stuff in 'parents' dictionary
terms = root.xpath("/obo/term [namespace = 'cellular_component' and not(is_obsolete)]")
for t in terms:
    termid = t.find("id").text
    parent_ids = [isa.text for isa in t.findall("is_a")]
    parents[termid] = parent_ids

for t in terms:
    termid = t.find("id").text
    termname = t.find("name").text
    parent_stack = []
    complex = False

    if termid == "GO:0032991":
        complex = True
    elif t.find("is_root") is not None:
        complex = False
    else:
        parent_stack.extend(parents[termid])
        while len(parent_stack) > 0:
            parent_id = parent_stack.pop()

            if parent_id == "GO:0032991":
                complex = True
                break

            if parent_id in parents:
                parent_stack.extend(parents[parent_id])
    
    encoding = "C" if complex else "A"

    if termid in mg_eq:
        go_uuid = mg_eq[termid]
    else:
        go_uuid = uuid.uuid4()

    accession_dict[termid] = (encoding, go_uuid)
    term_dict[termname] = (encoding, go_uuid)

gofile.close()

# write namespaces
with open("go_cellular_component_term.belns", "w") as tns, \
open("go_cellular_component_accession.belns", "w") as ans, \
open("go_cellular_component_term.beleq", "w") as teq, \
open("go_cellular_component_accession.beleq", "w") as aeq:
    for k, v in sorted(accession_dict.items()):
        # unpack tuple
        encoding, uuid = v
        ans.write("%s|%s\n" % (k, encoding))
        aeq.write("%s|%s\n" % (k, uuid))

    for k, v in sorted(term_dict.items(), key=lambda k: (k[0].lower())):
        # unpack tuple
        encoding, uuid = v
        tns.write("%s|%s\n" %(k, encoding))
        teq.write("%s|%s\n" %(k, uuid))

