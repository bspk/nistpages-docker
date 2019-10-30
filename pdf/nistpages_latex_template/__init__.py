"""
1.tex

%  	Report Number - fill in Report Number sent to you (see info below)
%   DOI Statement - fill in DOI sent to you
%   Month Year - fill in Month and Year of Publication
    (above described in 2.tex)

2.tex

%	Author Order and Grouping. Always identify the primary author/creator first (s/he does not have to be a NIST author). For publications with multiple authors, group authors by their organizational affiliation. The organizational groupings and the names within each grouping should generally be ordered by decreasing level of contribution.
%	For non-NIST authors, list their city and state below their organization name.
%	For NIST authors, include the Division and Laboratory names (but do not include their city and state).

3.tex

Document content

(optional) Acknowledgements (described in 4.tex)

4.tex

Appendices (described in 4.tex)
Changelog (described in 4.tex)

5.tex

"""
import pkg_resources
from shutil import copyfile
import nistpages_latex_template.tags as t
name = "nistpages_latex_template"
import os


def readfile(file):
    with open(pkg_resources.resource_filename(name, file)) as f:
        text = f.read()
    return text


def author_block(author_data):
    text = '\\normalsize '
    for authors in author_data:
        text += authors[t.first_author] + '\\\\\n'
        if t.second_author in authors:
            text += authors[t.second_author] + '\\\\\n'

        text += '\\textit{' + authors[t.first_line] + '}\\\\\n'

        if t.second_line in authors:
            text += '\\textit{' + authors[t.second_line] + '}\\\\\n'

        text += '\\vspace{12pt}\\n'
    return text


def copy_files():
    os.makedirs('_pdfinclude', exist_ok=True)
    copyfile(pkg_resources.resource_filename(name, "DoC-logo-eps-converted-to.pdf"), "_pdfinclude/DoC-logo-eps-converted-to.pdf")
    copyfile(pkg_resources.resource_filename(name, "techpubs.bst"), "techpubs.bst")


def generate(content,
        report_number=None,
        doi_url=None,
        month=None,
        year=None,
        authors=None,
        **kwargs):
    """Take in LaTeX body with metadata and generate the LaTeX code using the NIST template

    :param report_number:
    :param doi_url:
    :param month:
    :param year:
    :param authors:
    :param content:
    :return: text that is ready to be compiled using LaTeX
    """
    if report_number is None or doi_url is None or month is None or year is None or authors is None or content is None:
        raise ValueError("Required values to generate PDF file not found.")

    copy_files()

    latex = readfile('1.tex')

    # Yes, these are escaped for Python! The desired latex output looks like \newcommand
    latex += '\\newcommand{\\pubnumber}{' + str(report_number) + '}\n'
    latex += '\\newcommand{\\DOI}{' + str(doi_url) + '}\n'
    latex += '\\newcommand{\\monthyear}{' + str(month) + ' ' + str(year) + '}\n'

    latex += readfile('2.tex')
    latex += author_block(authors)
    latex += readfile('3.tex')
    latex += content
    latex += readfile('4.tex')
    latex += readfile('5.tex')

    return latex



