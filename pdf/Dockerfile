FROM ruby:slim AS gembuilder

## add gem directory
RUN mkdir /usr/local/kramdown_latexnist
ADD ./pdf/kramdown_latexnist /usr/local/kramdown_latexnist
# Clean out existing gems from build
RUN rm -vf /usr/local/kramdown_latexnist/kramdown-latexnist-*.gem
WORKDIR /usr/local/kramdown_latexnist

## build gem

RUN gem build kramdown-latexnist.gemspec

## Second stage: Build out our runtime image and copy gem from first step

FROM python:3-slim

# Install latex, ruby, and extra tools

RUN apt-get update && \
  apt-get install -y \
  ruby \
  ghostscript \
  wget \
  libswitch-perl \
  gnupg \
  && apt-get clean && rm -rf /var/lib/apt/lists/*
  
# Install Texlive: latest release.
# Based on: (Yet another) Texlive Docker image
# https://github.com/YtoTech/docker-texlive
# By: Yoan Tournade yoan@ytotech.com
# Itself based on :
# - https://www.tug.org/texlive/quickinstall.html
# - https://tex.stackexchange.com/questions/1092/how-to-install-vanilla-texlive-on-debian-or-ubuntu

COPY ./texlive.profile /tmp/
RUN cd /tmp && wget -qO- https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz | tar xz \
    && /tmp/install-tl*/install-tl -profile /tmp/texlive.profile \
    && rm -rf /tmp/install-tl-*
    
# Add Texlive binaries to path.
ENV PATH="/usr/local/texlive/bin/x86_64-linux:${PATH}"  

# Install libraries under ruby (gem) and python (pip)

RUN gem install kramdown rcapture && \
  pip install ruamel.yaml jinja2

# Copy our utility files from the source directory
ADD ./pdf/kramdown-latexnist ./pdf/preprocess-pdf.py /opt/pdf/

# Copy our custom library from the first stage

COPY --from=gembuilder /usr/local/kramdown_latexnist/kramdown-latexnist-*.gem /usr/local/kramdown_latexnist/

# Install our custom kramdown library

RUN  gem install --local /usr/local/kramdown_latexnist/kramdown-latexnist-*.gem
