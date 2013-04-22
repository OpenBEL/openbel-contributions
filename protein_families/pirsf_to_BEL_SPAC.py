#!/usr/bin/env python3.3
from collections import defaultdict
import urllib.request
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

def get_data(url):
    # from url, download and save file
    REQ = urllib.request.urlopen(url)
    file_name = url.split('/')[-1]
    with open(file_name,'b+w') as f:
        f.write(REQ.read())
    return file_name

# parse SwissProt .belns document and make list of values
SP_ids = []
with open(get_data('http://resource.belframework.org/belframework/1.0/namespace/swissprot-accession-numbers.belns'), 'r') as ns:
    for line in iter(ns):
        if line.startswith('[Values]'):
            break
    for line in iter(ns):
        (value, encoding) = line.split('|')
        SP_ids.append(value)
SP_ids = set(SP_ids)

# download PIRSF
pirsf_url = 'ftp://ftp.pir.georgetown.edu/databases/pirsf/pirsfinfo.dat'
pirsf = urllib.request.urlopen(pirsf_url)
pirsf_file_name = pirsf_url.split('/')[-1]
with open(pirsf_file_name, 'b+w') as f:
    f.write(pirsf.read())

# read PIRSFinfo.dat file
pirsf_dict = defaultdict(list)
with open(get_data(pirsf_url), mode = 'rt') as g:
    for line in iter(g):
        if line.startswith('>'):
            line = line.split(None, maxsplit=2)
            pirsf_id = line[0].lstrip('>')
            # collecting status, family name, and parents
            status = line[1].strip('()')
            if len(line) == 3:            
                if '[Parent=' not in line[2]:
                    pirsf_name = line[2].rstrip()
                    parent = 'none'	
                else:
                    value = line[2].split('[Parent=')
                    pirsf_name = value[0].rstrip()
                    parent = value[1].rstrip(']')
            # create PIRSF ID BEL term             
            pirsf_bel = bel_term(pirsf_id,'PIRSF','p')
        else:
            (member_id, member_status, seed_status) = line.split()
            if member_id in SP_ids:
                member_name = bel_term(member_id,'SPAC','p')
                pirsf_dict[pirsf_bel].append(member_name)                         	

# sort list of members annotated to each pirsf_name in pirsf_dict
pirsf_dict = {k:sorted(list(v)) for k, v in pirsf_dict.items()} 
# write file
output_file = 'pirsf_members.bel'
with open(output_file, "w") as bel:
    for k, v in pirsf_dict.items():
        bel.write(k + ' hasMembers list(' + ",".join(v) + ')')
        bel.write('\n')
    bel.close()

