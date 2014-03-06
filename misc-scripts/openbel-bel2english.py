#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Python Library to convert BEL Statements to English

Parameters
----------
BEL statement

Returns
-------
English translation of BEL Statement

You can run this script to get an example of what it does.

The library file automatically downloads the GO Equivalence files from Github needed to
convert GO Accession IDs to GO Terms to increase readability of the English translations.
"""

import re
import urllib
import os.path

# Global variable
goterms = {}

abundances = {
    'a': 'abundance of',
    'abundance': 'abundance of',
    'p': 'protein abundance of',
    'proteinAbundance': 'protein abundance of',
    'g': 'gene abundance of',
    'geneAbundance': 'gene abundance of',
    'm': 'microRNA abundance of',
    'microRNAAbundance': 'microRNA abundance of',
    'r': 'RNA abundance of',
    'rnaAbundance': 'RNA abundance of',
}
abundances_insert = '|'.join(abundances.keys())

activities = {
    'bp': 'biological process of',
    'biologicalProcess': 'biological process of',
    'path': 'pathological process of',
    'pathology': 'pathological process of',
    'gtp': 'GTP-bound activity of the',
    'cat': 'catalytic activity of the',
    'chap': 'chaperone activity of the',
    'deg': 'degradation activity of the',
    'kin': 'kinase activity of the',
    'act': 'molecular activity of the',
    'pep': 'peptidase activity of the',
    'phos': 'phosphatase activity of the',
    'ribo': 'ribosylation activity of the',
    'tscript': 'transcriptional activity of the',
    'tport': 'transport activity of the',
    'sec': 'secretion of',
    'surf': 'surface expression of the',
}
activities_insert = '|'.join(activities.keys())

relations = {
    'increases': 'increases the',
    '->': 'increases the',
    'directlyIncreases': 'directly increases the',
    '=>': 'directly increases the',
    'isA': 'is a',
    'decreases': 'decreases the',
#    '-|': 'decreases the',
    'directlyDecreases': 'directly decreases the',
#    '=|': 'directly decreases the',
    'causesNoChange': 'causes no significant change of',
    'negativeCorrelation': 'is negatively correlated with',
    'positiveCorrelation': 'is positively correlated with',
    'orthologous': 'is orthologous to',
    'transcribedTo': 'is transcribed to',
    'translatedTo': 'is translated to',
    'association': 'is associated with',
    'biomarkerFor': 'is a biomarker for',
    'hasMember': 'has member',
    'hasMembers': 'has members',
    'hasComponent': 'has component',
    'hasComponents': 'has components',
    'prognosticBiomarkerFor': 'is a prognostic biomarker for',
    'rateLimitingStepOf': 'is a rate limiting step of',
    'subProcessOf': 'is a subprocess of',
    'actsIn': 'acts in',
    'analagous': 'analagous',
    'hasModification': 'has the modification',
    'hasProduct': 'has the product',
    'hasVariant': 'has the variation',
    'includes': 'includes',
    'reactantIn': 'is a reactant in',
    'translocates': 'translocates',
}
relations_insert = '|'.join(relations.keys())

modifications = {
    'P': 'phosphorylated',
    'A': 'acetylated',
    'F': 'farnesylated',
    'G': 'glycosylated',
    'H': 'hydroxylated',
    'M': 'methylated',
    'R': 'ribosylated',
    'S': 'sumoylated',
    'U': 'ubiquitinated',
}
modifications_insert = '|'.join(modifications.keys())

residues = {
    'A': 'alanine',
    'R': 'arginine',
    'N': 'asparagine',
    'D': 'aspartic acid',
    'C': 'cysteine',
    'E': 'glutamic acid',
    'Q': 'glutamine',
    'G': 'glycine',
    'H': 'histidine',
    'I': 'isoleucine',
    'L': 'leucine',
    'K': 'lysine',
    'M': 'methionine',
    'F': 'phenylalanine',
    'P': 'proline',
    'S': 'serine',
    'T': 'threonine',
    'W': 'tryptophan',
    'Y': 'tyrosine',
    'V': 'valine',
}
residues_insert = '|'.join(residues.keys())


def convert_GOCCACC():
    '''Collect dictionary to convert GO Accession IDs to GO Terms'''

    goterms_fn = 'go-cellular-component-terms.beleq'
    goacc_fn = 'go-cellular-component-accession-numbers.beleq'

    if not os.path.isfile(goterms_fn) or not os.path.isfile(goacc_fn):
        print "Retrieving GO Terms Equivalence file"
        goterms_url = 'https://raw.github.com/OpenBEL/openbel-framework-resources/latest/equivalence/go-cellular-component-terms.beleq'
        urllib.urlretrieve(goterms_url, filename='go-cellular-component-terms.beleq')

        print "Retrieving GO Accession IDs Equivalence file"
        goacc_url = 'https://raw.github.com/OpenBEL/openbel-framework-resources/latest/equivalence/go-cellular-component-accession-numbers.beleq'
        urllib.urlretrieve(goacc_url, filename='go-cellular-component-accession-numbers.beleq')

    accessions = {}
    global goterms

    with open('go-cellular-component-accession-numbers.beleq', 'rb') as cca:
        for line in cca:
            if '[Values]' in line:
                for line in cca:
                    line = line.rstrip()
                    acc, uid = line.split('|')
                    accessions[uid] = acc

    with open('go-cellular-component-terms.beleq', 'rb') as cct:
        for line in cct:
            if '[Values]' in line:
                for line in cct:
                    line = line.rstrip()
                    term, uid = line.split('|')
                    goterms[accessions[uid]] = term


# TODO: Missing BEL constructs
# fus or fusion

def bel2english(bel):
    '''Convert BEL Statement to English'''
    # Uses global var: goterms

    # Setting debug to True will cause the bel statement to be printed at every conversion step
    debug = False

    # Process GOCCACC namespace values - convert to GO Term
    match = re.findall('(GOCCACC:"(GO:\d+)")', bel)
    for group in match:
        bel = bel.replace(group[0], goterms[group[1]])
    if debug:
        print bel

    # Translocation function
    match = re.findall('(tloc\((.*?),(.*?),(.*?)\))', bel)
    for group in match:
        replacestring, this, movefrom, moveto = group
        bel = bel.replace(replacestring, 'translocation of the %s from the %s to the %s' % (this, movefrom, moveto))
    if debug:
        print bel

    # Protein modification
    match = re.findall('(,pmod\(([A-Z]),([A-Z]),(\d+)\))', bel)
    for group in match:
        replacestring, m, r, location = group
        bel = bel.replace(replacestring, ' which is %s at the %s at location %s' % (modifications[m], residues[r], location))

    match = re.findall('(,pmod\(([A-Z]),([A-Z])\))', bel)
    for group in match:
        replacestring, m, r = group
        bel = bel.replace(replacestring, ' which is %s at the %s' % (modifications[m], residues[r]))

    match = re.findall('(,pmod\(([A-Z])\))', bel)
    for group in match:
        replacestring, m = group
        bel = bel.replace(replacestring, ' which is %s' % (modifications[m]))
    if debug:
        print bel

    # Substitutions
    match = re.findall('(,sub\(\s*([A-Z]),\s*(\d+),\s*([A-Z])\))', bel)
    for group in match:
        replacestring, orig, location, new = group
        bel = bel.replace(replacestring, ' which has %s substituted at location %s with %s' % (residues[orig], location, residues[new]))
    if debug:
        print bel

    # Reaction
    bel = bel.replace('rxn', 'reaction of ')

    # Composite
    bel = bel.replace('composite', 'composite of ')

    # Complex
    bel = bel.replace('complex(NCH:', 'complex(')
    bel = bel.replace('),p', ') and p')

    # Match activities
    match = re.findall('((%s)\((.*?)\))' % (activities_insert), bel)
    for group in match:
        bel = replacement(bel, group, activities)
    if debug:
        print bel

    # Match abundances
    match = re.findall('((%s)\(\w+:(.*?)\))' % (abundances_insert), bel)
    for group in match:
        bel = replacement(bel, group, abundances)
    if debug:
        print bel

    # Match relations
    replacestring = re.findall('(%s)' % (relations_insert), bel)[0]
    bel = bel.replace(replacestring, relations[replacestring])
    if debug:
        print bel

    bel = 'The %s.' % bel
    if debug:
        print bel

    return bel


def replacement(bel, group, hash):
    '''Replace strings in BEL statement based on regex matches (group)'''
    if len(group) == 3:
        replacestring, f, entity = group
        function = hash[f]
        new = '%s %s' % (function, entity)
        bel = bel.replace(replacestring, new)

    return bel


# Example BEL Statements for testing
# bel = 'gtp(p(HGNC:RAC1)) increases a(CHEBI:"leukotriene C4")'
# bel = 'bp(GO:"response to endoplasmic reticulum stress") increases tloc(p(HGNC:ATF6),GOCCACC:"GO:0005737",GOCCACC:"GO:0005634")'
# bel = 'kin(p(HGNC:MAPK8)) directlyIncreases p(HGNC:ATF2,pmod(P,T,71))'
# bel = 'p(HGNC:HRAS,sub(G,12,V)) directlyIncreases gtp(p(HGNC:HRAS))'
# bel = 'rxn(reactants(a(CHEBI:"hydrogen peroxide")),products(a(SCHEM:"Hydroxyl radical"))) hasProduct a(SCHEM:"Hydroxyl radical")'
# bel = 'composite(p(HGNC:IFNA), p(HGNC:IL1B)) increases sec(p(HGNC:CXCL10))'
# bel = 'p(HGNC:ZBTB16) decreases surf(p(HGNC:CD14))'
# bel = 'complex(p(HGNC:BACH1),p(HGNC:MAFK)) hasComponent p(HGNC:MAFK)'
# bel = 'cat(complex(p(HGNC:CD8A),p(HGNC:CD8B))) increases cat(complex(NCH:"T Cell Receptor Complex"))'
# bel = 'kin(p(HGNC:PRKCI)) increases tloc(p(HGNC:NFE2L2),GOCCACC:"GO:0005737",GOCCACC:"GO:0005634")'


def main():

    # Collect GO Terms and Accession IDs - populates the global goterms
    convert_GOCCACC()

    # Convert BEL to English
    bel = 'kin(p(HGNC:PRKCI)) increases tloc(p(HGNC:NFE2L2),GOCCACC:"GO:0005737",GOCCACC:"GO:0005634")'
    print 'BEL: ', bel
    print 'English: ', bel2english(bel)


if __name__ == '__main__':
    main()
