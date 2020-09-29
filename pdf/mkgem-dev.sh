#!/bin/bash

pushd /opt/pdf/kramdown_latexnist/ && rm kramdown-latexnist-*.gem && gem build kramdown-latexnist.gemspec && gem install kramdown-latexnist-*.gem && popd

