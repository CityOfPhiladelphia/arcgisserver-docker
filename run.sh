#!/bin/bash
set -e

PASSWORD='apassword'
sudo yum install -y nfs-utils

docker build -t ags .

docker stop ags 2>/dev/null || true
docker rm ags 2>/dev/null || true
docker volume rm arcgis-directories arcgis-config-store 2>/dev/null

# make sure the EFS network tab has an NFS 2049/TCP firewall rule
EFSDNS=<some-efs-dns-name>
docker volume create \
  --name arcgis-directories \
  --driver local \
  --opt type=nfs \
  --opt o=addr=$EFSDNS,rw,nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
  --opt device=:/arcgis/directories

docker volume create \
  --name arcgis-config-store \
  --driver local \
  --opt type=nfs \
  --opt o=addr=$EFSDNS,rw,nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
  --opt device=:/arcgis/config-store

docker run -d \
  --restart unless-stopped \
  --name ags \
  -p 6443:6443 \
  -p 6080:6080 \
  -e ARCGIS_ADMIN_USER=siteadmin \
  -e ARCGIS_ADMIN_PASS=$PASSWORD \
  -v arcgis-directories:/home/arcgis/server/usr/directories \
  -v arcgis-config-store:/home/arcgis/server/usr/config-store \
  ags:latest
