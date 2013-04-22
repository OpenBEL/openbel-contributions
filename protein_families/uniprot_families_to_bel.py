#!/usr/bin/env python3.3
from collections import defaultdict
import urllib.request
import csv
import operator
import sys
import gzip
from string import Template


def bel_term(value,ns,f):
    # create bel term given value, namespace id, and bel function string
    must_quote = ['a','SET']
    if ':' in value or ' ' in value or '(' in value or value in must_quote:
        s = Template('${f}(${ns}:"${value}")')
    else:
        s = Template('${f}(${ns}:${value})')
    value = s.substitute(f=f, ns=ns, value=value)
    return value

def get_data(url):
    # from url, download and save file
    REQ = urllib.request.urlopen(url)
    file_name = url.split('/')[-1]
    with open(file_name,'b+w') as f:
        f.write(REQ.read())
    return file_name

# parse SwissProt .belns document and make list of values
SP_names = []
with open(get_data('http://resource.belframework.org/belframework/1.0/namespace/swissprot-entry-names.belns'), 'r') as ns:
    for line in iter(ns):
        if line.startswith('[Values]'):
            break
    for line in iter(ns):
        (value, encoding) = line.split('|')
        SP_names.append(value)

# pasre UniProt similar.txt document, assign human, mouse, and rat members present in SwissProt .belns file, and create bel hasMembers statements
uniprot_families = defaultdict(list)
with open(get_data('ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/docs/similar.txt'), 'r') as f:
    for line in iter(f):
        if line == "II. Families\n":
            break
    for line in iter(f):
        if not line.strip():
            continue
        if line.endswith('family\n'):
            family = line.strip()
            family_term = bel_term(family, 'UNIFAM', 'p')
        elif line.startswith('------'):
            break
        else:
            members = line.split(',')
            for member in members:
                if not member.strip():
                    continue
                (SP_name, SP_id) = member.split()
                SP_name = SP_name.strip()
                if SP_name in SP_names:
                    SP_term = bel_term(SP_name, 'SP', 'p')
                    uniprot_families[family_term].append(SP_term)

# write file
output_file = 'uniprot_members.bel'
with open(output_file, "w") as bel:
    for k, v in uniprot_families.items():
        bel.write(k + ' hasMembers list(' + ",".join(v) + ')')
        bel.write('\n')
    bel.close()            
