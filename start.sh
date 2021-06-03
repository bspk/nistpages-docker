#!/bin/sh


if [[ "$1" == "" ]]
then
  cmd=build
else
  cmd="$1"
fi

if [[ "$cmd" == "github" ]]
then
  # pre-process site directory for github
  mkdir /srv/jekyll/_site
  cmod 777 /srv/jekyll/_site
  cmd=build
fi

# echo $cmd

jekyll "$cmd" --config /site/site-defaults.yml,_config.yml,/site/site-overrides.yml --safe --verbose --trace --destination /srv/jekyll/_site
