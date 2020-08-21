#!/bin/bash

pushd /opt/pdf/kramdown_latexnist/ && gem build kramdown-latexnist.gemspec && gem install kramdown-latexnist-0.0.0.gem && popd

