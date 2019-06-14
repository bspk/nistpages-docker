# NIST Pages Development Support

This project helps developers and content editors create content for [NIST Pages](https://pages.nist.gov/), the online documentation publication system for [NIST](https://nist.gov/). 

The files here are used to create and publish Docker images based on [Jekyll](https://jekyllrb.com/)'s static site development program, but configured specially for use with NIST Pages. These Docker images allow for the creation of the static site content as well as live generation and local hosting of the site during development and editing. 

To use these utilities, you must have both `Docker` and `Docker Compose` installed on your system.

## Developing Content on a Local Server

Copy the `docker-compose.yml` file from this repository to your source directory and run the command `docker-compose up`. This will start a server on `http://localhost:4000` serving your content under whatever path you have set in `baseurl` inside your projects `_config.yml` file, which is loaded automatically by the system. So for example, with `baseurl` set to `800-0-0`, the content would be served on `http://localhost:4000/800-0-0/`. 

The project directory is watched by Jekyll as long as the server is running, and the site content is regenerated if anything changes. 

Be sure to add `docker-compose.yml` to the `exclude` list in `_config.yml`, otherwise it will be copied to your site's output folder.

## Generating Static Content for Publication

To generate the site content statically without serving it, use the docker run command directly from your project:

`docker run --rm --mount type=bind,source="$(pwd)",target=/srv/jekyll jricher/nistpages-build:latest`

This command tells docker to run the `nistpages-build` image, which builds the site using Jekyll, and mount the current directory into Jekyll's work directory in the container. The results are contained in `_site` under the current directory. Keep in mind that they are intended to be served based on the `baseurl` property in your `_config.yml` file, and so local viewing of these files without the appropriate web server will likely yield unwanted results.

## Building the Docker Images

The Docker images for both building and developing NIST Pages sites can be updated using the script

`./build.sh`

This will create two new docker images on your system, `nistpages-build` and `nistpages-dev`. 

To release these images to Docker Hub, use the script

`./release.sh`

For this script to work, you will need to be authenticated to Docker Hub and your account will need write permissions to the hosted repository.