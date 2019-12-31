# encoding: utf-8
require 'kramdown/latexnist/version'

require 'kramdown/converter/base'

module Kramdown
	module Converter
		#
		# Converts markdown into LaTeX with special sauce
		#
		class Latexnist < Latex
			
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
			
			
			def printelopts(el, opts)
				puts "EL++++ ", el.inspect
				puts "OPTS++ ", opts.inspect
				puts "------ -------------------------------"
			end
			
		end
	end
end