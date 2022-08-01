# encoding: utf-8
require 'kramdown/latexnist/version'

require 'kramdown/converter/base'

require 'rcapture'

module Kramdown
	module Converter
		#
		# Converts markdown into LaTeX with special sauce
		#
		class Latexnist < Latex
			
  		  	include RCapture::Interceptable
			
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
				
				# render the link text
				text = inner(el, opts)
				
				if el.attr['name'] # named anchor, treat like a target not a link
					if el.attr['name'] =~ /((ref-).*)\z/ # reference anchor gets bolded
						"\\hypertarget{#{el.attr['name']}}{\\textbf{#{text}}}\\label{#{el.attr['name']}}"
					else
						"\\hypertarget{#{el.attr['name']}}{#{text}}\\label{#{el.attr['name']}}"
					end
				else
					if el.attr['latex-href'] # if there's a PDF-specific link, use it
						url = el.attr['latex-href']
					else
						url = el.attr['href']
					end
				
					if url =~ /#((ref-|s-|f-|table-|fig-).*)\z/ # internal document links (should these be expanded??)
						"\\hyperlink{#{$1.gsub('%', '\\%').gsub('#', '\\#')}}{#{text.gsub(' ', '~').gsub('-', '\\babelhyphen{nobreak}')}}" # use nonbreaking spaces
					elsif url.start_with?('#')
						"\\hyperlink{#{url[1..-1].gsub('%', '\\%').gsub('#', '\\#')}}{#{text}}"
					elsif escape(url) == text # we have to check the escaped URL because the inner text might have been escaped as well
						# displaying the actual URL, use the URL package
						"\\url{#{url.gsub('%', '\\%').gsub('#', '\\#')}}"
					else
						"\\href{#{url.gsub('%', '\\%').gsub('#', '\\#')}}{#{text}}"
					end
				end
			end
			
			def convert_img(el, opts)
				line = el.options[:location]
			  
				# grab our special image path if it's there
				src = el.attr['latex-src'] || el.attr['src']
			  
				if src =~ /^(https?|ftps?):\/\//
					warning("Cannot include non-local image#{line ? " (line #{line})" : ''}")
					''
				elsif !src.empty?
					@data[:packages] << 'graphicx'
				
					img = "#{latex_link_target(el)}\\includegraphics[width=\\linewidth]{#{src}}"
					
					if opts[:td]
						# we're in a table cell, wrap the image in an environment to get it to play nice
						"\\vspace{0.05cm}\\raisebox{-.5\\height}{#{img}}"
					else
						img
					end
					
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
					table = "#{latex_link_target(el)}\\begin{ltabulary}{|#{align}|}#{attrs}\n" \
					"\\hline\n#{inner(el, opts)}\n" \
					"\\end{ltabulary}#{attrs}\n\n"

					if el.attr['latex-table']
						caption = escape(el.attr['latex-caption'] || '')
						
						"{\n" \
						"\\renewcommand{\\tablename}{Table}\n" \
						"\\renewcommand{\\thetable}{#{escape(el.attr['latex-table'])}}\n" \
						"\\captionof{table}{#{caption}}\n" \
						"\\hypertarget{table-#{escape(el.attr['latex-table'])}}{}\\label{table-#{escape(el.attr['latex-table'])}}\n" \
						"#{table}\n" \
						"}\n"
					else
						table
					end

				else
					table = "#{latex_link_target(el)}\\begin{tabulary}{\\textwidth}{|#{align}|}#{attrs}\n" \
					"\\hline\n#{inner(el, opts)}\n" \
					"\\end{tabulary}#{attrs}\n\n"

					if el.attr['latex-table']
						caption = escape(el.attr['latex-caption'] || '')
					
						if el.attr['latex-place']
							placement = '[' + el.attr['latex-place'] + ']'
						else
							placement = '[H]'
						end
					
						"\\begin{table}#{placement}\n" \
						"\\centering \n" \
						"\\hypertarget{table-#{escape(el.attr['latex-table'])}}{}\\label{table-#{escape(el.attr['latex-table'])}}\n" \
						"\\renewcommand{\\tablename}{Table}\n" \
						"\\renewcommand{\\thetable}{#{escape(el.attr['latex-table'])}}\n" \
						"\\caption{#{caption}}\n" \
						"#{table}\n" \
						"\\end{table}\n"
					else
						table
					end
				end
			end

			def convert_tr(el, opts)
				rowflags = ""
				
				"#{rowflags}" << \
				el.children.map {|c| send("convert_#{c.type}", c, opts) }.join(' & ') << "\\\\ \\hline\n"
			end

			def convert_td(el, opts)
				options = opts.dup.merge(:td => true) #flag everything inside as part of a table header
				if opts[:thead]
					# table header
					"\\raggedright\\arraybackslash\\textbf{#{inner(el, options)}}"
				else
					# table body
					inner(el, options)
				end
			end
			
			def convert_thead(el, opts)
				options = opts.dup.merge(:thead => true) #flag everything inside as part of a table header
				"#{inner(el, options)}\n"
			end
			
			def convert_header(el, opts)
				type = @options[:latex_headers][output_header_level(el.options[:level]) - 1]
				
				if ((toc = el.attr['latex-toc']))
					# add in the short TOC name if applicable
					type = "#{type}[#{toc}]"
				end
				
				if ((id = el.attr['id']) ||
					(@options[:auto_ids] && (id = generate_id(el.options[:raw_text])))) && in_toc?(el)
					"\\hypertarget{#{id}}{}\\label{#{id}}\n\\#{type}{#{inner(el, opts)}}\n\n"
				else
					"\\#{type}*{#{inner(el, opts)}}\n\n"
				end
			end

			def convert_ul(el, opts)
				if !@data[:has_toc] && (el.options[:ial][:refs].include?('toc') rescue nil)
					@data[:has_toc] = true
					'\tableofcontents'
				else
					if el.attr['class'] && el.attr['class'] == 'letter-list'
						latex_environment('enumerate', el, inner(el, opts), '[label=\alph*)]')
					else
						latex_environment(el.type == :ul ? 'itemize' : 'enumerate', el, inner(el, opts))
					end
				end
			end
			alias convert_ol convert_ul

			def convert_p(el, opts)
				if el.children.size == 1 && el.children.first.type == :img &&
					!(img = convert_img(el.children.first, opts)).empty?
					convert_standalone_image(el, opts, img)
				else
					"#{latex_link_target(el)}#{inner(el, opts)}\n\n"
				end
			end

			# Helper method used by +convert_p+ to convert a paragraph that only contains a single :img
			# element.
			def convert_standalone_image(el, _opts, img)
				child = el.children.first
				if child.attr['latex-fig']
					attrs = attribute_list(el)
					if child.attr['latex-place']
						placement = '[' + child.attr['latex-place'] + ']'
					else
						placement = '[h]'
					end
					"\\begin{figure}#{placement}#{attrs}\n\\centering\n#{img}\n\n" \
					"\\renewcommand{\\figurename}{Figure}\n" \
					"\\renewcommand{\\thefigure}{#{child.attr['latex-fig']}}\n" \
					"\\caption{#{escape(child.attr['title'] || child.attr['alt'] || '')}}\n" \
					"\\hypertarget{fig-#{child.attr['latex-fig']}}{}\\label{fig-#{child.attr['latex-fig']}}\n" \
					"#{latex_link_target(el, true)}\n\\end{figure}#{attrs}\n"
				else
					super
				end
			end

			def convert_codeblock(el, _opts)
				if el.attr['latex-literal']
					el.value # don't escape this because we want it to be exported as a literal
				else
					super
				end
			end
			
			def convert_br(_el, opts)
				res = +"\\\\"
				res << "\n" if (c = opts[:parent].children[opts[:index] + 1]) &&
					(c.type != :text || c.value !~ /^\s*\n/)
				res
			end

			def convert_dt(el, opts)
				"\\item[#{inner(el, opts)}] \\hfill \\\\ "
			end

			def convert_dd(el, opts)
				"#{latex_link_target(el)}#{inner(el, opts)}\n\n"
			end

			def convert_strong(el, opts)
				# render the link text
				text = inner(el, opts)
				if ["SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "MAY", "NEED NOT", "CAN", "CANNOT", "CAPITALS"].include?(text)
					"\\colorbox{gray!10}{\\textbf{\\footnotesize{#{latex_link_target(el)}#{text}}}}"
				else
					"\\textbf{#{latex_link_target(el)}#{text}}"
				end
			end


			# Wrap the +text+ inside a LaTeX environment of type +type+. The element +el+ is passed on to
			# the method #attribute_list -- the resulting string is appended to both the \\begin and the
			# \\end lines of the LaTeX environment for easier post-processing of LaTeX environments.
			# if the string +envargs+ is passed, it is inserted after the \\begin tag as a set of environment options
			def latex_environment(type, el, text, envargs='')
				attrs = attribute_list(el)
				"\\begin{#{type}}#{envargs}#{latex_link_target(el)}#{attrs}\n#{text.rstrip}\n\\end{#{type}}#{attrs}\n"
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

# Check for the "latex-ignore" attribute flag on any structure in the document. If
# found, the element is not rendered. If not found, the function is called as normal.
Kramdown::Converter::Latexnist.capture_pre :methods => 
	[:convert_root, :convert_blank, :convert_text, :convert_p, :convert_standalone_image, 
	:convert_codeblock, :convert_blockquote, :convert_header, :convert_hr, :convert_ul, :convert_dl, 
	:convert_li, :convert_dt, :convert_dd, :convert_html_element, :convert_xml_comment, 
	:convert_xml_pi, :convert_table, :convert_thead, :convert_tbody, :convert_tfoot, 
	:convert_tr, :convert_td, :convert_comment, :convert_br, :convert_a, :convert_img, 
	:convert_codespan, :convert_footnote, :convert_raw, :convert_em, :convert_strong, 
	:convert_entity, :convert_typographic_sym, :convert_smart_quote, :convert_math, :convert_abbreviation]  do |ci|

	el = ci.args.first

	ci.predicate = !el.attr['latex-ignore']

	ci.return = ''
end
