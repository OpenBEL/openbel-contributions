# Eric Neumann  copyright 2012
# parse_bel2rdf.rb
# VERSION 1.05
# Requires ruby 1.8 - won't run with 1.9 or later
# USAGE: ruby parse_bel2rdf.rb [-nocomment] <belfilename>


# require 'net/http'
# require 'builder'
require 'cgi'
require 'digest'
require 'digest/sha1'

load 'bel_rdf.rb'
load 'parens_parse.rb'

$DEBUG = false

def deputs(str)
    puts str if $DEBUG
end

$Line = 0

$UniqueRelationships = {}

$BinaryOpWithParensMatchPattern = nil
$BinaryOpMatchNoParensPattern = nil

class BELParsingException < RuntimeError
  attr :statement
  def initialize(statement)
    @statement = statement
  end
end

def buildPatterns()
    pat_array = []
   $binary_relations.each{|bin_op|
       syn_op = $hasSynonym[bin_op]
       deputs "bin_op #{bin_op} syn_op #{syn_op}"
       pat_array << bin_op.gsub(/\|/,'\|')
       pat_array << syn_op.gsub(/\|/,'\|') unless bin_op.eql?(syn_op) || !syn_op
   }
   pat_str = pat_array.join('|')
   $BinaryOpMatchNoParensPattern = Regexp.new("^(.+)\\s+(#{pat_str})\\s+(.+)$")
   $BinaryOpWithParensMatchPattern = Regexp.new("^(.+)\\s+(#{pat_str})\\s+\\((.+)\\)$")

   #match1 = /^(.+)\s*(->|=>|-\||=\||positiveCorrelation|negativeCorrelation|prognosticBiomarkerFor|causesNoChange)\s*(.+)$/
   #mp =     /^(.+)\s*(->|=>|-\||=\||positiveCorrelation|negativeCorrelation|prognosticBiomarkerFor|causesNoChange)\s*\((.+)\)$/

   deputs " "
   deputs "#{$BinaryOpWithParensMatchPattern.inspect}"
   #throw Exception.new
end
#initRelations()

buildPatterns()



#################

def notArray!(obj)
    throw Exception.new if obj.instance_of?(Array)
end

def modificationArray2Parens(modif_array)
    return nil unless modif_array
    modifications = []
    if modif_array
       modif_array.each {|node|
           deputs "      --- modificationArray2Parens node: #{node.inspect}"
           #modification_str = "#{node[0]}(#{node[1][0]}#{' ,' + node[2][0] if node.length > 2}#{' ,' + node[3][0] if node.length > 3})"
           modification_str = node[1].join(',')
           modifications << modification_str
       }
    end
    deputs "      --- modificationArray2Parens modifications: #{modifications}"
    modifications
end
###############################################################################################
## traverse_statement_tree
## BEL Stetement Tree Traversal after recursive parsing
###############################################################################################
$traverse_level = 0

def traverse_statement_tree(input_tree)
    $traverse_level += 1
    spacer = "   " * $traverse_level
deputs "#{spacer}traverse_statement_tree with #{input_tree.inspect} at level #{$traverse_level}"

    if input_tree.length == 4 && input_tree[0].eql?("GROUP")
        input_tree = input_tree.drop(1)
    end
# Binary infix operator search... input_tree.length == 3 && input_tree[1] == operator
    if input_tree.length == 3 && isBinary_Op(input_tree[1][0])
        deputs "#{spacer}-- infix-binop #{input_tree[1][0]} found in #{input_tree.inspect}"
        operator = normalizeTerm(input_tree[1][0])
        left_branch = input_tree[0]
        left_node = traverse_statement_tree(left_branch)

        right_branch = input_tree[2]
        right_node = traverse_statement_tree(right_branch)
        result_node = BELBinaryOpNode.new(operator, left_node, right_node)

# Binary prefix operator search...
    elsif input_tree.length == 3 && isBinary_Op(input_tree[0]) && input_tree.length == 3
        deputs "#{spacer}-- prefix-binop #{input_tree[0]} found in #{input_tree.inspect}"
        operator = normalizeTerm(input_tree[0])
        left_branch = input_tree[1]
        left_node = traverse_statement_tree(left_branch)

        right_branch = input_tree[2]
        right_node = traverse_statement_tree(right_branch)
        result_node = BELBinaryOpNode.new(operator, left_node, right_node)

# Nary operator search... [["nary-op",[...],[...]]]
    elsif input_tree.length == 1 && isNary_Op(input_tree[0][0]) && input_tree[0].length > 2
        deputs "#{spacer}-- Nary-op #{input_tree[0][0]} found in #{input_tree.inspect}"
        operator = normalizeTerm(input_tree[0][0])
        left_node = traverse_statement_tree(input_tree[0][1])
        nary_terms = input_tree[0][2..-1]
        rest_nodes = []
        nary_terms.each {|term_arg|
            deputs "........ parsing out arg #{term_arg.inspect}"
            arg_node = traverse_statement_tree(term_arg)
            rest_nodes << arg_node
        }
        deputs "#{spacer}-- Create Nary node with op: #{operator} leftnode: #{left_node.inspect} and restnodes #{rest_nodes.inspect}"
        result_node = BELUnaryOpNode.new(operator, left_node, rest_nodes)

# Nary operator search... ["nary-op",[...],[...]]
    elsif input_tree.length > 2 && isNary_Op(input_tree[0])
        deputs "#{spacer}-- Nary-op #{input_tree[0]} found in #{input_tree.inspect}"
        operator = normalizeTerm(input_tree[0])
        left_node = traverse_statement_tree(input_tree[1])
        deputs " - - - what is the leftnode? #{left_node.inspect}"
        nary_terms = input_tree[2..-1]
        rest_nodes = []
        nary_terms.each {|term_arg|
            deputs "........ parsing out arg #{term_arg.inspect}"
            arg_node = traverse_statement_tree(term_arg)
            rest_nodes << arg_node
        }
        deputs "#{spacer}--+ Create Nary node with op: #{operator} leftnode: #{left_node.inspect} and restnodes #{rest_nodes.inspect}"
        result_node = BELUnaryOpNode.new(operator, left_node, rest_nodes)


# Unary operator search...[["Unary-op",[arg1],[opt]]]
    elsif input_tree.length == 1 && isUnary_Op(input_tree[0][0])
        deputs "#{spacer}-- Unary-op #{input_tree[0][0]} found in #{input_tree.inspect}"
        operator = normalizeTerm(input_tree[0][0])
        left_node = traverse_statement_tree(input_tree[0][1])
        opt_nodes = nil
        opt_nodes = input_tree[0][2..-1] if input_tree[0].length > 2
        deputs "#{spacer}-- opt_nodes #{opt_nodes.inspect}"
        #modifications = modificationArray2Parens(opt_nodes)
        modifications = opt_nodes

        deputs "#{spacer}-- Create Unary node with op: #{operator} leftnode: #{left_node.inspect} and modifications #{modifications.inspect}"
        result_node = BELUnaryOpNode.new(operator, left_node, modifications)

# Unary operator search...["Unary-op",[arg1],[opt]]
    elsif input_tree.length > 1 && isUnary_Op(input_tree[0])
        deputs "#{spacer}-- Unary-op2 #{input_tree[0]} found in #{input_tree.inspect}"
        operator = normalizeTerm(input_tree[0])
        left_node = traverse_statement_tree(input_tree[1])
        opt_nodes = nil
        opt_nodes = input_tree[2..-1] if input_tree.length > 2
        deputs "#{spacer}-- opt_nodes #{opt_nodes.inspect} , input_tree[2] #{input_tree[2].inspect}"
        #modifications = modificationArray2Parens(opt_nodes)
        modifications = opt_nodes

        deputs "#{spacer}--+ Create Unary node with op: #{operator} leftnode: #{left_node.inspect} and modifications #{modifications.inspect}"
        result_node = BELUnaryOpNode.new(operator, left_node, modifications)

# Ternary operator search...["Ternary-op",[arg1],[arg2],[arg3],[opt]]
    elsif input_tree.length > 1 && isTernary_Op(input_tree[0])
        deputs "#{spacer}-- Ternary-op #{input_tree[0]} found in #{input_tree.inspect}"
        operator = normalizeTerm(input_tree[0])
        first_node = traverse_statement_tree(input_tree[1])
        second_node = traverse_statement_tree(input_tree[2])
        third_node = traverse_statement_tree(input_tree[3])
        opt_nodes = nil
        opt_nodes = input_tree[4..-1] if input_tree.length > 4

        deputs "#{spacer}--+ Create Ternary node with op: #{operator} first_node: #{first_node.inspect} , second_node: #{second_node.inspect}, third_node: #{third_node.inspect} and opt_nodes #{opt_nodes.inspect}"
        result_node = BELTernaryOpNode.new(operator, first_node, second_node, third_node, opt_nodes)

# URI search...
    elsif input_tree.length == 1 && input_tree[0].instance_of?(String)
        deputs "#{spacer}-- string #{input_tree[0]} found in #{input_tree.inspect}"
        string = input_tree[0]
        match1 = /^([a-zA-Z0-9]+:)?\"([^"]+)\"/.match(string)
        deputs "#{spacer}-- matching #{match1.inspect}"
        match1 = /^([a-zA-Z0-9]+:)?([^"]+)/.match(string) unless match1
        deputs "#{spacer}-- matching 2 #{match1.inspect}"
        throw Exception.new unless match1

        #inputstr = match4[1] + match4[2].gsub(/\s+/,'_').gsub(/[\(\)]/,'_').gsub(/\+/,'plus')  # CGI encode CGI.escape("NAD(+)")
        result_node = "#{match1[1]}#{fixQName(match1[2])}"

    else
        puts "#{spacer}Bad condition traverse_statement_tree with #{input_tree.inspect} at level #{$traverse_level}"

    end

    $traverse_level -= 1

    deputs "#{spacer}returning for traverse_statement_tree #{result_node.inspect}"
    return result_node
end

$COMMENT = true
$VERBOSE = false
###############################################################################################
## Top level parsing routine with file as input
###############################################################################################

def parse_bel_file
    emptyTriples
    $BELDocumentSequence = []
    batch_node_sequence = []
    node_id_seq = ""
    $rootnode = nil
    doc_node = nil
    $Statement_Num = 0

#    filename = $*[0]
    filename = $*[$*.length-1]
    $*.each {|flag|
        case flag.downcase
        when "-nocomment"
            $COMMENT = false
            deputs "nocomment...."
        when "-verbose"
            $VERBOSE = true
        end
    }

# Open output file...
    bel_file = File.new(filename, 'r')
    outPathFileName = filename.sub(".txt","")
    output_file = File.new("#{outPathFileName}.#{"n3"}", 'w+')




    lineCnt = 0
  lineSep = "\n"

# build _relations lists from rel2rdfpreds keys...
    initRelations()

   bel_file.each(lineSep) {|line|
       $Line += 1
       ## BEWARE of DOS escape characters at beginning of files!! \357\273\277
       deputs "BAD ESCAPE CHARS FOUND: \\357\\273\\277" if /^\357\273\277/=~line
       line = line.gsub(/^\357\273\277/,'')

       line.strip!
       $rootnode = nil
       #puts "---- line #{line} with char0=#{line[3]} == #{"##"[0]}"

       while (/\\$/=~line)
           line.chop!
           ln = bel_file.readline(lineSep)
           ln.strip!
           line << " " << ln
           #puts "found another -#{ln[-1,1]}-" if /\\/=~ln
           #puts "************ commented line break found #{line}"
       end

       deputs "---- line #{$Line}, processing: #{line}"
       if /^#/=~line ##  Look for comments
            deputs "...# #{line}"
            $rootnode = BELCommentNode.new(line) if $COMMENT

       elsif m = /^UNSET (\w+)/.match(line)
           value =  m[1]
           deputs "----- UNSET  #{value}"
           resetContext()

       elsif m = /^SET (\w+)/.match(line)
           #puts "...SET #{line}"
           case m[1]
           when "DOCUMENT"
               unless $BELDocumentNode
                   $BELDocumentNode = BELDocumentNode.new()
                   ##$rootnode = $BELDocumentNode  needs to be done only once....
               end
               start = "SET DOCUMENT".length
               line = line.slice(start+1, line.length)
               match = /^(\w+) = "([^"]+)"/.match(line)
               params = {match[1] => match[2]} if match
               #puts "----- SET DOCUMENT match #{params.inspect}"
               #$BELDocumentNode.add_values(params)
               key = match[1]
               key = "title" if key == "Name"

               $BELDocumentNode.add_keyval(key.downcase, match[2])

           when "Citation"     ##     SET Citation = {"PubMed", "Exp Clin Immunogenet, 2001;18(2) 80-5","11340296"}
               match = /^SET Citation = \{"([^,"]+)"\s*,\s*"([^"]+)"\s*,\s*"([^,"]+).*"\}/.match(line)
               deputs "...... SET Citation match #{line}"
               $rootnode = BELCitationNode.new(match[1], match[2], match[3])

           when "Species"  ##     SET Species = "9606"
               #match = /^SET Species =\s+"([^,"]+)"/.match(line)
               species = line.scan(/"([^"]+)"/)
               species.flatten! if species
               #puts "...... SET Citation match #{line}"
               species.each {|specie|
                   ##$BELDocumentSequence << $rootnode ; batch_node_sequence << $rootnode if $rootnode
                   batch_node_sequence << $rootnode if $rootnode
                   $rootnode = BELSpeciesNode.new(specie)
                   addContextSetting($rootnode)
               } if species

           when "Tissue" ##      SET Tissue = "t-cells"
               #match = /^SET Tissue =\s+"([^,"]+)(\s*,\s*([^\s,"]+))*\s*"/.match(line)
               #tissues_str = ""
               #match = /^SET Tissue =\s*"([^"]+)\s*"/.match(line)
               tissues = line.scan(/"([^"]+)"/)
               tissues.flatten! if tissues
               #tissues_str = match[1] if match[1]
               #tissues = tissues_str.split(",")
               #puts "...... SET Citation match #{line} match #{tissues.inspect}"

              # deputs "tissues #{tissues.inspect}" ; throw "mine"    if tissues
               tissues.each {|tissue|
                   ##$BELDocumentSequence << $rootnode ; batch_node_sequence << $rootnode if $rootnode
                   batch_node_sequence << $rootnode if $rootnode
                   $rootnode = BELTissueNode.new(tissue)
                   addContextSetting($rootnode)
               } if tissues

           when "CellLine" ##      SET CellLine  = "U-937" or {"U-937" , "Balb-1C"}
               #match = /^SET CellLine =\s+"([^,"]+)"/.match(line)
               cells = line.scan(/"([^"]+)"/)
               cells.flatten! if cells
               #puts "...... SET CellLine match #{line}"
               cells.each {|cellline|
                   ##$BELDocumentSequence << $rootnode ; batch_node_sequence << $rootnode if $rootnode
                   batch_node_sequence << $rootnode if $rootnode
                   $rootnode = BELCellLineNode.new(cellline)
                   addContextSetting($rootnode)
               } if cells

           when "Evidence" ##    SET Evidence = "Here we show that interfereon-alpha (IFNalpha) is a potent producer of SOCS expression in human T cells, as high expression of CIS, SOCS-1, SOCS-2, and SOCS-3 was detectable after IFNalpha stimulation. After 4 h of stimulation CIS, SOCS-1, and SOCS-3 had returned to baseline levels, whereas SOCS-2 expression had not declined."
               match = /^SET Evidence =\s+"([^"]+)"/.match(line.gsub(/\\"/,"'"))
               #puts "...... SET Evidence no match for #{line}" unless match
               $rootnode = BELEvidenceNode.new(match[1])
               addContextSetting($rootnode)

           when "ExposureTime" ##     SET ExposureTime = "4hr"
               match = /^SET ExposureTime =\s+"([^,"]+)"/.match(line)
               #puts "...... SET Citation match #{line}"
               $rootnode = BELExposureTimeNode.new(match[1])
               addContextSetting($rootnode)

           else
               value =  m[1]
               deputs "----- SET  #{value}"

           end

       elsif m = /^DEFINE (\w+) /.match(line)
                  #puts "...SET #{line}"
           case m[1]
           when "ANNOTATION" # DEFINE ANNOTATION Species AS URL \
                match = /^DEFINE ANNOTATION\s+(\w+)\s+AS\s+(\w+)\s+([^\n]+)/.match(line)
                #puts "...... DEFINE ANNOTATION match #{line} "
                #puts "...... DEFINE ANNOTATION == #{match.inspect}"
                defvalue = match[3]
                defvalue = "<" + defvalue + ">" if /http:/.match(defvalue)
                $rootnode = BELAnnotationNode.new(match[1], match[2], defvalue) if match
           #puts "...DEFINE #{line}"
            when "NAMESPACE"  #DEFINE NAMESPACE HGNC AS URL \
                match = /^DEFINE NAMESPACE (\w+) AS URL ([^\n]+)/.match(line)
                #puts "...... DEFINE ANNOTATION == #{match.inspect}"
                if match
                    namespace = match[1]
                    url = match[2]
                    $dynamicNStypes[namespace] = url
                    url.gsub!(/"/,'') # remove quotes around urls: quote2anglebracket()
                    url = "<" + url + ">" #
                    # deputs "++++++++ url #{url}"
                    $rootnode = BELNameSpaceNode.new(namespace, url)
                end

            when "DEFAULT"  #DEFINE DEFAULT NAMESPACE HGNC AS URL \
                match = /^DEFINE DEFAULT NAMESPACE (\w+) AS URL ([^\n]+)/.match(line)
                if match
                    url = match[2]
                    url.gsub!(/"/,'')
                    url = "<" + url + ">"
                    $rootnode = BELNameSpaceNode.new(match[1], url, "true")
                end

            end

       elsif /\/\//=~line
           #puts "//... #{line}"
           i = /\/\// =~ line
           statement  = line.slice(0,i)
           slice_str = line.slice(i+1, line.length)
           deputs "...BEL Statement with comment #{statement} slice #{slice_str} at i #{i} len #{line.length}"
           $rootnode = BELCommentNode.new(slice_str) if $COMMENT

           $Statement_Num += 1

           begin
               #testparse = parens_parse(statement)
               #puts "---- testparse #{testparse[1].inspect}"

               recursive_parsed = parens_parse(line)
               $rootnode = traverse_statement_tree(recursive_parsed)

               addContextStatement($rootnode)
           rescue BELParsingException => parseErrorDetail
               deputs ">>>>> BELParsingException at line #{$Line} with #{parseErrorDetail.statement}"
           end
           #$rootnode.generate_rdf_graph.to_s
       elsif !line.empty?
           deputs " "
           deputs "...BEL Statement call #{line}"

           $Statement_Num += 1
           begin
               recursive_parsed = parens_parse(line)
               #puts "---- testparse #{testparse[1].inspect}"
               node = traverse_statement_tree(recursive_parsed)
               $rootnode = node

               deputs ".."
               node_str = node.inspect
               rootnode_str = $rootnode.inspect
               deputs node_str
               deputs "  "
               #deputs "* * * COMPARE... #{"SAME" if node_str.length == rootnode_str.length}"
               #puts rootnode_str
               deputs "ORIG: #{line}"
               deputs "PARSED #{node.generate_bel}"
               deputs ".."

               addContextStatement($rootnode)
           rescue BELParsingException => parseErrorDetail
               deputs ">>>>> BELParsingException at line #{$Line} with #{parseErrorDetail.statement}"
           end
           #$rootnode.generate_rdf_graph.to_s
       end

       ##$BELDocumentSequence += batch_node_sequence
       ##$BELDocumentSequence << $rootnode ; batch_node_sequence << $rootnode if $rootnode
       batch_node_sequence << $rootnode if $rootnode
       #puts $rootnode.generate_rdf_graph.to_s
       ##
       if batch_node_sequence.length > 1000
           ## assume Document script is within first 1000 BEL lines !!
           puts ">>>> Batching with #{$Line} lines completed so far"
           doc_node = $BELDocumentNode.generate_rdf_graph unless doc_node

           node_id_seq += generate_and_serialize_RDF_per_nodes(batch_node_sequence, output_file)

           # Need to save $BELContextNodes in order to clear node mameroy cache better!!
           saveLastContextNode = $BELContextNodes.last
           $BELContextNodes = $BELContextNodes[0..-2]
           $BELContextNodes.each {|context_node|
               context_node.generate_rdf_graph
           }
           batch_node_sequence = []
           $BELContextNodes = [saveLastContextNode]
       end
   }
   if batch_node_sequence.length > 0
       ## assume Document script is within first 1000 BEL lines !!
       doc_node = $BELDocumentNode.generate_rdf_graph unless doc_node

       node_id_seq += generate_and_serialize_RDF_per_nodes(batch_node_sequence, output_file)
       batch_node_sequence = []

       # Last sweep-- Need to save $BELContextNodes in order to clear node mameroy cache better!!
       $BELContextNodes.each {|context_node|
           context_node.generate_rdf_graph
       }
       batch_node_sequence = []
   end

    #puts $BELDocumentSequence.inspect
    #puts "dynamic prefixes \n\n#{createPrefixes}"


    document_list = "_:seq0 bel:has_list ( "
    document_list << doc_node[1] << " " if doc_node[1]
    document_list << node_id_seq
    document_list << ") ."

=begin
    cnt = 0
    $BELDocumentSequence.each {|node|
        cnt += 1
        deputs " . . . .  generate rdf from Seq: # #{cnt}, #{node}"
        s = node.generate_rdf_graph
        node.cached_id = s[1]
        #puts "-------- #{s[1]}"
        document_list << s[1] << " " if s[1]
    }
    document_list << ") ."
    #puts "----- doc list #{document_list}"
=end

    #puts triplestore2RDF
    #out.triplestore2RDF

    output = ""

    #output << triplestore2RDF  #  generateN3FromTriplesStore($NameSpacesMapping, output_file)
    triplestore2RDFBatched(output_file)  #  generateN3FromTriplesStore($NameSpacesMapping, output_file)

    output << document_list
    output_file.write(output)
    output_file.close
    puts "---- #{$Line} lines completed, #{$Statement_Num} statements"
end

parse_bel_file


