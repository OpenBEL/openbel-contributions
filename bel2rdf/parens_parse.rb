#  Eric Neumann  copyright 2012
# parens_parse.rb 
# VERSION 1.0
# USAGE: subroutine > call parens_parse(STRING) returns tree_array

$level = 0
$DEBUG = false

def deputs(str) 
    puts str if $DEBUG
end

def parens_parse_recursive(inputstr) 
    
    unless inputstr
        puts "In parens_parse inputstr is NIL at level #{$level}"
        break
    end
    
    $level += 1
    spacer = "   " * $level
    #puts "#{spacer}parens_parse: #{inputstr} level #{$level}"
	
	array = []
	rest_string = inputstr
	
	new_pos = 0
	len = inputstr.length
	
	while (rest_string.any?) do
        ##puts "#{spacer}-- while loop with #{rest_string}"
		case rest_string
		when /^(\w*)\((.+)$/
			head = $1
			head = "GROUP" if head.empty?
			rest_string = $2
            deputs "#{spacer}-- matched operator #{head} with rest #{rest_string}"
	
			#array << head
	
			inner_array = parens_parse_recursive(rest_string)
			rest_string = inner_array[0]
            deputs "#{spacer}-- and found parsed #{inner_array.inspect}"
			array << [head] + inner_array[1]
			
		when /^(\w+):(\w+)\s*(.+)$/
			qname = "#{$1}:#{$2}"
			rest_string = $3
            deputs "#{spacer}-- matched uri #{qname} with rest #{rest_string}"

			array << [qname]
		
		when /^(\w+):("[^"]+")\s*(.+)$/
			ns = $1
			rest_string = $3

			qname = $2.gsub(/\s+/,'_')
            deputs "#{spacer}--++ matched uri ns: #{ns} & string #{qname} with rest #{rest_string}"
			
			array << ["#{ns}:#{qname}"]
			
		when /^\s*(\w+)\s*(.+)$/
			qname = $1
			rest_string = $2
            deputs "#{spacer}-- matched simple string #{qname} with rest #{rest_string}"
			array << [qname]

		when /^\s*("[^"]+")(.+)$/
			qname = $1
            deputs "#{spacer}-- matched term #{qname}"
			rest_string = $2
			array << [qname]

		when /^\s*,\s*(.+)$/
			rest_string = $1
            deputs "#{spacer}-- found next ',' with #{rest_string}"
			#break

		when /^\)(.*)$/
			rest_string = $1
            deputs "#{spacer}-- pop up for ')' with #{rest_string}"
			break
			
		else
            deputs "#{spacer}-- no matches with #{rest_string} -- should not be here!!"
		    throw Exception.new
		end

		
	end
	#puts "out of loop"
	
    $level -= 1
	
	return [rest_string , array]
end

def parens_parse(inputstr)
    result = parens_parse_recursive(inputstr)
    result[1]
end


## aaa(bbb("zzz") , ccc("yyy"))

=begin

arg_string = $*[0]
puts "arg_string #{arg_string}"

result = parens_parse(arg_string)

puts "result #{result.inspect}"
puts "statement length #{result.length}"
puts "... with infix op #{result[1][0].inspect}" if result.length > 1
puts "... with op #{result[0][0].inspect} length #{result[0].length}" if result.length == 1
=end

##puts "match test #{/^(\w+)\((.+)$/.match(arg_string).inspect}"
##puts "call with #{arg_string}"

# Test 10,000 times....
#for i in 0..10000
#    result = parens_parse(arg_string)
#end
#puts "result #{result[1].inspect}"
