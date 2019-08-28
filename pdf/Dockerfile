FROM python:3-slim

# Install pdflatex
RUN apt-get update && \
  apt-get install -y texlive-latex-base texlive-latex-extra ruby && \
  gem install kramdown && \
  pip install ruamel.yaml && \
  apt-get clean


