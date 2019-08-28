#!/bin/bash

echo -n 'Current version number: '
cat ./VERSION

read -p '    New version number: ' VERSION

echo $VERSION > ./VERSION

echo -n 'Release version number: '
cat ./VERSION

docker tag nistpages-build:latest jricher/nistpages-build:$VERSION
docker tag nistpages-dev:latest jricher/nistpages-dev:$VERSION
docker tag nistpages-pdf:latest jricher/nistpages-pdf:$VERSION
docker tag nistpages-build:latest jricher/nistpages-build:latest
docker tag nistpages-dev:latest jricher/nistpages-dev:latest
docker tag nistpages-pdf:latest jricher/nistpages-pdf:latest

docker push jricher/nistpages-build:$VERSION
docker push jricher/nistpages-dev:$VERSION
docker push jricher/nistpages-pdf:$VERSION
docker push jricher/nistpages-build:latest
docker push jricher/nistpages-dev:latest
docker push jricher/nistpages-pdf:latest
