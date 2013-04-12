#!/usr/bin/env python3.3
from collections import OrderedDict
from collections import defaultdict
import urllib.request
import csv
import operator
import sys
import gzip
from string import Template

def bel_term(value,ns,f):
    #create bel term given value, namespace id, and bel function string
    must_quote = ['a','SET']
    if ':' in value or ' ' in value or value in must_quote:
        s = Template('${f}(${ns}:"${value}")')
    else:
        s = Template('${f}(${ns}:${value})')
    value = s.substitute(f=f, ns=ns, value=value)
    return value


# open and save namespace document
gocc_url = 'http://resource.belframework.org/belframework/1.0/namespace/go-cellular-component-accession-numbers.belns'
gocc = urllib.request.urlopen(gocc_url)
belns_file = 'go-cellular-component-accession-numbers.belns'
with open(belns_file,'b+w') as f:
    f.write(gocc.read())

# parse belns document and make list of complexes
complexes = []
with open(belns_file,'r') as ns:
    reader = csv.reader(ns, delimiter='|')
    for row in reader:
    # need to find row after [Values]
        if row:
            if row[0].startswith('GO:'):
                if row[1] == 'C':
                    complexes.append(row[0])
            elif row[0].startswith('Keyword='):
                keyword = row[0].split(sep='=')
                complex_ns = keyword[1]

# download and open human, mouse, and rat gene association files from GO
# write BEL file for each species with genes annotated to each complex term
datasets = [('human','ftp://ftp.geneontology.org/pub/go/gene-associations/gene_association.goa_human.gz', 'HGNC'), 
	('mouse','ftp://ftp.geneontology.org/pub/go/gene-associations/gene_association.mgi.gz', 'MGI'), 
	('rat','ftp://ftp.geneontology.org/pub/go/gene-associations/gene_association.rgd.gz', 'RGD')]

for (species, url, ns) in datasets:  
# open and save file
    go = urllib.request.urlopen(url)
    goa_file_name = url.split('/')[-1]
    with open(goa_file_name, 'b+w') as f:
        f.write(go.read())
# make dictionary genemap with list of proteins for each complex GO term
    gomap = defaultdict(list)
    with gzip.open(goa_file_name, mode = 'rt') as g:
        reader = csv.reader(g, delimiter='\t')
        for row in reader:
            # find records with CC GO terms, that do not have a qualifier 
            if not row[0].startswith('!') and row[3] == '' and row[4] in complexes:
                term = bel_term(row[4],complex_ns,'complex')
                gene = bel_term(row[2],ns,'p')
                gomap[term].append(gene)
    # uniquify and sort list of genes annotated to each complex in gomap
    gomap = {k:set(v) for k, v in gomap.items()}
    gomap = {k:sorted(list(v)) for k, v in gomap.items()} 
    # write files
    output_file = "_".join((species,"complex_genes.bel"))
    with open(output_file, "w") as bel:
        for k, v in gomap.items():
            bel.write(k + ' hasComponents list(' + ",".join(v) + ')')
            bel.write('\n')
    bel.close()

