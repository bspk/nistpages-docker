"""
Processes a set Jekyll site for PDF rendering.

Configured using the _pdf.yml configuration file.

Written by Mark Sherman <mark@bspk.io> and Justin Richer <justin@bspk.io>
"""
import os.path
import subprocess
from ruamel.yaml import YAML
yaml = YAML(typ='safe')
import pprint
pp = pprint.PrettyPrinter(indent=2)
import jinja2
from jinja2 import Template
import re

# Latex template for Jinja
latex_jinja_env = jinja2.Environment(
	block_start_string = '\BLOCK{',
	block_end_string = '}',
	variable_start_string = '\VAR{',
	variable_end_string = '}',
	comment_start_string = '\#{',
	comment_end_string = '}',
	line_statement_prefix = '%:',
	line_comment_prefix = '%#',
	trim_blocks = True,
	autoescape = False,
	loader = jinja2.FileSystemLoader(os.path.abspath('.'))
)

def read_yaml(filename):
    """Read and parse a configuration file

    :return: configuration parameters as an object
    """
    with open(filename) as file:
        config = yaml.load(file)
    return config


def parse_frontmatter(filename):
    """Read in a markdown file and separate the headers from the body, all as text.
    Used by md_to_latex, below.

    :param filename: path of a jekyll markdown file
    :return: header object, body text
    """
    with open(filename) as file:
        text = file.read()

    # find the header
    
    if (text.startswith('---\n')):
        header_end = text.index('---\n', 4) + 4  # The +4 is the length of the character sequence

        header = text[:header_end]
        body = text[header_end:]

        headers = yaml.load(header[4:-4])  # 'headers' is now a python object containing the header fields

        return headers, body
    else:
        return {}, text


def md_to_latex(filename):
    """Read in an md file from disk and process it into a headers object and a string of latex content.

    :param add_title: if True, prepends the body text with a title from the config data
    :param filename: path of a jekyll markdown file
    :return: headers as an object, latex content as a string
    """
    # parse the frontmatter out in case we need it later
    headers, body = parse_frontmatter(filename)

    # run the file through our external processor
    done = subprocess.run(['/opt/pdf/kramdown-latexnist', filename], text=True, capture_output=True)

    # this is where we'd post-process the individual latex results if we need to
    output = done.stdout

    return headers, output


def assemble_parts(config):

    foreword = collect_section(config, 'foreword')
    texts = collect_section(config, 'body')

    references = collect_section(config, 'references')
    abstract = collect_section(config, 'abstract')
    introduction = collect_section(config, 'introduction')
    acknowledgements = collect_section(config, 'acknowledgements')
    glossary = collect_section(config, 'glossary')
    
    
    # post-proces texts through template
    template = latex_jinja_env.get_template(os.path.join(config['basedir'], config['template']))
    
    vars = {
        'has_foreword': has_section(foreword),
        'has_references': has_section(references),
        'has_abstract': has_section(abstract),
        'has_introduction': has_section(introduction),
        'has_acknowledgements': has_section(acknowledgements),
        'has_glossary': has_section(glossary),
        
        'body': "\n".join(texts),
        'foreword': "\n".join(foreword)
    }
    
    # copy over some fields from the config block
    for field in ('report_number', 'doi_url', 'month', 'year'):
        vars[field] = config[field]
    
    # run rendered items and configuration through the template
    latex = template.render(vars)
    
    return latex

def has_section(list):
    return 'true' if list else 'false' # these flags are needed in this form for the latex template

def collect_section(config, section):
    # loop through every file in the collection and convert it using our external kramdown converter
    collect = []
    if section in config:
        for p in config[section]:
            headers, body = md_to_latex(os.path.join(config['basedir'], p))
            collect.append(body)
    return collect

def create_work_area(config):
    if (not os.path.exists(fileworkdir(config))):
        os.mkdir(fileworkdir(config))

def fileworkdir(config):
    return os.path.join(config['basedir'], config['workdir'], config['filename'])

def convert_to_pdf(config):
    # run pdflatex to do the converstion
    
    done = subprocess.run(['pdflatex', '-interaction=nonstopmode', '-halt-on-error', config['filename'] + '.tex'], cwd=fileworkdir(config), text=True, capture_output=True)
    
    return done.stdout

def generate_doc():
    # parse our configuration document and export the resulting file
    if (os.path.exists('_pdf.yml')):
        configs = read_yaml('_pdf.yml')

        for idx, config in enumerate(configs['pdf']):
            print("Processing PDF configuration %d:" % idx)
            pp.pprint(config)
            
            create_work_area(config)
            
            body = assemble_parts(config)
            filename = os.path.join(fileworkdir(config), config['filename'] + '.tex')
            print("Writing LaTeX file %s" % filename)
            with open(filename, 'w') as f:
                f.write(body)
            
            print("Writing PDF file")
            pdflog = convert_to_pdf(config)
            print(pdflog)


def main():
    generate_doc()

if __name__ == "__main__":
    main()
