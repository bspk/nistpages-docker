# encoding: utf-8
require 'kramdown/latexnist/version'

require 'kramdown/converter/base'

module Kramdown
	module Converter
		#
		# Converts markdown into LaTeX with special sauce
		#
		class Latexnist < Latex
			
	        # Initialize the LaTeX converter with the +root+ element and the conversion +options+.
			def initialize(root, options)
				@headers = options[:yaml_headers]
				super
		        ENTITY_CONV_TABLE.each_value {|v| v[0] = "#{v[0]}{}" } # add extra escape sequence to HTML entity conversion values
			end

	        def convert_footnote(el, opts)
	          @data[:packages] << 'fancyvrb'
			  options = opts.dup.merge(:footnote => true) #flag everythign inside a footnote as special because we need to treat things a little differently sometimes
	          "\\footnote{#{inner(el.value, options).rstrip}}"
	        end
			
			def convert_a(el, opts)
				url = el.attr['href']
				
				if el.attr['name']&.start_with?('ref-') # reference anchor
					"\\hypertarget{#{el.attr['name']}}{#{inner(el, opts)}}\\label{#{el.attr['name']}}"
				elsif url =~ /#((ref-|s-|f-).*)\z/ # internal document links
					"\\hyperlink{#{$1}}{#{inner(el, opts)}}"
				elsif url.start_with?('#')
					"\\hyperlink{#{url[1..-1].gsub('%', '\\%')}}{#{inner(el, opts)}}"
				else
					"\\href{#{url.gsub('%', '\\%')}}{#{inner(el, opts)}}"
				end
			end
			
	        def convert_img(el, _opts)
	          line = el.options[:location]
			  
			  src = el.attr['src']
			  
	          if src =~ /^(https?|ftps?):\/\//
	            warning("Cannot include non-local image#{line ? " (line #{line})" : ''}")
	            ''
	          elsif !src.empty?
	            @data[:packages] << 'graphicx'
				
				# grab our special image path if it's there
				src = el.attr['latex-src'] || src
				
	            "#{latex_link_target(el)}\\includegraphics[width=\\linewidth]{#{src}}"
	          else
	            warning("Cannot include image with empty path#{line ? " (line #{line})" : ''}")
	            ''
	          end
	        end

	        TABLE_ALIGNMENT_CHAR = {default: 'L', left: 'L', center: 'C', right: 'R'} # :nodoc:

			def convert_table(el, opts)
				@data[:packages] << 'tabulary'
				#align = el.options[:alignment].map {|a| TABLE_ALIGNMENT_CHAR[a] }.join('|')
				#align = el.options[:alignment].map {|a| 'L' }.join('|')
				attrs = attribute_list(el)
				"#{latex_link_target(el)}\\begin{tabulary}{\\linewidth}{|#{align}|}#{attrs}\n" \
				"\\hline\n#{inner(el, opts)}\n\\end{tabulary}#{attrs}\n\n"
			end

	        def convert_tr(el, opts)
	          el.children.map {|c| send("convert_#{c.type}", c, opts) }.join(' & ') << "\\\\ \\hline\n"
	        end

			# Debug helper method
			def printelopts(el, opts)
				puts "EL++++ ", el.inspect
				puts "OPTS++ ", opts.inspect
				puts "------ -------------------------------"
			end
			
		end
	end
end