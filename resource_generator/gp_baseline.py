#!/usr/bin/env python3
# coding: utf-8
#
# gp_baseline.py
# inputs:
#   -o    old namespace/equivalence dictionary file (built with build_equivalence.py)
#   -n    the directory to store the equivalence data
#   -v    enables verbose mode

from common import download
from configparser import ConfigParser
from configuration import path_constants, gp_reference, gp_datasets
import argparse
import bz2
import errno
import os
import pdb
import pickle
import re
import sys
import tarfile
import bz2

parser = argparse.ArgumentParser(description="Generate namespace and equivalence files for gene/protein datasets.")
parser.add_argument("-o", required=False, nargs=1, metavar="EQUIVALENCE FILE", help="The old namespace equivalence dictionary file.")
parser.add_argument("-n", required=True, nargs=1, metavar="DIRECTORY", help="The directory to store the new namespace equivalence data.")
parser.add_argument("-v", required=False, action="store_true", help="This enables verbose program output.")
args = parser.parse_args()

if args.o is None:
    print("Generating gene/protein baseline.")
    old_equivalence = None
else:
    old_equivalence = args.o[0]

resource_dir = args.n[0]
if not os.path.exists(resource_dir):
    os.mkdir(resource_dir)

# change to resource directory
os.chdir(resource_dir)

# make dataset directory
if not os.path.exists(path_constants.dataset_dir):
    os.mkdir(path_constants.dataset_dir)

# create empty dictionary to hold all ns values and equivalence
gp_dict = {}

# parse reference dataset (entrez gene)
for path, url in gp_reference.file_to_url.items():
    download(url, path)
parser = gp_reference.parser_class(gp_reference.file_to_url)
print("Running " + str(parser))
(gene_dict, history_dict) = parser.parse()
gp_dict.update(gene_dict)

# parse dependent datasets
for d in gp_datasets:
    for path, url in d.file_to_url.items():
        download(url, path)
    parser = d.parser_class(gene_dict, history_dict, d.file_to_url)
    print("Running " + str(parser))
    gp_dict.update(parser.parse())

print("Completed gene protein resource generation.")
print("Number of namespace entries: %d" %(len(gp_dict)))

with open("equivalence.dict", "wb") as df:
    pickle.dump(gp_dict, df)

with tarfile.open("datasets.tar", "w") as datasets:
    for fname in os.listdir(path_constants.dataset_dir):
        datasets.add(fname)

#bz2.compress(datasets)
