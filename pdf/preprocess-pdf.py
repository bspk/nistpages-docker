"""
Pre-processes a special doc or accompanying site written in markdown for pdf render.
Requires .md files that are intended for Jekyll and include Jekyll front matter headers, which are the first thing
    in the file and are delineated with '---\n'.

Written by Mark Sherman <mark@bspk.io>
"""
import os.path
import subprocess
import nistpages_latex_template as latex
from ruamel.yaml import YAML
yaml = YAML(typ='safe')
import pprint
pp = pprint.PrettyPrinter(indent=2)

# tags from configuration file _pdf.yml, just in case you want to change them later
TAG_PARTS = 'parts'
TAG_NO_TITLE = 'doNotAddTitle'

def read_yaml(filename):
    """Read and parse a configuration file

    :return: configuration parameters as an object
    """
    with open(filename) as file:
        config = yaml.load(file)
    return config


def read_md(filename):
    """Read in a markdown file and separate the headers from the body, all as text.
    Used by md_to_latex, below.

    :param filename: path of a jekyll markdown file
    :return: header text, body text
    """
    with open(filename) as file:
        text = file.read()

    # find the header
    
    if (text.startswith('---\n')):
        header_end = text.index('---\n', 4) + 4  # The +4 is the length of the character sequence

        header = text[:header_end]
        body = text[header_end:]

        return header[4:-4], body
    else:
        return '', text


def md_to_latex(filename, add_title=True):
    """Read in an md file from disk and process it into a headers object and a string of latex content.
    Called automatically in assemble_parts

    :param add_title: if True, prepends the body text with a title from the config data
    :param filename: path of a jekyll markdown file
    :return: headers as an object, latex content as a string
    """
    header, body = read_md(filename)
    if (header):
        headers = yaml.load(header)  # 'headers' is now a python object containing the header fields
        

    # insert the title from the header
    if (headers and headers['title'] and add_title):
        sec_title = "# " + headers['title']
        body = '\n'.join([sec_title, body])

    done = subprocess.run(['kramdown', '--output', 'latex'], input=body, text=True, capture_output=True)

    return headers, done.stdout


def assemble_parts(config):
    parts = config[TAG_PARTS]
    if TAG_NO_TITLE in config:
        no_titles = config[TAG_NO_TITLE]
    else:
        no_titles = []
    texts = []
    for p in parts:
        add_title = p not in no_titles
        headers, body = md_to_latex(os.path.join(config['basedir'], p), add_title=add_title)
        texts.append(body)
    return '\n'.join(texts)


def generate_doc():
    if (os.path.exists('_pdf.yml')):
        configs = read_yaml('_pdf.yml')

        for idx, config in enumerate(configs['pdf']):
            print("Processing PDF configuration %d:" % idx)
            pp.pprint(config)
            body = assemble_parts(config)
            tex = latex.generate(body, **config)
            filename = os.path.join(config['basedir'], config['filename'] + '.tex')
            print("Writing file %s" % filename)
            with open(filename, 'w') as f:
                f.write(tex)

def main():
    generate_doc()


if __name__ == "__main__":
    main()

