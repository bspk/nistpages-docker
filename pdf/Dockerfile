FROM ruby:slim AS gembuilder

## add gem directory
RUN mkdir /usr/local/kramdown_latexnist
ADD ./pdf/kramdown_latexnist /usr/local/kramdown_latexnist
# Clean out existing gems from build
RUN rm -f /usr/local/kramdown_latexnist/kramdown-latexnist-*.gem
WORKDIR /usr/local/kramdown_latexnist

## build gem

RUN gem build kramdown-latexnist.gemspec

## Second stage: Build out our runtime image and copy gem from first step

FROM python:3-slim

# Install latex, ruby, and extra tools

RUN apt-get update && \
  apt-get install -y texlive-latex-base texlive-latex-extra texlive-font-utils texlive-fonts-extra \
     ruby ghostscript && \
  apt-get clean

# Install libraries under ruby (gem) and python (pip)

RUN gem install kramdown rcapture && \
  pip install ruamel.yaml jinja2

# Copy our utility files from the source directory
ADD ./pdf/kramdown-latexnist ./pdf/preprocess-pdf.py /opt/pdf/

# Copy our custom library from the first stage

COPY --from=gembuilder /usr/local/kramdown_latexnist/kramdown-latexnist-*.gem /usr/local/kramdown_latexnist/

# Install our custom kramdown library

RUN  gem install --local /usr/local/kramdown_latexnist/kramdown-latexnist-*.gem
