# Dockerfile for building and hosting ArcGIS Server on Linux
----

This Dockerfile was developed using Docker version 19.03.2, build 6a30dfc, with the experimental flag enabled.

## Setup

Before running the docker build, you'll need:

1. Installation package in the form of a .tar.gz, renamed to 'arcgisserver.tar.gz'
  * You can get that under the downloads section: https://my.esri.com/#/downloads
  * The package will come as a bundle with 'ArcGIS Enterprise (Linux)', 10.8 version
  * IMPORTANT! rename the file arcgisserver.tar.gz as the Dockerfile expects it.

2. ESRI license file in the form of a .prvc file, renamed to 'arcgisserver.prvc'
  * You can get that here: https://my.esri.com/#/authorizations
  * For 10.8 you'll want to go through the authorization process for 'ArcGIS Enterprise', and for license type choose 'ArcGIS Server', after that, you'll need to decide what level of arcgis server you need, we usually choose 'Advanced' over 'Basic'.

3. Choose a hostname that you'll have a DNS record setup for (not necessary to have it during build).

## Building and Running

For the build command you'll be doing some special things.
 * --squash: to squash the docker image into a single layer, this should prevent the setup files that get removed at the end from being included in the total image size. ArcGIS Server is not light, and the image turns out to be around 11 GB in size with the setup file layer... don't want it any larger.
    --squash requires experimental features of Docker enabled, read: https://github.com/docker/cli/blob/master/experimental/README.md
 * --add-host: Pass your chosen hostname here, mapped to 127.0.0.1 so the arcgisserver install picks up on it.
 * --build-arg: You'll also pass the hostname here so we can force arcgisserver to use the hostname we want.

For the below command we're using citygeo-geocoder.phila.city as an example hostname, replace with your own.

```
docker build --squash \
    --add-host citygeo-geocoder.phila.city:127.0.0.1 \
    --build-arg hostname=citygeo-geocoder.phila.city \
    -t arcgisserver .
```

### Proxy considerations
Consult with our internal proxy article on how to deal with the web proxy and Docker. Docker also has documentation here:
https://docs.docker.com/network/proxy/

### Running
First on the host machine create two directories for storing config and other arcgis data. If you lose the container somehow, you should be able to recreate it with these folders:
```
mkdir -p ~/arcgis-docker/config-store
mkdir -p ~/arcgis-docker/arcgis-directories
```

Then to run the container:
```
docker run -d \
    --name arcgisserver \
    --hostname citygeo-geocoder.phila.city \
    -p 6080:6080 \
    -p 6443:6443 \
    -v ~/arcgis-docker/config-store:/arcgis/server/usr/config-store \
	-v ~/arcgis-docker/arcgis-directories:/arcgis/server/usr/directories \
    arcgisserver:latest
```

ArcGIS Server can then be configured at these URLs:
 * https://citygeo-geocoder.phila.city:6443/arcgis/manager/
 * https://<ip_address>:6443/arcgis/manager/

ArcGIS Server and administered here:
 * https://citygeo-geocoder.phila.city:6443/arcgis/admin
 * https://<ip_address>:6443/arcgis/admin

## Migrating

If at some point you need to migrate your arcgisserver docker container to a different machine, follow these steps.

A freshly run ArcGIS server container does NOT recognize dragged and dropped config-store and arcgis-directories folders and run off them, when browsing to the manager URL it will act like the server is not joined and as if its' a fresh install. Attempting to create a new site will also fail until you perform the next step.

To get around that, you can simply delete ".site" folders that exist in various directories within the two volume-mounted folders. These appear to identify the install, and deleting them allows a new site creation to work. After that, you should see your old services. 

Here's a simple command to run in the top directory above the mounted folders to remove all the .site folders. Careful to run this command ONLY in the mounted folder!!
 
```find . -name '\.site' -exec rm -irf '{}' \;```

## Reverse proxy with Nginx
If you don't want users to have to enter in the port into the URL for a cleaner experience, then you can install a webserver to act as a front-end that proxies to arcgisserver as a backend.

ESRI offers their web-adaptor product to do this but it's a clunky fix using java and tomcat for what should be a simple solution. Nginx serves this role well.

An example vhost configuration can be found in the file nginx-vhost.conf
