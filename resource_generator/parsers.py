# coding: utf-8

from common import gzip_to_text
from lxml import etree
import csv
import gzip
import uuid

class Parser(object):
    def __init__(self, file_to_url):
        self.file_to_url = file_to_url

    def parse():
        pass

class EntrezGeneParser(Parser):
    resourceLocation = "http://resource.belframework.org/belframework/1.0/namespace/entrez-gene-ids-hmr.belns"

    def __init__(self, file_to_url):
        super(EntrezGeneParser, self).__init__(file_to_url)
        self.encoding = {"protein-coding" : "GRP", "miscRNA" : "GR", "ncRNA" : "GR", "snoRNA" : "GR",
                        "snRNA" : "GR", "tRNA" : "GR", "scRNA" : "GR", "other" : "G", "pseudo" : "GR",
                        "unknown" : "G", "rRNA" : "GR"}
        file_keys = iter(file_to_url.keys())
        self.gene_history = next(file_keys)
        self.gene_info = next(file_keys)

    def parse(self):
        # parse gene_info to represent the current valid entrez gene ids
        eg_dict = dict([((EntrezGeneParser.resourceLocation, rec[1]), (self.encoding[rec[9]], uuid.uuid4())) \
                        for rec in csv.reader(gzip_to_text(self.gene_info), delimiter="\t", quotechar="\"") if rec[0] in ("9606", "10090", "10116")])

        # parse gene_history to know which gene ids were discontinued
        history_dict = dict([(rec[2], rec[1])
                        for rec in csv.reader(gzip_to_text(self.gene_history), delimiter="\t", quotechar="\"") if rec[0] in ("9606", "10090", "10116")])
        history_dict = {k : self.__walk__(history_dict, k) for k in history_dict}
        return (eg_dict, history_dict)

    def __walk__(self, history_dict, val):
        while val in history_dict:
            val = history_dict[val]
        return None if val == '-' else val

    def __str__(self):
        return "EntrezGene Parser for dataset: %s" %(self.file_to_url)

class HGNCParser(Parser):
    resourceLocation = "http://resource.belframework.org/belframework/1.0/namespace/hgnc-approved-symbols.belns"

    def __init__(self, gene_dict, history_dict, file_to_url):
        super(HGNCParser, self).__init__(file_to_url)
        self.gene_dict = gene_dict
        self.history_dict = history_dict
        self.hgnc_file = next(iter(file_to_url.keys()))
        self.encoding = {"gene with protein product" : "GRP", "RNA, cluster" : "GR", "RNA, long non-coding" : "GR", "RNA, micro" : "GRM", \
                          "RNA, ribosomal" : "GR", "RNA, small cytoplasmic" : "GR", "RNA, small misc" : "GR", "RNA, small nuclear" : "GR", \
                          "RNA, small nucleolar" : "GR", "RNA, transfer" : "GR", "phenotype only" : "G", "RNA, pseudogene" : "GR", \
                          "T cell receptor pseudogene" : "GR", "immunoglobulin pseudogene" : "GR", "pseudogene" : "GR", "T cell receptor gene" : "GRP", \
                          "complex locus constituent" : "GRP", "endogenous retrovirus" : "G", "fragile site" : "G", "immunoglobulin gene" : "G", \
                          "protocadherin" : "G", "readthrough" : "GR", "region" : "G", "transposable element" : "G", "unknown" : "G", \
                          "virus integration site" : "G"}

    def parse(self):
        with open(self.hgnc_file, "r") as hgncf:
            # open csv file
            csvr = csv.reader(hgncf, delimiter="\t", quotechar="\"")

            # parse remainder into HGNC dict, skip header row 0
            hgnc_dict = dict([self.__build_entry__(rec) for rec in csvr if csvr.line_num > 1])
        return hgnc_dict

    def __build_entry__(self, record):
        # build key
        k = (HGNCParser.resourceLocation, record[0])

        # lookup entrez gene uuid if specified, otherwise create new uuid
        if len(record) == 3 and record[2]:
            gene_id = record[2]

            # is it discontinued, if so find replacement
            if gene_id in self.history_dict:
                replacement = self.history_dict[gene_id]
                print("(HGNC) Entrez gene id of %s is discontinued, replacing with %s" %(gene_id, replacement))
                gene_id = replacement

            gene_entry = self.gene_dict[(EntrezGeneParser.resourceLocation, gene_id)]
            v = (self.encoding[record[1]], gene_entry[1])
        else:
            v = (self.encoding[record[1]], uuid.uuid4())
        return (k, v)

    def __str__(self):
        return "HGNC Parser for dataset: %s" %(self.file_to_url)

class MGIParser(Parser):
    resourceLocation = "http://resource.belframework.org/belframework/1.0/namespace/mgi-approved-symbols.belns"

    def __init__(self, gene_dict, history_dict, file_to_url):
        super(MGIParser, self).__init__(file_to_url)
        self.gene_dict = gene_dict
        self.history_dict = history_dict
        file_keys = iter(file_to_url.keys())
        self.mgi_gtpgup = next(file_keys)
        self.mgi_coordinate = next(file_keys)
        self.encoding = {"gene" : "G", "protein coding gene" : "GRP", "non-coding RNA gene" : "GR", "rRNA gene" : "GR", "tRNA gene" : "GR", \
                         "snRNA gene" : "GR", "snoRNA gene" : "GR", "miRNA gene" : "GRM", "scRNA gene" : "GR", "lincRNA gene" : "GR", \
                         "RNase P RNA gene" : "GR", "RNase MRP RNA gene" : "GR", "telomerase RNA gene" : "GR", "unclassified non-coding RNA gene" : "GR", \
                         "heritable phenotypic marker" : "G", "gene segment" : "G", "unclassified gene" : "GR", "other feature types" : "G", \
                         "pseudogene" : "GR", "QTL" : "G", "transgene" : "G", "complex/cluster/region" : None, "cytogenetic marker" : None, \
                         "BAC/YAC end" : None, "other genome feature" : "G"}

    def parse(self):
        with open(self.mgi_coordinate, "r") as mgicf:
            # open mgi coordinate file to find entrez gene equivalence, skip header row 0
            csvr = csv.reader(mgicf, delimiter="\t", quotechar="\"")
            mgi_eg_eq = dict([(rec[2].strip(), self.gene_dict[rec[10]]) for rec in csvr if csvr.line_num > 1 and len(rec) >= 11])

            for symbol, gene_id in mgi_eg_eq.items():
                if gene_id in history_dict:
                    replacement = history_dict[gene_id]
                    print("(MGI) Entrez gene id of %s is discontinued, replacing with %s" %(gene_id, replacement))
                    mgi_eg_eq.update((symbol, replacement))

        with open(self.mgi_gtpgup, "r") as mgigf:
            # parse remainder into HGNC dict, when a symbol exists, and skip header row 0
            mgi_dict = dict([self.__build_entry__(rec) for rec in csv.reader(mgigf, delimiter="\t", quotechar="\"") if rec[8].find(";Name=") != -1])
        return mgi_dict

    def __build_entry__(self, record):
        # pull out dictionary of key/values by tokenizing on ; then =
        # format example: ID=MGI:2448514;Name=R3hdm1;Note=protein coding gene
        entry_data = dict(map(lambda val: val.split("="), record[8].split(";")))

        if "Name" in entry_data:
            symbol = entry_data["Name"]
            if "Note" in data:
                note = entry_data["Note"]
                if note not in self.encoding:
                    ex = KeyError("Gene type ('Note') is not recognized as an encoding.")
                    raise(ex)
                enc = self.encoding[note]
            else:
                ex = ValueError("Symbol specified without an encoding")
                raise(ex)
        k = (MGIParser.resourceLocation, symbol)
        v = (enc, self.gene_dict[(EntrezGeneParser.resourceLocation, mgi_eg_eq[symbol])])
        return (k, v)

    def __str__(self):
        return "MGI Parser for dataset: %s" %(self.file_to_url)

class RGDParser(Parser):
    resourceLocation = "http://resource.belframework.org/belframework/1.0/namespace/rgd-approved-symbols.belns" 

    def __init__(self, gene_dict, history_dict, file_to_url):
        super(RGDParser, self).__init__(file_to_url)
        self.gene_dict = gene_dict
        self.history_dict = history_dict
        self.genes_rat_file = next(iter(file_to_url.keys()))
        self.encoding = {"gene" : "G", "miscrna" : "GR", "predicted-high" : "GRP", "predicted-low" : "GRP", "predicted-moderate" : "GRP",
                         "protein-coding" : "GRP", "pseudo" : "GR", "snrna" : "GR", "trna" : "GR", "rrna" : "GR"}

    def parse(self):
        with open(self.genes_rat_file, "r") as ratf:
            csvr = csv.reader(ratf, delimiter="\t", quotechar="\"")
            rgd_dict = dict([self.__build_entry__(rec) for rec in csvr if csvr.line_num > 60])
        return rgd_dict

    def __build_entry__(self, record):
        k = (RGDParser.resourceLocation, record[1])

        gene_id = record[20]
        if not gene_id:
            gene_id = None
        else:
            if gene_id in self.history_dict:
                replacement = self.history_dict[gene_id]
                gene_id = replacement

        enc = self.encoding[record[36]]
        if gene_id is None:
            v = (enc, uuid.uuid4())
        else:
            gene_entry = self.gene_dict[(EntrezGeneParser.resourceLocation, gene_id)]
            v = (self.encoding[record[36]], gene_entry[1])

        return (k, v)

    def __str__(self):
        return "RGD Parser for dataset: %s" %(self.file_to_url)

class SwissProtParser(Parser):
    resourceLocation_accession_numbers = "http://resource.belframework.org/belframework/1.0/namespace/swissprot-accession-numbers.belns"
    resourceLocation_entry_names = "http://resource.belframework.org/belframework/1.0/namespace/swissprot-entry-names.belns"

    def __init__(self, gene_dict, history_dict, file_to_url):
        super(SwissProtParser, self).__init__(file_to_url)
        self.gene_dict = gene_dict
        self.history_dict = history_dict
        self.sprot_file = next(iter(file_to_url.keys()))
        self.encoding = "GRP"
        self.entries = {}
        self.accession_numbers = {}
        self.gene_ids = {}
        self.entry_names = set({})

    def parse(self):
        sprot_dict = {}
        with gzip.open(self.sprot_file) as sprotf:
            ctx = etree.iterparse(sprotf, events=('end',), tag='{http://uniprot.org/uniprot}entry')
            self.__fast_iter__(ctx, self.__eval_entry__)

            for entry_name in sorted(self.entry_names):
                val = self.entries[entry_name]
                entry_accessions = val[0]
                entry_gene_ids = val[1]

                # one protein to many genes, so we cannot equivalence
                if len(entry_gene_ids) > 1:
                    entry_uuid = uuid.uuid4()
                elif len(entry_gene_ids) == 0:
                    #print("No GeneId for entry name: %s" %(entry_name))
                    entry_uuid = uuid.uuid4()
                else:
                    # one gene exists so find entrez gene uuid
                    gene_id = entry_gene_ids[0]
                    if gene_id in self.history_dict:
                        gene_id = self.history_dict[gene_id]
                    entry_uuid = self.gene_dict[(EntrezGeneParser.resourceLocation, gene_id)]

                # add entry name namespace / equivalence entry
                sprot_dict.update({(SwissProtParser.resourceLocation_entry_names, entry_name) : (self.encoding, entry_uuid)})

                # add entry accession numbers where each one represents only one swiss prot entry
                for entry_accession in entry_accessions:
                    state = self.accession_numbers[entry_accession]
                    if state is None:
                        # accession number is one to many, create separate uuid
                        # not equivalenced with either entry name or entrez gene id
                        sprot_dict.update({(SwissProtParser.resourceLocation_accession_numbers, entry_accession) : (self.encoding, uuid.uuid4())})
                    else:
                        # accession number is unique to this protein entry, so equivalence
                        # to entry name and entrez gene id
                        sprot_dict.update({(SwissProtParser.resourceLocation_accession_numbers, entry_accession) : (self.encoding, entry_uuid)})
            return sprot_dict 

            #print("swiss prot saved items: %d" %(len(self.entries)))
            #print("Number of unique accession numbers: " + str(sum(val == 1 for acc, val in self.accession_numbers.items())))
            #print("Number of duplicate accession numbers: " + str(sum(val == None for acc, val in self.accession_numbers.items())))
            #print("Number of unique gene ids: " + str(sum(val == 1 for gene_id, val in self.gene_ids.items())))
            #print("Number of duplicate gene ids: " + str(sum(val == None for gene_id, val in self.gene_ids.items())))

            #for k, v in self.gene_dict.items():
            #    print("sprot ns/eq: (%s) : (%s)" %(k, v))

    def __eval_entry__(self, e):
        # stop evaluating if this entry is not in the Swiss-Prot dataset
        if e.get("dataset") != "Swiss-Prot":
            return

        # stop evaluating if this entry is not for human, mouse, or rat
        org = e.find("{http://uniprot.org/uniprot}organism")
        if org is not None:
            # restrict by NCBI Taxonomy reference
            dbr = org.find("{http://uniprot.org/uniprot}dbReference")
            if dbr.get("id") not in ("9606", "10090", "10116"):
                return

        # get entry name
        entry_name = e.find("{http://uniprot.org/uniprot}name").text
        self.entry_names.add(entry_name)

        # get all accessions
        entry_accessions = []
        for entry_accession in e.findall("{http://uniprot.org/uniprot}accession"):
            acc = entry_accession.text
            entry_accessions.append(acc)
            if acc in self.accession_numbers:
                self.accession_numbers[acc] = None
            else:
                self.accession_numbers[acc] = 1

        entry_gene_ids = []
        for dbr in e.findall("{http://uniprot.org/uniprot}dbReference"):
            if dbr.get("type") == "GeneId":
                gene_id = dbr.get("id")
                entry_gene_ids.append(gene_id)
                if gene_id in self.gene_ids:
                    self.gene_ids[gene_id] = None
                else:
                    self.gene_ids[gene_id] = 1

        self.entries.update({entry_name : (entry_accessions, entry_gene_ids)})

    def __fast_iter__(self, ctx, fun):
        for ev, e in ctx:
            fun(e)
            e.clear()
            while e.getprevious() is not None:
                del e.getparent()[0]
        del ctx

    def __str__(self):
        return "SwissProt Parser for dataset: %s" %(self.file_to_url)

