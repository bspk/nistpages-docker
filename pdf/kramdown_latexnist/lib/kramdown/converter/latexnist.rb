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
				
				text = inner(el, opts)
				
				if el.attr['name'] # named anchor, treat like a target not a link
					"\\hypertarget{#{el.attr['name']}}{#{text}}\\label{#{el.attr['name']}}"
				elsif url =~ /#((ref-|s-|f-).*)\z/ # internal document links
					"\\hyperlink{#{$1}}{#{text}}"
				elsif url.start_with?('#')
					"\\hyperlink{#{url[1..-1].gsub('%', '\\%')}}{#{text}}"
				elsif url == text
					"\\url{#{url.gsub('%', '\\%')}}"
				else
					"\\href{#{url.gsub('%', '\\%')}}{#{text}}"
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


			# \begin{tabulary}{\textwidth}{|p{0.1\textwidth}|p{0.07\textwidth}|p{0.25\textwidth}|p{0.2\textwidth}|p{0.2\textwidth}|}   %  latex-columns="p@0.1\textwidth,p@0.07\textwidth,p@0.25\textwidth,p@0.2\textwidth,p@0.2\textwidth"
			# \hline\rowcolor{black}
			# \color{white}\RaggedRight Color & \color{white}\RaggedRight Zone &\color{white}\RaggedRight sRGB Tristimulus Value (IEC 61966-2-1) &\color{white}\RaggedRight sRGB Value (IEC 61966-2-1) &\color{white}\RaggedRight CMYK Value \{C,M,Y,K\}\\ \hline
			

			def convert_table(el, opts)
				@data[:packages] << 'tabulary'
				attrs = attribute_list(el)
				
				if el.attr['latex-columns']
					# input is col@width,col@width,...
					# output is col{width}|col{width}|...
					align = el.attr['latex-columns'].split(',').map { |a| a.split('@') }.map { |c,w| c + '{' + w + '}' }.join('|')
				else
					align = el.options[:alignment].map {|a| TABLE_ALIGNMENT_CHAR[a] }.join('|')
				end
				
				if el.attr['latex-longtable']
					"#{latex_link_target(el)}\\begin{ltabulary}{|#{align}|}#{attrs}\n" \
					"\\hline\n#{inner(el, opts)}\n\\end{ltabulary}#{attrs}\n\n"
				else
					"#{latex_link_target(el)}\\begin{tabulary}{\\textwidth}{|#{align}|}#{attrs}\n" \
					"\\hline\n#{inner(el, opts)}\n\\end{tabulary}#{attrs}\n\n"
				end
			end

			def convert_tr(el, opts)
				if opts[:thead]
					rowflags = "\\rowcolor{black}"
				else
					rowflags = ""
				end
				
				"#{rowflags}\n" << \
				el.children.map {|c| send("convert_#{c.type}", c, opts) }.join(' & ') << "\\\\ \\hline\n"
			end

			def convert_td(el, opts)
				if opts[:thead]
					# table header
					"\\color{white}\\RaggedRight #{inner(el, opts)}"
				else
					# table body
					inner(el, opts)
				end
			end
			
			def convert_thead(el, opts)
				options = opts.dup.merge(:thead => true) #flag everythign inside as part of a table header
				"#{inner(el, options)}\n"
			end
			
			def convert_header(el, opts)
				type = @options[:latex_headers][output_header_level(el.options[:level]) - 1]
				if ((id = el.attr['id']) ||
					(@options[:auto_ids] && (id = generate_id(el.options[:raw_text])))) && in_toc?(el)
					"\\hypertarget{#{id}}{}\\label{#{id}}\n\\#{type}{#{inner(el, opts)}}\n\n"
				else
					"\\#{type}*{#{inner(el, opts)}}\n\n"
				end
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