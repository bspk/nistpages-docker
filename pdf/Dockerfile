FROM ruby:slim AS gembuilder

## add gem directory
RUN mkdir /usr/local/kramdown_latexnist
ADD ./kramdown_latexnist /usr/local/kramdown_latexnist
WORKDIR /usr/local/kramdown_latexnist

## build gem

RUN gem build kramdown-latexnist.gemspec

## later: copy gem from firs step

FROM python:3-slim

# Install latex, ruby, and extra tools

RUN apt-get update && \
  apt-get install -y texlive-latex-base texlive-latex-extra ruby ghostscript texlive-font-utils texlive-fonts-extra && \
  apt-get clean

# Copy our utility files
RUN mkdir /opt/pdf
ADD ./kramdown-latexnist ./preprocess-pdf.py /opt/pdf/

# Copy our custom library

RUN mkdir /usr/local/kramdown_latexnist
COPY --from=gembuilder /usr/local/kramdown_latexnist/kramdown-latexnist-*.gem /usr/local/kramdown_latexnist/

# Install libraries

RUN gem install kramdown && \
  gem install --local /usr/local/kramdown_latexnist/kramdown-latexnist-*.gem && \
  pip install ruamel.yaml jinja2
