#!/usr/bin/env python3
#
# build_equivlence.py
#
# inputs: none
# outputs: namespace/equivalence dictionary file

from html.parser import HTMLParser
import pickle
import re
import urllib.request

BELNS_URL='http://resource.belframework.org/belframework/1.0/namespace/'

class NsParser(HTMLParser):
    def __init__(self, baseurl):
        super().__init__()
        self.belns = []
        self.baseurl = baseurl

    def handle_starttag(self, tag, attrs):
        if tag == 'a' and attrs[0][1].endswith('.belns'):
            self.belns.append(self.baseurl + attrs[0][1])

parser = NsParser(BELNS_URL)
with urllib.request.urlopen(BELNS_URL) as nsr:
    ns = str(nsr.read())
    parser.feed(ns)

def tuplify_nsv(belns, value):
    tokens = value.decode('utf-8').strip('\n').split('|')
    return ((belns, tokens[0]), tokens[1])

eq_dict = {}
value_re = re.compile("[\w \-,']+\|.*")
for belns in parser.belns:
    with urllib.request.urlopen(belns) as nsf:
        values = dict([tuplify_nsv(belns, val) for val in nsf.readlines() if value_re.match(str(val))])
        eq_dict.update(values)
        print("loaded %s" %(belns))

print("Equivalence dictionary contains %d namespace values." %(len(eq_dict.keys())))
print("Dumping dictionary")
with open("equivalence.dict", "wb") as df:
    pickle.dump(eq_dict, df)

