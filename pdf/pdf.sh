#!/bin/sh

python /opt/pdf/preprocess-pdf.py

pdflatex *.tex
pdflatex *.tex
