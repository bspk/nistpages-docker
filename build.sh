#!/bin/sh


# build the static base file

docker build -t nistpages-build -f Dockerfile.build .

docker build -t nistpages-dev -f Dockerfile.dev .

docker build -t nistpages-pdf pdf/

