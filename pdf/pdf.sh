#!/bin/sh

cp -rv /opt/source/* /opt/work/

python /opt/pdf/preprocess-pdf.py

find . -name '*.tex' -print

find . -name '*.tex' -exec 'pdflatex' '{}' ';'

find . -name '*.aux' -exec 'bibtex' '{}' ';'

find . -name '*.tex' -exec 'pdflatex' '{}' ';'

find . -name '*.tex' -exec 'pdflatex' '{}' ';'

find . -name '*.pdf' -exec 'cp' '{}' /opt/source/ ';'
