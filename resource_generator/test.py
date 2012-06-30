#!/usr/bin/env python3.2

import cProfile
import csv
import gzip

def gzip_to_text(gzip_file, encoding="ascii"):
    with gzip.open(gzip_file) as gzf:
            for line in gzf:
                yield str(line, encoding)

def verbose(d):
    for dis, rep in d.items():
        if rep == "-":
            d[dis] = None
            continue

        while rep in d:
            rep = d[rep]
            if rep == "-":
                d[dis] = None
                break
        #else:
        d[dis] = rep
    return d

def recursive(d, k):
    v = d[k]
    if v == '-':
        v = d[k] = None
    elif v in d:
        v = d[k] = recursive(d, v)
    return v

def do_recursive(d):
    for k in d:
        recursive(d, k)
    return d

def walk(d, val):
    while val in d:
        val = d[val]
    return None if val == '-' else val

def dict_comprehension(d):
    return {k : walk(d, k) for k in d}

# public dataset pulled from url: ftp://ftp.ncbi.nih.gov/gene/DATA/gene_history.gz
csvr = csv.reader(gzip_to_text("gene_history.gz"), delimiter="\t", quotechar="\"")
d = {rec[2].strip() : rec[1].strip() for rec in csvr if csvr.line_num > 1}
print("Running original procedural solution.")
cProfile.run('d = verbose(d)')
c = 0
for k, v in d.items():
    c += (1 if v is None else 0)
print(c)
print("Running recursive solution.")
cProfile.run('d = do_recursive(d)')
c = 0
for k, v in d.items():
    c += (1 if v is None else 0)
print(c)
print("Running dict comprehension solution.")
cProfile.run('d = dict_comprehension(d)')
c = 0
for k, v in d.items():
    c += (1 if v is None else 0)
print(c)
