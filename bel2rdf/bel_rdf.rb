#  Eric Neumann  copyright 2012
# parse_bel2rdf.rb 
# VERSION 1.05
# USAGE: 'load or requires bel_rdf.rb' 


require 'cgi'
require 'digest'
require 'digest/sha1'

$DEBUG = false
def deputs(str) 
    puts str if $DEBUG
end


###############################################################################################
## Set of Dictionaries and Mappings for BEL <=> RDF
## Should be complete set of all BEL terms and functions
###############################################################################################

$synonyms = {"a" => "abundance", "g" => "geneAbundance", "p" => "proteinAbundance", "r" => "rnaAbundance", "m" => "microRNAAbundance", 
    "complex" => "complexAbundance", "composite" => "compositeAbundance", "kin" => "kinaseActivity", "k" => "kinaseActivity", "txn" => "transcriptionalActivity", "tscript" => "transcriptionalActivity", 
    "composite" => "compositeAbundance", "->" => "->", "-|" => "-|", "=>" => "=>", "=|" => "=|",
    "increases" => "->", "decreases" => "-|", "directlyIncreases" => "=>", "directlyDecreases" => "=|", 
    "tport" => "transportActivity", "gtp" => "gtpBoundActivity",
    "cat" => "catalyticActivity", "pep" => "peptidaseActivity", "phos" => "phosphataseActivity", "bp" => "biologicalProcess", "pos" => "positiveCorrelation", "neg" => "negativeCorrelation",
    "positiveCorrelation" => "positiveCorrelation", "negativeCorrelation" => "negativeCorrelation", "analogous" => "analogousTo", "orthologous" => "orthologousTo",
    "mod" => "modification", "fus" => "fusion", "pmod" => "proteinModification", "sub" => "substitution", "trunc" => "truncation", "chap" => "chaperoneActivity",
    "rxn" => "reaction", "path" => "pathology", "ribo" => "ribosylationActivity", "prognosticBiomarkerFor" => "prognosticBiomarkerFor", "causesNoChange" => "causesNoChange",
    "reactants" => "reactants", "cellSecretion" => "cellSecretion", "tloc" => "translocation"}

$hasSynonym = {}

$unary_relations = ["proteinAbundance", "transcriptionalActivity", "kinaseActivity", "rnaAbundance", "microRNAAbundance", "abundance", "complexAbundance","compositeAbundance", "geneAbundance"]
$unary_rel2rdfpreds = {"proteinAbundance" => ["bel:has_protein_abundance", "bel:ProteinAQC"], "transcriptionalActivity" => ["bel:has_transcription_abundance", "bel:TranscriptionAQC"], 
    "kinaseActivity" => ["bel:has_kinase_activity", "bel:KinaseAQC"], "rnaAbundance" => ["bel:has_mrna_abundance", "bel:MrnaAQC"], "abundance" => ["bel:has_cmpd_abundance", "bel:CmpdAQC"], 
    "complexAbundance" => ["bel:has_complex_abundance", "bel:ComplexAQC"], "compositeAbundance" => ["bel:has_composite_abundance", "bel:CompositeAQC"],
    "geneAbundance" => ["bel:has_gene_abundance", "bel:GeneAQC"], "pathology" => ["bel:has_pathology", "bel:PathologyAQC"],
    "biologicalProcess" => ["bel:has_biological_process_act", "bel:BiologicalProcessAQC"],
    "reactants" => ["bel:has_reactants", "bel:ReactantsAQC"], "products" => ["bel:has_products", "bel:ProductsAQC"],
    "microRNAAbundance" => ["bel:has_micro_rna_abundance", "bel:MicroRNAAQC"]}

$root_causality = "causal_effect"

$binary_relations = ["->", "-|", "=>", "=|", "positiveCorrelation", "negativeCorrelation", "analogousTo", "orthologousTo"]
$binary_rel2rdfpreds = {"->" => ["bel:affects", "bel:is_affected_by", "bel:IndirectIncreaseEffect"], "-|" => ["bel:affects", "bel:is_affected_by", "bel:IndirectDecreaseEffect"], 
    "=>" => ["bel:affects", "bel:is_affected_by", "bel:DirectIncreaseEffect"], "=|" => ["bel:affects", "bel:is_affected_by", "bel:DirectDecreaseEffect"],
    "negativeCorrelation" => ["bel:correlates", "bel:correlates", "bel:NegativeCorrelation"], "positiveCorrelation" => ["bel:correlates", "bel:correlates", "bel:PositiveCorrelation"],
    "analogousTo" => ["bel:has_seq_relation", "bel:has_seq_relation", "bel:Analogy"], "orthologousTo" => ["bel:has_seq_relation", "bel:has_seq_relation", "bel:Orthology"],
    "biomarkerFor" => ["bel:biomarker_for", "bel:has_biomarker", "bel:BiomarkerFor"] , "prognosticBiomarkerFor" => ["bel:biomarker_for", "bel:has_biomarker", "bel:PrognosticBiomarkerFor"] ,
    "causesNoChange" => ["bel:not_causes", "bel:not_caused_by", "bel:NoChangeCaused"], "isA" => ["bel:isa", "bel:generic_to", "bel:SuperClass"],
    "reaction" => ["bel:reactant_for", "bel:product_for", "bel:Reaction", "bel:has_reactant", "bel:has_product"],
    "rateLimitingStepOf" => ["bel:rate_limits", "bel:is_rate_limited_by", "bel:RateLimitingStepOf"],
    "hasComponent" => ["bel:has_component", "bel:is_component_of", "bel:hasComponent"],
    "association" => ["bel:has_association", "bel:has_association", "bel:Association"]}
    
$nary_relations = ["complexAbundance","compositeAbundance"]
$nary_rel2rdfpreds = {"complexAbundance" => ["bel:has_complex_abundance", "bel:ComplexAQC"], 
    "compositeAbundance" => ["bel:has_composite_abundance", "bel:CompositeAQC"],
    "reactants" => ["bel:has_reactants", "bel:ReactantsAQC"], "products" => ["bel:has_products", "bel:ProductsAQC"]}
    
$ternary_relations = ["translocation"]
$ternary_rel2rdfpreds = {"translocation" => ["bel:is_translocated_by", "bel:is_translocation_source_for", "bel:is_translocation_destiny_for", "bel:Translocation",
    "bel:translocates", "bel:from_compartment", "bel:to_compartment"]} 

$modifications = ["modification", "fusion", "proteinModification", "substitution", "truncation"]
$modifications_rel2rdfpreds = {"modification" => ["bel:has_modification", "bel:Modification"], "fusion" => ["bel:has_fusion", "bel:FusionModification"], 
    "proteinModification" => ["bel:has_protein_modification", "bel:ProteinModification"], "substitution" => ["bel:has_substitution", "bel:SubstitutionModification"], 
    "truncation" => ["bel:has_truncation", "bel:TruncationModification"]}
    
$pmod_types = {"H" => "Hydroxylation" , "P" => "Phosphorylation" , "A" => "Acetylation" , "G" => "Glycosylation" , 
    "M" => "Methylation" , "U" => "Ubiquitination" , "R" => "Ribosylation"} 
$mod_contracts = {"modification" => "mod", "fusion" => "fus", "proteinModification" => "pmod", "substitution" => "sub", "truncation" => "trunc"}


$transformations = ["cellSecretion", "cellSurfaceExpression", "degradation", "reaction", "translocation"]
$transformations_rel2rdfpreds = {"cellSecretion" => ["bel:has_cell_secretion", "bel:CellSecretion"], "cellSurfaceExpression" => ["bel:has_cell_surface_expression", "bel:CellSurfaceExpression"],
     "degradation" => ["bel:has_degradation", "bel:Degradation"], "reaction" => ["bel:has_reaction", "bel:Reaction"]}

$activities = ["catalyticActivity", "chaperoneActivity", "gtpBoundActivity", "kinaseActivity", "molecularActivity", "peptidaseActivity", "phosphataseActivity", 
    "ribosylationActivity", "transcriptionalActivity", "transportActivity"]
$activities_rel2rdfpreds = {"catalyticActivity" => ["bel:has_catalytic_activity", "bel:CatalyticActivity"], "chaperoneActivity" => ["bel:has_chaperone_activity", "bel:ChaperoneActivity"],
     "gtpBoundActivity" => ["bel:has_gtpbound_activity", "bel:GtpBoundActivity"], "kinaseActivity" => ["bel:has_kinaseActivity", "bel:KinaseActivity"], 
     "molecularActivity" => ["bel:has_molecular_activity", "bel:MolecularActivity"], "peptidaseActivity" => ["bel:has_peptidase_activity", "bel:PeptidaseActivity"], 
     "phosphataseActivity" => ["bel:has_phosphatase_activity", "bel:PhosphataseActivity"], "ribosylationActivity" => ["bel:has_ribosylation_activity", "bel:RibosylationActivity"], 
     "transcriptionalActivity" => ["bel:has_transcriptional_activity", "bel:TranscriptionalActivity"], "transportActivity" => ["bel:has_transport_activity", "bel:TransportActivity"]}

$processes_rel2rdfpreds = {"biologicalProcess" => ["bel:has_biological_process", "bel:BiologicalProcessAC"] }

 

$namespaces = ["HGNC", "UNI", "ENTREZ", "CHEBI", "PFH", "ns1", "MESHD", "MESHCL"]
$namespacetypes = {"HGNC" => "bel:Gene", "UNI" => "bel:Protein", "PFH" => "bel:HumanProteinFamily", "ENTREZ" => "bel:Gene", "CHEBI" => "bel:Compound", 
    "ns1" => "bel:Node", "MESHD" => "bel:MESH-Disease", "MESHCL" => "bel:MESH-Cell_Location", "GO" => "bel:GO-Process", "MGI" => "bel:MGI-Gene", 
    "NCM" => "bel:NamedMouseComplex", "NCH" => "bel:NamedHumanComplex", "PFM" => "bel:MouseProteinFamily"}

$dynamicNStypes = {} 

$UniqueRelationships = {}

def makeUniqueRelationship(rel_name)
    count = 0
    if $UniqueRelationships[rel_name]
        count = $UniqueRelationships[rel_name]
        count += 1
        $UniqueRelationships[rel_name] = count
    else
        count = 1
        $UniqueRelationships[rel_name] = count
    end
    
    return "#{rel_name}_#{count.to_s}"
end

def initRelations()
    $unary_rel2rdfpreds.merge!($activities_rel2rdfpreds)
    $unary_rel2rdfpreds.merge!($transformations_rel2rdfpreds)
    $unary_rel2rdfpreds.merge!($processes_rel2rdfpreds)

    $unary_relations = $unary_rel2rdfpreds.keys 
    $binary_relations = $binary_rel2rdfpreds.keys 
    $nary_relations = $nary_rel2rdfpreds.keys 
    
    $ternary_relations = $ternary_rel2rdfpreds.keys
    
    $modifications_relations = $modifications_rel2rdfpreds.keys
        
    $synonyms.each {|key, val|
        $hasSynonym[val] = key unless key.eql?(val)
    }
    #puts "$hasSynonym   #{$hasSynonym.inspect}"
end

initRelations()

###############################################################################################
## Context management routines
## Generaties RDF Context nodes linking Settings to Statements
## Should be used for higher reasoning around different or related context
## NOTE: These do not convert back into BEL
###############################################################################################

$BELStatementContext = {}
$SettingContext = false
$CurrentBELContextNode = nil
$BELContextNodes = []
$NumStatementsinContext = 0

def resetContext
    $BELStatementContext = {}
    $SettingContext = false
end

def addContextSetting(setting_node)
    unless $SettingContext
        $CurrentBELContextNode = BELContextNode.new() 
        $BELContextNodes << $CurrentBELContextNode
    end
    
    $CurrentBELContextNode.addSetting(setting_node)
    #$BELStatementContext[key] = value
    $SettingContext = true
    $NumStatementsinContext = 0
end


def addContextStatement(statement_node)
    if not $CurrentBELContextNode
        $CurrentBELContextNode = BELContextNode.new() 
        $BELContextNodes << $CurrentBELContextNode
    end
    $CurrentBELContextNode.addStatement(statement_node)
    $SettingContext = false
    $NumStatementsinContext += 1
end


###############################################################################################
## FixQName routine
###############################################################################################
def fixQName(qname)
    deputs "in fixQName #{qname} "
    newstr = qname.gsub(/\s+/,'_').gsub(/[\(\)\&\@]/,'_').gsub(/\+/,'plus').gsub(/[,\.;\:'`]/,'').gsub(/\//,'-')  # CGI encode CGI.escape("NAD(+)")
    m = /^\d/.match(qname)
    newstr = "n-#{newstr}" if m
    newstr
end

def fixNumName(qname)
    m = /^\d/.match(qname)
    if m
        puts "Should not begin with number: #{qname}" 
        qname = "n-#{qname}"
    end
    qname
end

###############################################################################################
## Complete set of BEL Node classes
###############################################################################################

$BELDocumentSequence = []
$BELDocumentNode = nil
$AnonymousNodeCount = 0

class BELNode ## SET Document 
    attr_accessor :cached_id # used for storing volatile (recently created) nodeIDs when generating RDF
    def has_type
        @type
    end
    
    def generate_bel
       "" 
    end
end


def getAnonymousID 
    anon = $AnonymousNodeCount
    $AnonymousNodeCount += 1
    "_:a#{anon}"
end

class BELDocumentNode < BELNode ## SET Document  
    attr_accessor :values

    def initialize(title=nil, authors=nil, version=nil, copyright=nil, description=nil, opt=nil)  
        @type = "Document"  
        @values = {}
        #puts "------ create BELDocumentNode!!!!!!!!!!!!"
        @values["title"] = title if title
        @values["authors"] = authors if authors  
        @values["version"] = version if version  
        @values["copyright"] = copyright if copyright
        @values["description"] = description if description
    end

    def add_values(params)
        #puts "------ Document @values before #{@values.inspect}"
        #puts "------ Document add hash #{params.inspect}"
        @values = @values.merge(params)
        #puts "------ Document @values #{@values.inspect}"
    end

    def add_keyval(key, val)
        #puts "------ Document @values before #{@values.inspect}"
        @values[key] = val
        #puts "------ Document @values #{@values.inspect}"
        values = @values 
    end
 
    def values=(values)
      @values = values
    end
    
    def values
        @values
    end
    
    def generate_rdf_graph
        anonID = getAnonymousID
        #puts "------ Document generate rdf #{@values.inspect}"
        addTriple(anonID, "rdf:type", ":BELDocumentNode")
        @values.each {|key, val|
            addTriple(anonID, "dc:#{key}", val)                    
        }
        #addTriple(anonID, "dc:title", @values["title"]) if @values["title"]       
        #addTriple(anonID, "dc:authors", @values["authors"]) if @values["authors"]       
        #addTriple(anonID, "dc:version", @values["version"]) if @values["version"]
        #addTriple(anonID, "dc:copyright", @values["copyright"]) if @values["copyright"]
        #addTriple(anonID, "dc:description", @values["description"]) if @values["description"]
        ["", anonID, ""]
    end
  
    def generate_bel  ## SET DOCUMENT Name = "Example BEL Script Document"
        #puts "########## Document generate_bel"
        string = ""
        #keys = %w{ title authors version copyright description}
        #keys.each {|key|
        @values.each {|key, val|
            #val = @values[key]
            key = "Name" if key=="title"
            string << "SET Document #{key.capitalize} = \"#{val}\"\n" 
        }
        return string
    end
    
end

class BELSpeciesNode < BELNode ## SET Species = "9606"  
    def initialize(species, opt=nil)  
        @type = "Species"  
        @species = species  
    end

    def generate_rdf_graph
        anonID = getAnonymousID
        addTriple(anonID, "rdf:type", ":BELSpeciesNode")
        addTriple(anonID, ":species", @species)   
        ["", anonID, ""]
    end
    
    def generate_bel  ## SET Species = "9606"
        return "SET Species = \"#{@species}\""
    end
    
end

class BELTissueNode < BELNode ## SET Tissue  
    def initialize(tissue, opt=nil)  
        @type = "Tissue"  
        @tissue = tissue  
    end

    def generate_rdf_graph
        anonID = getAnonymousID
        addTriple(anonID, "rdf:type", ":BELTissueNode")
        addTriple(anonID, ":tissue", @tissue) 
        ["", anonID, ""]
    end

    def generate_bel  ## SET Tissue = "t-cells"
        return "SET Tissue = \"#{@tissue}\""
    end

end

class BELCellLineNode < BELNode ## SET CellLine = "U237"  
    def initialize(cellline, opt=nil)  
        @type = "CellLine"  
        @cellline = cellline  
    end

    def generate_rdf_graph
        anonID = getAnonymousID
        addTriple(anonID, "rdf:type", ":BELCellLineNode")
        addTriple(anonID, ":cellline", @cellline) 
        ["", anonID, ""]
    end

    def generate_bel  ## SET CellLine = "U237"  
        return "SET CellLine = \"#{@cellline}\""
    end

end

class BELCitationNode < BELNode ## SET Tissue  
    def initialize(source, citation, id, opt=nil)  
        @type = "Citation"  
        @source = source  
        @citation = citation  
        @id = id  
    end

    def generate_rdf_graph
        anonID = getAnonymousID
        addTriple(anonID, "rdf:type", ":BELCitationNode")
        addTriple(anonID, ":source", @source)        
        addTriple(anonID, ":citation", @citation)        
        addTriple(anonID, ":id", @id)   
        ["", anonID, ""]
    end

    def generate_bel  ## SET Citation = {"PubMed", "Exp Clin Immunogenet, 2001;18(2) 80-5","11340296"}
        return "SET Citation = {\"#{@source}\", \"#{@citation}\", \"#{@id}\"}"
    end

end



class BELEvidenceNode < BELNode ## SET Evidence  
    def initialize(evidence, opt=nil)  
        @type = "Evidence"  
        @evidence = evidence  
       # @exposure_time = nil
    end

    def generate_rdf_graph
        anonID = getAnonymousID
        addTriple(anonID, "rdf:type", ":BELEvidenceNode")
        addTriple(anonID, ":evidence", @evidence)
        #addTriple(anonID, ":exposure_time", @exposure_time)
        ["", anonID, ""]
    end

    def generate_bel  ## SET Evidence = "..."
        return "SET Evidence = \"#{@evidence}\""
    end
    
end

class BELExposureTimeNode < BELNode ## SET ExposureTime  
    def initialize(exposure_time, opt=nil)  
        @type = "ExposureTime"  
        @exposure_time = exposure_time  
    end

    def generate_rdf_graph
        anonID = getAnonymousID
        addTriple(anonID, "rdf:type", ":BELExposureTimeNode")
        addTriple(anonID, ":exposure_time", @exposure_time)
        ["", anonID, ""]
    end

    def generate_bel  ## SET ExposureTime = "..."
        return "SET ExposureTime = \"#{@exposure_time}\""
    end
    
end


class BELContextNode < BELNode ## CONTEXT   
    def initialize(line=nil)  
        @type = "Context"  
        @line = line  
        @setting_nodes = []
        @statement_nodes = []
    end
    
    def addSetting(setting_node)
        @setting_nodes << setting_node
    end

    def addStatement(statement_node)
        @statement_nodes << statement_node
    end
    
    def generate_rdf_graph
        anonID = getAnonymousID
        addTriple(anonID, "rdf:type", ":BELContextNode")
        
        @setting_nodes.each {|setting_node|
            addTriple(anonID, "bel:has_setting", setting_node.cached_id)
        }

        @statement_nodes.each {|statement_node|
            addTriple(anonID, "bel:has_statement", statement_node.cached_id)
            addTriple(statement_node.cached_id, "bel:in_context", anonID)
        }
        ["", anonID, ""]
    end

    def generate_bel  ## None
        ""
    end
    
end



class BELAnnotationNode < BELNode ## DEFINE ANNOTATION Tissue AS LIST {"t-cells"}
    def initialize(annot, deftype, definition, opt=nil) 
        @type = "ANNOTATION"  
        @annot = annot 
        @deftype = deftype 
        definition.gsub!(/"/, '')
        @definition = definition.strip
    end
         
    def generate_rdf_graph
        anonID = getAnonymousID
        addTriple(anonID, "rdf:type", ":BELAnnotationNode")
        addTriple(anonID, ":annotation_for", @annot)
        addTriple(anonID, ":format", @deftype)
        addTriple(anonID, ":definition", @definition)
        ["", anonID, ""]
    end
    
    def generate_bel  ## DEFINE ANNOTATION Tissue AS LIST {"t-cells"}
        "DEFINE ANNOTATION #{@annot} AS #{@deftype} \"#{@definition}\""
    end
end

class BELNameSpaceNode < BELNode ## DEFINE Namespace NS AS URL "http://resource.belframework.org/belframework/1.0/namespace/hgnc-approved-symbols.belns"
    def initialize(namespace, url, default=nil) 
        @type = "NAMESPACE"  
        @namespace = namespace 
        @url = url 
        @default = nil
        @default = "true" if default && !default.empty?
    end

    def generate_rdf_graph
        anonID = getAnonymousID
        addTriple(anonID, "rdf:type", ":BELNameSpaceNode")
        addTriple(anonID, ":namespace", @namespace)
        addTriple(anonID, ":url", @url)
        addTriple(anonID, ":default", @default) if @default
        ["", anonID, ""]
    end
    
    def generate_bel  ## DEFINE Namespace NS AS URL "http://....."
        def_str = ""
        def_str = "DEFAULT " if @default
        "DEFINE #{def_str}Namespace #{@namespace} AS URL \"#{@url}\""
    end
    
end

class BELCommentNode < BELNode ##    
    def initialize(comment)  
        deputs " BELCommentNode init #{comment}"
        @comment = comment.gsub(/\"/,'\"')  
    end
    
    def generate_rdf_graph
        anonID = getAnonymousID
        addTriple(anonID, "rdf:type", ":BELCommentNode")
        addTriple(anonID, "rdfs:comment", @comment)
        ["", anonID, ""]
    end

    def generate_bel  ## '#'
        "#{@comment}"
    end
    
end


class BELOpNode < BELNode
    def type
        @type
    end

    def is_terminal?

    end

    def has_modifications?

    end

    def is_modification?

    end

    def degree

    end
    
    def generate_rdf_graph
       nil 
    end
    
    def generate_bel  ## 
        ""
    end    
end

###############################################################################################
##  Parsing routine for lists of Modifications
##  <protname> [ <modification>, <res>,[<pos>],[<change>]) , ... ]
###############################################################################################
def parse_modlist(protname, mods)
    mod_array = []
    deputs ".... parse_modlist for #{protname} mods: #{mods.inspect}"
    mods.each {|mod|
        deputs " +++ parse_modlist #{mod.inspect}"
        modifier = mod[0]
        mod_args = mod[1..-1].flatten
        mod_args = mod_args.map {|arg|  ## get rid of any NS's in the modification args
            arg.gsub(/\w+:/,"")
        }
        
        ## modifier_syn = $synonyms[modifier]
        modifier_syn = normalizeTerm(modifier)
        deputs "-- no modification synonym or entry found for #{mod}" unless modifier_syn || $synonyms.has_value?(modifier)
        modifier_syn = modifier unless modifier_syn
        deputs " +++ modifier #{modifier} , mod_args #{mod_args.inspect}"
        mod_args_term = mod_args.join('_')
        
        mod_array << BELUnaryOpNode.new(modifier_syn, protname + "_" + mod_args_term, mod_args)   # modifier_syn+'_'+ mod_args
    }
    #puts "... created mods #{mod_array.inspect}"
    mod_array
end

=begin
###############################################################################################
##  Parsing routine for lists of Modifications
##  <protname> [ <modification>(<res>,[<pos>],[<change>]) , ... ]
###############################################################################################
def parse_modlist_old(protname, mods)
    mod_array = []
    deputs ".... parse_modlist for #{protname} mods: #{mods.inspect}"
    mods.each {|mod|
        mod.strip
        deputs " +++ parse_modlist #{mod.inspect}"
        ##match1 = mod.scan(/,\s*(\w+)\(([^()]+)\)$/)    
        match1 = mod.scan(/(\w+)\(([^()]+)\)/)
        if match1    
            deputs " +++ match1 #{match1.inspect}"
            match1 = match1.flatten
            modifier = match1[0]
            mod_args = match1[1]
        else
            deputs " +++ no match for parse_modlist #{mod.inspect}"
        end
        
        ## modifier_syn = $synonyms[modifier]
        modifier_syn = normalizeTerm(modifier)
        deputs "-- no modification synonym or entry found for #{mod}" unless modifier_syn || $synonyms.has_value?(modifier)
        modifier_syn = modifier unless modifier_syn
        deputs " +++ modifier #{modifier} , mod_args #{mod_args}"
        mod_args_term = mod_args.gsub(/,\s*/, '_')
        
        mod_array << BELUnaryOpNode.new(modifier_syn, protname + "_" + mod_args_term, mod_args)   # modifier_syn+'_'+ mod_args
    }
    #puts "... created mods #{mod_array.inspect}"
    mod_array
end
=end

## BELUnaryOpNode.new("proteinAbundance", "HGNC:PARP1", "pmod(R)")
## BELUnaryOpNode.new("complexAbundance", "HGNC:PARP1", "HGNC:XRCC5")
class BELUnaryOpNode < BELOpNode
  def initialize(type, child, optionals=nil)  
    # Instance variables  
    @type = type  
    @nary = false
    @child = child  
    @members = []
    @modifications = []
    @pmod_type = []
    @mod_arg = []       ## ... is now an array of args!!

    mod_preds = $modifications_rel2rdfpreds[type]
    if mod_preds
        deputs " --- found modification #{type} with #{optionals.inspect} for @child #{@child}"
        if @type.eql?("proteinModification")
            #mm = /^\w+:[^_]+_([A-Z])/.match(@child)
            pmod_type = optionals[0]
            deputs "proteinModification = #{@child} - #{pmod_type}" 
            @pmod_type << $pmod_types[pmod_type]
            deputs "@pmod_type = #{@pmod_type}" 
            
            throw Exception.new unless @pmod_type
        end
        #mm = /^\w+:\w+_[A-Z]_(.+)$/.match(@child)
        
        @mod_arg = optionals   #   ["P" , "S" , "24" ; "R" ;] 
        return  ## nothing more needed to init! 
    end

    #if (@type.eql?("complexAbundance") || @type.eql?("compositeAbundance"))
    if (isNary_Op(@type))
        deputs " ******** Found N-ary complex or composite"
        deputs "-- this: #{@child} should not be a string!!" if @child.instance_of?(String)
            
        @members = [@child]  ## do this as a default even if no other children
        @nary = true
    end
    deputs ".... BELUnaryOpNode init  type #{@type} with child #{@child.inspect} #{'terminal' if is_terminal?} #{'and members' + @members.inspect if @members.any?} with opt #{optionals.inspect}"
    
    if optionals && optionals.any?
        if @nary   ## option is array of children nodes, NOT strings!!
            ##@members = [@child]
            @members = @members + optionals
            deputs "^^^^^^^^^^^^^^^^^^ parsed & initialized multiple members #{@members.inspect}"
            @members.each {|mem|

                if mem.class.eql?(Array)
                    deputs "++++++++++++  PROB"
                    throw Exception.new
                end
                
            }
        else  ## should test for modifcation option here...
            deputs ".... parse_modlist in Unary node for class:#{optionals.class} #{optionals.inspect}"
            @modifications = parse_modlist(@child.to_s, optionals)
            deputs "... parsed & initialized modifications #{@modifications.inspect}"
        end
    end
  end  
  
  def to_s  
    "#{@type}(#{@child.to_s})"  
  end  
  
  def is_terminal?
      @child.instance_of?(String) or @child.instance_of?(Array)
  end

  def has_members?
      @members.instance_of?(Array) && @members.any?
  end
  

  def has_modifications?
      @modifications.instance_of?(Array) && @modifications.any?
  end

  def is_modification?
      #puts "===== is_modification? #{@type}"
      $modifications.member?(@type) ## && @child.instance_of?(Array)
  end
  
  def degree
    return 1
  end
  
  def mod_args
      @mod_arg
  end
    
  def generate_rdf_graph
      n3_graph = nil
      ns = nil
      deputs "----- Unary generate_rdf_graph for #{@child} of type #{@type}"
      
      mod_concat = ""
      deputs "----- Unary generate_rdf_graph @modifications #{@modifications.inspect}" if @modifications && @modifications.any?
      #throw Exception.new if @modifications && @modifications.any?
      @modifications.map {|mod|
          short_type = $mod_contracts[mod.type]
          short_type = mod.type unless short_type
          mod_concat << "_#{short_type}_#{mod.mod_args.join('_')}"
      } if @modifications
      mod_concat = mod_concat.gsub(/,/,'').gsub(/\s+/,'_')
      deputs " mod_concat #{mod_concat}" unless mod_concat.empty?
      
      if is_terminal?
          # create URI node
          primary_node = nil # This will represent the deepest "molecular" node
          secondary_node = nil # This will represent the next "operator" node
          qname = nil
          # unary, with possible modifier  e.g., p(HGNC:AKT1, pmod(P, S, 21))
          newChildname = fixNumName(@child)
          match1 = /^(\w+?):([\w-]+).*/.match(newChildname)
          if match1
              ns_ind = $namespaces.index(match1[1])
              unless ns_ind
                  ns = match1[1] if $dynamicNStypes[match1[1]]
              else
                  ns = $namespaces[ns_ind]
              end
              deputs ".... NS match #{match1[1]} with #{newChildname} #{match1[2]}"
              qname = match1[2] + mod_concat
              # ns_dict_lookup
              primary_node = newChildname
          else
              primary_node = "ns1:" + newChildname  # "def:" + @child  # previously ns2
              qname = newChildname + mod_concat
          end
          deputs "... building(1) qname #{qname} from @child #{newChildname} in @type #{@type}"
          #secondary_node = "#{ns}:#{qname}_#{@type}"
          secondary_node = "ns1:#{qname}_#{@type}"  # use local ns here for terminal nodes
          
          rdfpred = $unary_rel2rdfpreds[@type]
          
          unless rdfpred
              term = normalizeTerm(@type)
              term ||= @type
              rdfpred = $modifications_rel2rdfpreds[term] 
              deputs "... generate_rdf_graph type #{term} rdfpred #{rdfpred.inspect}"
          end

          
          n3_graph = ["#{primary_node} #{rdfpred[0]} #{secondary_node} . #{secondary_node} a #{rdfpred[1]} .\n", "#{secondary_node}", "#{qname}"]
          
          rdfpred[1] = "bel:Thing" if rdfpred[1].nil? || rdfpred[1].empty?
          addTriple(secondary_node, "a", rdfpred[1])
          
          # Handle modifcation terminal nodes here!!! No need for inner protein or gene nodes
          if is_modification?  ## bad flow logic, but jump out here if inside a modification node!
              deputs "**** This is the Modification! #{secondary_node}"
              label = secondary_node.gsub(/^[a-zA-Z0-9]+:/,'').gsub(/_/,' ')
              addTriple(secondary_node, "rdfs:label", label) 
              @pmod_type.each {|mod_type|
                  addTriple(secondary_node, "bel:pmod_type", mod_type) 
              }
              addTriple(secondary_node, "bel:mod_arg", @mod_arg.join(',')) if @mod_arg && !@mod_arg.empty?
              return n3_graph 
          end
          deputs "****** Term Unary generate_rdf_graph for #{secondary_node} of type #{rdfpred[1]} with next node #{primary_node}"
          

          addTriple(primary_node, rdfpred[0], secondary_node)
          
          ############## need better typing here!!!!!
          primary_type = $namespacetypes[ns]
          deputs "primary_type for terminal is #{primary_type} for #{ns}"
          primary_type = "bel:Thing" if primary_type.nil? || primary_type.empty?
          addTriple(primary_node, "a", primary_type) 
          label = primary_node.gsub(/^[a-zA-Z0-9]+:/,'').gsub(/_/,' ')
          addTriple(primary_node, "rdfs:label", label) 
                    
          # create inverse relations
          inv_pred = rdfpred[0].gsub(/has/,"child_for")
          addTriple(secondary_node, inv_pred, primary_node)
          addTriple(secondary_node, "bel:has_child", primary_node)  ## transitive but added explicitly here
          label = secondary_node.gsub(/^[a-zA-Z0-9]+:/,'').gsub(/_/,' ')
          addTriple(secondary_node, "rdfs:label", label)
         
      elsif @nary && has_members? 
          deputs "********** Nary generate_rdf_graph for members #{@members.inspect}"
          
          graphs = []
          # Generate RDF graphs for nary members...
          @members.each {|childnode|
              deputs " -----   @members #{childnode}  #{childnode.class}"
              graphs << childnode.generate_rdf_graph
          }
          
          # Generate compositeName incl nary member names...
          compositeName = ""
          graphs.each {|rdf_graph|
              #primary_node = rdf_graph[1]
              qname = rdf_graph[2]
              if compositeName.empty?
                  compositeName = fixNumName(qname) 
              else
                  
                  compositeName += "_#{fixNumName(qname)}" 
              end
          }
          ns = "ns1"
          secondary_nodename = "#{ns}:#{compositeName}_#{@type}"
          deputs "****** Nary generate_rdf_graph for #{secondary_nodename}"

          # Generate trimples from nary members...
          graphs.each {|rdf_graph|
              primary_node = rdf_graph[1]

              #puts "... building(#) qname #{qname}"

              rdfpred = $unary_rel2rdfpreds[@type]
              n3_graph = ["#{primary_node} #{rdfpred[0]} #{secondary_nodename} . #{secondary_nodename} a #{rdfpred[1]} .\n", "#{secondary_nodename}", "#{compositeName}"]
              addTriple(primary_node, rdfpred[0], secondary_nodename)
              rdfpred[1] = "bel:Thing" if rdfpred[1].nil? || rdfpred[1].empty?
              addTriple(secondary_nodename, "a", rdfpred[1])

              label = secondary_nodename.gsub(/^[a-zA-Z0-9]+:/,'').gsub(/_/,' ')
              addTriple(secondary_nodename, "rdfs:label", label)

              # create inverse relations
              inv_pred = rdfpred[0].gsub(/has/,"child_for")
              addTriple(secondary_nodename, inv_pred, primary_node)
              addTriple(secondary_nodename, "bel:has_child", primary_node)  ## transitive but added explicitly here
          }
          
      else # If not terminal node, recurse down....
          rdf_graph = @child.generate_rdf_graph
          primary_node = rdf_graph[1]
          
          match2 = /^(.+):(.+)/.match(primary_node)
          #ns_ind = $namespaces.index(match2[1])
          #ns = $namespaces[ns_ind]
          
          qname = rdf_graph[2]
          qname = fixNumName(qname)
          deputs "... building(2) qname #{qname}"
          ns = "ns1"
          secondary_node = "#{ns}:#{qname}_#{@type}"
          rdfpred = $unary_rel2rdfpreds[@type]
          
          n3_graph = ["#{primary_node} #{rdfpred[0]} #{secondary_node} . #{secondary_node} a #{rdfpred[1]} .\n", "#{secondary_node}", "#{qname}"]
          addTriple(primary_node, rdfpred[0], secondary_node)
          rdfpred[1] = "bel:Thing" if rdfpred[1].nil? || rdfpred[1].empty?
          addTriple(secondary_node, "a", rdfpred[1])
          
          label = secondary_node.gsub(/^[a-zA-Z0-9]+:/,'').gsub(/_/,' ')
          addTriple(secondary_node, "rdfs:label", label)
          deputs "****** Unary generate_rdf_graph for #{secondary_node} of type #{rdfpred[1]}"

          # create inverse relations
          inv_pred = rdfpred[0].gsub(/has/,"child_for")
          addTriple(secondary_node, inv_pred, primary_node)
          addTriple(secondary_node, "bel:has_child", primary_node)  ## transitive but added explicitly here
      end
      
      @modifications.each {|mod|
          mod_node = mod.generate_rdf_graph
          mod_node = mod_node[1]
          n3_graph = ["#{secondary_node} bel:has_modification #{mod_node} . #{mod_node} a #{rdfpred[1]} .\n", "#{secondary_node}", "#{qname}"]
#          addTriple(primary_node, "bel:has_modification", mod_node)
          addTriple(secondary_node, "bel:has_modification", mod_node)  ## DO NOT LINK MODICATION WITH CHILD GENE NODE!!!!
          addTriple(mod_node, "bel:child_for_modification", secondary_node)  ## This should probably be removed...
          addTriple(mod_node, "a", "bel:Modification")
      } if @modifications
  
      deputs "****** Finished Unary generate_rdf_graph for #{secondary_node} using qname #{qname}"
      
      n3_graph
  end

  def generate_bel  ## 
      #puts "*********** generate_bel for #{@child} type #{@type}"
      #puts "*********** generate_bel with modifications" if has_modifications?
      
      if is_modification?
          return "#{@type}(#{@mod_arg.join(',')})"
      end
          
      composite_array = []
      @members.each { |childnode|
            #puts " -----   @members #{childnode}  #{childnode.class}"
            composite_array << childnode.generate_bel 
        } unless is_terminal?  # named complex, no components listed!!
        
        compositeStr = composite_array.join(' , ')

        modification_array = []
        modificationStr = ""
        #puts "---- @modifications #{@modifications.inspect}" if @modifications
        @modifications.each {|mod|
            modification_array << mod.generate_bel
        } if @modifications
        modificationStr = ", " + modification_array.join(' , ') if has_modifications?
        
      if @child.instance_of?(String)
          return "#{@type}(#{@child}#{modificationStr})" if @child 
      elsif has_members?
          return "#{@type}(#{compositeStr})"
      else
          #puts "Unary generate_bel for #{@child} of type #{@type}"
          return "#{@type}(#{@child.generate_bel}#{modificationStr})"
      end
      
  end
  
end  

class BELBinaryOpNode < BELOpNode
    def initialize(type, child1, child2, option=nil)  
      # Instance variables  
      @type = type  
      @child1 = child1  
      @child2 = child2  
      deputs ".... BELBinaryOpNode init c1=#{@child1} ,c2=#{child2}  type #{@type} with opt #{option}"
    end  

    def to_s  
        "#{@child1.to_s} #{@type} #{@child2.to_s}"  
    end
    
    def degree
      return 2
    end
    
    def generate_rdf_graph
        n3_graph = nil
        ns = "ns1"
        #puts ".... this node #{self.inspect}"
        deputs "---- Binary generate_rdf_graph for #{self.inspect} for @child1 #{@child1.inspect} @child2 #{@child2.inspect}"
        left_n3graph = @child1.generate_rdf_graph
        right_n3graph = @child2.generate_rdf_graph

        left_primary_node = left_n3graph[1]
        right_primary_node = right_n3graph[1]

        left_qname = left_n3graph[2]
        right_qname = right_n3graph[2]
        #puts "... left_primary_node: #{left_primary_node} right_primary_node: #{right_primary_node} left_qname: #{left_qname} right_qname: #{right_qname}" 
        
        match1 = /^(.+?):(\w+?)/.match(left_primary_node)
        deputs "... left_primary_node #{left_primary_node}" unless match1
        left_ns_ind = $namespaces.index(match1[1])
        deputs "... Really #{left_primary_node}  ns: #{match1[1]}" 
        left_ns = $namespaces[left_ns_ind] 

        match2 = /^(.+):(.+)/.match(right_primary_node)
        right_ns_ind = $namespaces.index(match1[1])
        right_ns = $namespaces[right_ns_ind]
        
        rdfpred = $binary_rel2rdfpreds[@type]
        match1 = /^.+:(.+)/.match(rdfpred[2])
        #puts "match1 #{match1[1]}"
        iteraction_qname = match1[1]
        #qname = "#{left_qname}_to_#{right_qname}_#{iteraction_qname}"
        qname = "#{left_primary_node.gsub(/^[a-zA-Z0-9]+:/,'')}_to_#{right_primary_node.gsub(/^[a-zA-Z0-9]+:/,'')}_#{iteraction_qname}"
        
        # make unique indexed name for statement uniqueness
        qname = makeUniqueRelationship(qname) 
        
        secondary_node = "#{ns}:#{qname}"

        n3_graph = ["#{left_primary_node} #{rdfpred[0]} #{secondary_node} . #{right_primary_node} #{rdfpred[1]} #{secondary_node} .#{secondary_node} a #{rdfpred[2]} .\n", "#{secondary_node}", "#{qname}"]
        addTriple(left_primary_node, rdfpred[0], secondary_node)
        addTriple(right_primary_node, rdfpred[1], secondary_node)
        rdfpred[2] = "bel:Thing" if rdfpred[2].nil? || rdfpred[2].empty?
        addTriple(secondary_node, "a", rdfpred[2])

        label = secondary_node.gsub(/^[a-zA-Z0-9]+:/,'').gsub(/_/,' ')
        addTriple(secondary_node, "rdfs:label", label)

        # create inverse relations
        inv_pred1 = rdfpred[0].gsub(/bel:/,'bel:rel_')
        inv_pred0 = rdfpred[1].gsub(/bel:/,'bel:rel_')
        addTriple(secondary_node, inv_pred0, left_primary_node )
        addTriple(secondary_node, inv_pred1, right_primary_node)

        n3_graph
    end

    def generate_bel  ## 
#        "#{@type}(#{@child1.generate_bel} , #{@child2.generate_bel})"
        rhs = @child2.generate_bel
        if isBinary_Op(@child2.type)
            rhs = "(#{rhs})"
        end
            
        "#{@child1.generate_bel} #{@type} #{rhs}"
    end
    
end  


def create_primaryname_and_qname(childName, mod_concat="")
    primary_node = nil # This will represent the deepest "molecular" node
    secondary_node = nil # This will represent the next "operator" node
    qname = nil
    ns = nil
    # unary, with possible modifier  e.g., p(HGNC:AKT1, pmod(P, S, 21))
    newChildname = fixNumName(childName)
    match1 = /^(\w+?):([\w-]+).*/.match(newChildname)
    if match1
        ns_ind = $namespaces.index(match1[1])
        unless ns_ind
            ns = match1[1] if $dynamicNStypes[match1[1]]
        else
            ns = $namespaces[ns_ind]
        end
        deputs ".... NS match #{match1[1]} with #{newChildname} #{match1[2]}"
        qname = match1[2] + mod_concat
        # ns_dict_lookup
        primary_node = newChildname
    else
        primary_node = "ns1:" + newChildname  # "def:" + @child  # previously ns2
        qname = newChildname + mod_concat
    end
    [primary_node , qname, ns]    
end

class BELTernaryOpNode < BELOpNode
  def initialize(type, child1, child2, child3, option=nil)
      # Instance variables  
      @type = type  
      @child1 = child1  
      @child2 = child2  
      @child3 = child3  
      deputs ".... BELBinaryOpNode init c1=#{@child1} ,c2=#{child2} ,c3=#{child3} type #{@type} with opt #{option}"
      
  end
  
  def to_s  
      "#{@child1.to_s} #{@type} #{@child2.to_s} , #{@child3.to_s}"  
  end
  
  def degree
    return 3
  end
  
  def generate_rdf_graph
      n3_graph = nil
      ns = "ns1"
      primary_node = nil
      secondary_node = nil
      #puts ".... this node #{self.inspect}"
      puts "---- Ternary g_rdf_g for #{self.inspect} for @child1 #{@child1.inspect} @child2 #{@child2.inspect} @child3 #{@child3.inspect}"
     # first_n3graph = @child1.generate_rdf_graph
     #second_n3graph = @child2.generate_rdf_graph
      #third_n3graph = @child3.generate_rdf_graph
      rdfpred = $ternary_rel2rdfpreds[@type]
      rdfpred[3] = "bel:Thing" if rdfpred[3].nil? || rdfpred[3].empty?
      
      qname_array = []
      child_name_results = []
      [@child1,@child2,@child3].each {|child|
          if child.instance_of?(String)
              # create URI node
              result = create_primaryname_and_qname(child.to_s)
              child_name_results << result
              qname_array << result[1]
              puts "---- Ternary g_rdf_g child #{child} qname #{result[1]}"
          else
              rdf_n3graph = child.generate_rdf_graph
              primary_node = rdf_n3graph[1]
              qname = rdf_n3graph[2]
              puts "---- Ternary g_rdf_g qname2 #{qname}"
              qname_array << fixNumName(qname)
              ns = "ns1"
              child_name_results << [primary_node, qname, ns]
          end
          puts "... g_rdf_g building qname #{qname} from @child #{child} in type #{@type}"
      }
      puts "---- Ternary g_rdf_g qname_array #{qname_array.inspect}"

      secondary_node = "ns1:#{qname_array.join('_')}_#{type}"  # use local ns here for terminal nodes
      puts "---- Ternary g_rdf_g secondary_node #{secondary_node}"
      
      addTriple(secondary_node, "a", rdfpred[3])
      label = secondary_node.gsub(/^[a-zA-Z0-9]+:/,'').gsub(/_/,' ')
      addTriple(secondary_node, "rdfs:label", label) 

      pred_index = 0
      child_name_results.each {|result|
                    
          primary_node = result[0]
          qname = result[1]
          ns = result[2]
          primary_type = $namespacetypes[ns]

          addTriple(primary_node, "a", primary_type) 
          addTriple(primary_node, rdfpred[pred_index], secondary_node)
          label = primary_node.gsub(/^[a-zA-Z0-9]+:/,'').gsub(/_/,' ')
          addTriple(primary_node, "rdfs:label", label) 
          addTriple(secondary_node, "bel:has_child", primary_node)  ## transitive but added explicitly here
          inv_pred = rdfpred[pred_index+4]  ## .gsub(/(has_|to_|from_)/,"child_for_")
          addTriple(secondary_node, inv_pred, primary_node)
          
          pred_index += 1
      }


      n3_graph = ["#{primary_node} #{rdfpred[0]} #{secondary_node} . #{secondary_node} a #{rdfpred[1]} .\n", "#{secondary_node}", "#{secondary_node}"]
  end
  
  
  def generate_bel  ## 
      first = @child1.generate_bel
      if @child2.instance_of?(String)
          second = @child2
      else
          second = @child2.generate_bel
      end
      if @child3.instance_of?(String)
          third = @child3
      else
          third = @child3.generate_bel
      end
          
      "#{@type}(#{first}, #{second}, #{third})"
  end
      
end 


###############################################################################################
## Basic local TripleStore routines
###############################################################################################

$TripleStore = {}

    def emptyTriples
      $TripleStore.each_pair {|subject, predsHash|
          predsHash.clear
      }
      $TripleStore.clear      
    end
    
    def object_property?(prop)
      prop =~ /:id/
    end

    def functional_property?(prop)
      prop =~ /:fp/
    end
    
    def addTriple(subject, property, object)   #  {subj1 => {prop1 => obj1, prop2 => obj2}, }
      # assumes one object per prop per subj !!!
      #puts "--- #{subject} - #{property} -- #{object}"
      subjPredsHash = $TripleStore[subject]
      unless subjPredsHash
        subjPredsHash = {}
        $TripleStore[subject] = subjPredsHash
      end
      existing_obj = subjPredsHash[property]
    #      if existing_obj && object_property?(property)
      if existing_obj && !functional_property?(property)
        if existing_obj.instance_of?(Array)
          subjPredsHash[property] = (existing_obj << object) unless existing_obj.include?(object)
        else #elsif
          unless existing_obj.eql? object
              subjPredsHash[property] = [existing_obj, object] 
          end
        end
      else #elsif
        subjPredsHash[property] = object
      end
      # $TripleStore[subject] = subjPredsHash
    end
    
    def removeTriple(subject, property, object)   #  {subj1 => {prop1 => obj1, prop2 => obj2}, }
    end

    def removeAllTriplesbySubject(subject)   #  {subj1 => {prop1 => obj1, prop2 => obj2}, }
        $TripleStore.delete(subject)
    end
    
    
    def getBySubject(subject)    # returns properties hash for a subject
      subjHash = $TripleStore[subject]
#      if subjHash
#        subjHash.to_a
#      end
    end

    def getByObject(object)  # returns subj, prop pairs
      results = []
      # subjects = $TripleStore.keys
      $TripleStore.each {|subj, predsHash|
          if predsHash.value?(object)
       #     if existing_obj.instance_of?(Array) ..... NOT FINISHED YET!!
            results << [subj, predsHash.index(object)] # subj, prop pairs
          end
      }
      results
    end

    def getByProperty(prop)
      results = []
    #  subjects = $TripleStore.keys
      $TripleStore.each_pair {|subj, predsHash|
        obj = predsHash[prop]
        if obj
            results << [subj, obj] # subject, object pairs
        end
      }
      results
    end
    
    
    def prefixesN3
        prefixes = %{
@prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix owl:  <http://www.w3.org/2002/07/owl#> .
@prefix dc: <http://purl.org/dc/elements/1.1/> .
@prefix : <http://openbel.org/belowl#> .
@prefix bel: <http://openbel.org/belowl#> .
@prefix ns1: <http://openbel.org/belowl/ns/> .

}
        prefixes
    end
    
=begin
@prefix HGNC:  <http://www.genenames.org/hugo/owl#> .
@prefix UNI:  <http://www.uniprot.org/protein#> .
@prefix ENTREZ: <http://purl.biowebcentral.org/ncbi/gene/> .
@prefix CHEBI: <http://openbel.org/belowl/CHEBI/> .
@prefix MESHD: <http://openbel.org/belowl/MESHD/> .
=end
    
def createPrefixes
   prefix_str = ""
   $dynamicNStypes.each {|ns, url|
       prefix_str += "@prefix #{ns}:  <#{url}#> .\n"
   } 
   prefix_str += "\n\n"
end
    
def triplestore2RDF # N3
    #puts "dynamic prefixes \n\n#{createPrefixes}"
    n3_string = prefixesN3 + createPrefixes
    $TripleStore.each_pair {|subject, predsHash|
        first_pass = true
        predsHash.each_pair {|pred, object|
            #puts "---- this obejct is an array #{object}"  if object.instance_of?(Array)
            sobject = object
            sobject = object.join(' , ')  if object.instance_of?(Array)
            #puts "??????? #{sobject}" 
            #puts "!!!!!!! URIs #{sobject}" if /^[a-zA-Z]*:/.match(sobject)
            # URI or URL test...
            m = /^(_|[a-zA-Z0-9]*:[^\s]|<)/.match(sobject)
            sobject = "\"#{sobject}\"" unless m     ## sobject.instance_of?(String)
            if first_pass
                n3_string += "#{subject} #{pred} #{sobject} "
            else
                n3_string += ";\n\t#{pred} #{sobject} "                    
            end
            first_pass = false
        }
        n3_string += ".\n\n"
    }
   n3_string 
end

##################################################################################################
## This routine converts current triplestore to serialized RDF in batchSized chunks
## $TripleStore is not cleared here
##################################################################################################
def triplestore2RDFBatched(output_file) # N3
    batchSize = 10
    subjectSets = 0
    #puts "dynamic prefixes \n\n#{createPrefixes}"
    
    deputs "triplestore2RDFBatched, subject size #{$TripleStore.size}"
    n3_string = prefixesN3 + createPrefixes
    sum = 0
    batch_sum = 0
    batch = 0
    $TripleStore.each_pair {|subject, predsHash|
        subj_sum = predsHash.size
        #puts "triplestore2RDFBatched, predicates per subject #{subj_sum}"
        batch_sum += subj_sum
        subjectSets += 1
        first_pass = true
        predsHash.each_pair {|pred, object|
            #puts "---- this obejct is an array #{object}"  if object.instance_of?(Array)
            #sobject = object.join(' , ')  if object.instance_of?(Array)
            deputs "object is array!" if object.instance_of?(Array)
            objects = object
            objects = [object] unless object.instance_of?(Array)

            #puts "??????? #{sobject}" 
            #puts "!!!!!!! URIs #{sobject}" if /^[a-zA-Z]*:/.match(sobject)
            # URI or URL test...
            objects = objects.map {|sobject|
                if /^(http:\/\/[^\s]+)$/.match(sobject)
                    sobject = "<#{sobject}>"      ## http uri
                    deputs "stringify http object: #{sobject}"
                elsif /^((_|[a-zA-Z0-9]*):[^\s]+$|<http:\/\/)/.match(sobject)
                    sobject = sobject
                    deputs "stringify uri object: #{sobject}"
                else
                    deputs "stringify literal: #{sobject}"
                    sobject = "\"#{sobject}\""     ## sobject.instance_of?(String)
                end   
                sobject             
            }
            object_clause = objects.join(' , ')  
            if first_pass
                n3_string += "#{subject} #{pred} #{object_clause} "
            else
                n3_string += ";\n\t#{pred} #{object_clause} "                    
            end
            first_pass = false
        }
        n3_string += ".\n\n"
        
        if subjectSets > batchSize
            batch += 1
            deputs "---Batch ##{batch}, predicate total: #{batch_sum}, current total #{sum}"
            sum += batch_sum
            batch_sum = 0
            output_file.write(n3_string)
            n3_string = ""
            subjectSets = 0
        end        
    }
    sum += batch_sum
    output_file.write(n3_string)
    deputs "triplestore2RDFBatched: has #{sum} triples"
end


def triplestore2Turtle
    n3_string = prefixesN3
    $TripleStore.each_pair {|subject, predsHash|
        predsHash.each_pair {|pred, object|
            n3_string += "#{subject} #{pred} #{object} .\n"
        }
    }
   n3_string 
end

def normalizeTerm(term_str)
    norm_term = $synonyms[term_str]
    #puts "... normalizeTerm #{term_str} to #{norm_term}"
    if !norm_term && $synonyms.value?(term_str) 
        norm_term = term_str
    end
    norm_term ||= term_str ## if not found, simply use term_str!!
end

def isUnary_Op(term_str)
    #puts "---- test for Unary op #{term_str}: #{$unary_relations.member?(term_str)}"
   $unary_relations.member?(term_str) 
end

def isBinary_Op(term_str)
    #puts "---- test for Binary op #{term_str}: #{$binary_relations.member?(term_str)}"
   $binary_relations.member?(term_str) || $binary_relations.member?($synonyms[term_str])
end

def isNary_Op(term_str)
    #puts "---- test for Nary op #{term_str}: #{$nary_relations.member?(term_str)}"
   $nary_relations.member?(term_str) 
end

def isTernary_Op(term_str)
    #puts "---- test for Ternary op #{term_str}: #{$ternary_relations.member?(term_str)}"
   $ternary_relations.member?(term_str) 
end

##################################################################################################
## This routine generates triples and converts current set to serialized RDF per seq_group chunks
## and return list of root node ids
## $TripleStore IS cleared here!!
##################################################################################################
def generate_and_serialize_RDF_per_nodes(seq_group, output_file)
      node_id_seq = ""
      seq_group.each {|node| 
          s = node.generate_rdf_graph
          node.cached_id = s[1]
          node_id_seq += node.cached_id + " " 
      } 
      triplestore2RDFBatched(output_file) 
      emptyTriples 
      
      #memory_usages = `ps -A -o rss=`.split("\n")
      #total_mem_usage = memory_usages.inject { |a, e| a.to_i + e.strip.to_i }
      #puts "total_mem_usage #{total_mem_usage}"
      #puts "$TripleStore size #{$TripleStore.size}"
      #seq_group.clear
      node_id_seq
end
