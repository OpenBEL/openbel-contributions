# coding: utf-8

import os
import parsers

class paths(object):
    def __init__(self, build_dir, dataset_config, dataset_dir, equivalence_dict, equivalence_dir, info, namespace_dir):
        self.__build_dir = build_dir
        self.__dataset_config = dataset_config
        self.__dataset_dir = dataset_dir
        self.__equivalence_dict = equivalence_dict
        self.__equivalence_dir = equivalence_dir
        self.__info = info
        self.__namespace_dir = namespace_dir

    @property
    def build_dir(self):
        return self.__build_dir

    @property
    def dataset_config(self):
        return self.__dataset_config
    
    @property
    def dataset_dir(self):
        return self.__dataset_dir

    @property
    def equivalence_dict(self):
        return self.__equivalence_dict

    @property
    def equivalence_dir(self):
        return self.__equivalence_dir

    @property
    def info(self):
        return self.__info

    @property
    def namespace_dir(self):
        return self.__namespace_dir

class dataset(object):
    def __init__(self, file_to_url, parser_class):
        self.__file_to_url = file_to_url
        self.__parser_class = parser_class

    @property
    def file_to_url(self):
        return self.__file_to_url

    @property
    def parser_class(self):
        return self.__parser_class

path_constants = paths("build", "dataset_config.ini", "datasets", "build/equivalence_dict", "equivalences", "build_info", "namespaces")

gp_reference = dataset({os.path.join(path_constants.dataset_dir, "eg-gene_info.gz") : "ftp://ftp.ncbi.nih.gov/gene/DATA/gene_info.gz", \
                       os.path.join(path_constants.dataset_dir, "eg-gene_history.gz") : "ftp://ftp.ncbi.nih.gov/gene/DATA/gene_history.gz"}, \
                       parsers.EntrezGeneParser)

gp_datasets = []
gp_datasets.append(dataset({os.path.join(path_constants.dataset_dir, "hgnc-hgnc_downloads.tsv") : "http://www.genenames.org/cgi-bin/hgnc_downloads.cgi?title=HGNC+output+data&submit=submit&hgnc_dbtag=on&col=gd_app_sym&col=gd_locus_type&col=md_eg_id&status=Approved&status_opt=2&where=&order_by=gd_app_sym_sort&format=text&limit=&.cgifields=&.cgifields=chr&.cgifields=status&.cgifields=hgnc_dbtag"}, parsers.HGNCParser))
gp_datasets.append(dataset({os.path.join(path_constants.dataset_dir, "mgi-mgi_gtpgup.gff.tsv") : "ftp://ftp.informatics.jax.org/pub/reports/MGI_GTGUP.gff" , os.path.join(path_constants.dataset_dir, "mgi-mgi_coordinate.rpt.tsv") : "ftp://ftp.informatics.jax.org/pub/reports/MGI_Coordinate.rpt"},  parsers.MGIParser))
gp_datasets.append(dataset({os.path.join(path_constants.dataset_dir, "rgd-genes_rat.tsv") : "ftp://rgd.mcw.edu/pub/data_release/GENES_RAT.txt"}, parsers.RGDParser))
gp_datasets.append(dataset({os.path.join(path_constants.dataset_dir, "sprot-uniprot_sprot.xml.gz") : "ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.xml.gz"}, parsers.SwissProtParser))
