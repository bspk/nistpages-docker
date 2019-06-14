#!/bin/sh


if [[ "$1" == "" ]]
then
  cmd=build
else
  cmd="$1"
fi

# echo $cmd

jekyll "$cmd" --config /site/site-defaults.yml,_config.yml,/site/site-overrides.yml --safe --verbose --trace --destination /srv/jekyll/_site
