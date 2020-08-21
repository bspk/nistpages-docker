#!/bin/bash

echo -n 'Current version number: '
cat ./VERSION

read -p '    New version number: ' VERSION

# Save version in repo
echo $VERSION > ./VERSION
# Tag gem
sed -i '' "s/VERSION = \".*\"/VERSION = \"$VERSION\"/" pdf/kramdown_latexnist/lib/kramdown/latexnist/version.rb

echo -n 'Release version number: '
cat ./VERSION

# Rebuild

read -p "Rebuild images? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    ./build.sh
fi

read -p "Push release? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
	docker tag nistpages-build:latest jricher/nistpages-build:$VERSION;
	docker tag nistpages-dev:latest jricher/nistpages-dev:$VERSION;
	docker tag nistpages-pdf:latest jricher/nistpages-pdf:$VERSION;
	docker tag nistpages-build:latest jricher/nistpages-build:latest;
	docker tag nistpages-dev:latest jricher/nistpages-dev:latest;
	docker tag nistpages-pdf:latest jricher/nistpages-pdf:latest;

	docker push jricher/nistpages-build:$VERSION;
	docker push jricher/nistpages-dev:$VERSION;
	docker push jricher/nistpages-pdf:$VERSION;
	docker push jricher/nistpages-build:latest;
	docker push jricher/nistpages-dev:latest;
	docker push jricher/nistpages-pdf:latest;
fi

