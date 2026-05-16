#!/bin/bash

docker build -t ags .

docker volume create --driver local \
  --opt type=nfs4 \
  --opt o=addr=<efs-dns>,nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
  --opt device=:/arcgis/directories arcgis-directories

docker volume create --driver local \
  --opt type=nfs4 \
  --opt o=addr=<efs-dns>,nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
  --opt device=:/arcgis/config-store arcgis-config-store

docker run -d \
  --restart unless-stopped \
  --name ags \
  -p 6443:6443 \
  -p 6080:6080 \
  -e ARCGIS_ADMIN_USER=siteadmin \
  -e ARCGIS_ADMIN_PASS=apassword \
  -v arcgis-directories:/home/arcgis/server/usr/directories \
  -v arcgis-config-store:/home/arcgis/server/usr/config-store \
  ags:latest
