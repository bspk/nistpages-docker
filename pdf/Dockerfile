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
ARG TARGETPLATFORM
ARG BUILDPLATFORM

# Install latex, ruby, and extra tools

RUN apt-get update && \
  apt-get install -y ruby ghostscript gcc musl-dev python3-dev&& \
  apt-get clean

  # Install Texlive: latest release.
  # Based on: (Yet another) Texlive Docker image
  # https://github.com/YtoTech/docker-texlive
  # By: Yoan Tournade yoan@ytotech.com
  # Itself based on :
  # - https://www.tug.org/texlive/quickinstall.html
  # - https://tex.stackexchange.com/questions/1092/how-to-install-vanilla-texlive-on-debian-or-ubuntu

  # install-tl dependencies.
  # GPG is for tlmgr installation source verifications.
  RUN apt-get update -qq && apt-get install -y \
      wget \
      libswitch-perl \
      gnupg \
      && apt-get clean && rm -rf /var/lib/apt/lists/*

  COPY ./texlive.profile /tmp/

  # get the texlive installer
  RUN cd /tmp && wget -qO- https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz | tar xz

  # Install based on platform
  #  Also creates symlinks to common binaries directory
  RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
  /tmp/install-tl*/install-tl -profile /tmp/texlive.profile --paper=letter --no-interaction --no-doc-install --no-src-install --force-platform x86_64-linux \
  && ln -s /usr/local/texlive/bin/x86_64-linux/* /usr/local/texlive/bin/; \
  elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
  /tmp/install-tl*/install-tl -profile /tmp/texlive.profile --paper=letter --no-interaction --no-doc-install --no-src-install --force-platform aarch64-linux \
  && ln -s /usr/local/texlive/bin/aarch64-linux/* /usr/local/texlive/bin/; \
  else \
  exit 10; \
  fi

  # remove texlive installer
  RUN rm -rf /tmp/install-tl-*

  # Add Texlive binaries to path.
  # AMD64 and ARM64 platforms install binaries in different directories
  # /usr/local/texlive/bin/x86_64-linux and /usr/local/texlive/bin/aarch64-linux
  # This adds the path containing symlinks to those directories
  ENV PATH="/usr/local/texlive/bin:${PATH}"

# Install libraries under ruby (gem) and python (pip)
RUN pip install --upgrade pip

RUN gem install kramdown rcapture && \
  pip install ruamel.yaml jinja2 psutil

# Copy our utility files from the source directory
ADD ./pdf/kramdown-latexnist ./pdf/preprocess-pdf.py /opt/pdf/

# Copy our custom library from the first stage

COPY --from=gembuilder /usr/local/kramdown_latexnist/kramdown-latexnist-*.gem /usr/local/kramdown_latexnist/

# Install our custom kramdown library

RUN  gem install --local /usr/local/kramdown_latexnist/kramdown-latexnist-*.gem
