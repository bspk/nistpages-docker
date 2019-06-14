FROM jekyll/jekyll

# these need to match the list in site-defaults.yml
RUN gem install jekyll-coffeescript \
  jekyll-commonmark-ghpages \
  jekyll-gist \
  jekyll-github-metadata \
  jekyll-paginate \
  jekyll-relative-links \
  jekyll-optional-front-matter \
  jekyll-readme-index \
  jekyll-default-layout \
  jekyll-titles-from-headings

ADD --chown=jekyll:jekyll runpages.sh site-defaults.yml site-overrides.yml /site/

EXPOSE 4000

ENTRYPOINT ["/site/runpages.sh"]

CMD ["serve"]