"""
Pre-processes a special doc or accompanying site written in markdown for pdf render.
Requires .md files that are intended for Jekyll and include Jekyll front matter headers, which are the first thing
    in the file and are delineated with '---\n'.

Written by Mark Sherman <mark@bspk.io>
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

# tags from configuration file _pdf.yml, just in case you want to change them later
TAG_PARTS = 'parts'

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
    headers, body = parse_frontmatter(filename)

    done = subprocess.run(['/opt/pdf/kramdown-latexnist'], input=body, text=True, capture_output=True)

    # this is where we'd post-process the individual latex results if we need to
    output = done.stdout

    return headers, output


def assemble_parts(config):

    foreword = []
    for p in config['foreword']: 
        headers, body = md_to_latex(os.path.join(config['basedir'], p))
        foreword.append(body)

    texts = []
    for p in config['body']:
        headers, body = md_to_latex(os.path.join(config['basedir'], p))
        texts.append(body)
    
    # post-proces texts through template
    template = latex_jinja_env.get_template(os.path.join(config['basedir'], config['template']))
    
    vars = {
        'body': "\n".join(texts),
        'foreword': "\n".join(foreword)
    }
    
    # copy over some fields from the config block
    for field in ('report_number', 'doi_url', 'month', 'year'):
        vars[field] = config[field]
    
    latex = template.render(vars)
    
    return latex
    


def generate_doc():
    if (os.path.exists('_pdf.yml')):
        configs = read_yaml('_pdf.yml')

        for idx, config in enumerate(configs['pdf']):
            print("Processing PDF configuration %d:" % idx)
            pp.pprint(config)
            body = assemble_parts(config)
            filename = os.path.join(config['basedir'], config['filename'] + '.tex')
            print("Writing file %s" % filename)
            with open(filename, 'w') as f:
                f.write(body)

def main():
    generate_doc()

if __name__ == "__main__":
    main()
