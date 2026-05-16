# Dockerfile for building and hosting ArcGIS Server on Linux
----

Note: This repository is EXPERIMENTAL! ESRI has not designed ArcGIS server in a stateful way so you can't really run it in containers like "cattle". It always requires a shared network folder if you want to run more than one, so this docker method has limited utility.

Run at your own risk.

## Setup

Before running the docker build, you'll need:

1. Installation package in the form of a .tar.gz, renamed to 'arcgisserver.tar.gz'
  * You can get that under the downloads section: https://my.esri.com/#/downloads
  * The package will come as a bundle with 'ArcGIS Enterprise (Linux)', 10.8 version
  * IMPORTANT! rename the file arcgisserver.tar.gz as the Dockerfile expects it.

2. ESRI license file in the form of a .prvc file, renamed to 'arcgisserver.prvc'
  * You can get that here: https://my.esri.com/#/authorizations
  * For 10.8 you'll want to go through the authorization process for 'ArcGIS Enterprise', and for license type choose 'ArcGIS Server', after that, you'll need to decide what level of arcgis server you need, we usually choose 'Advanced' over 'Basic'.


## Building and Running
