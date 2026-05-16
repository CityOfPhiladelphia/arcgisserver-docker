docker run -d \
  --name arcgis-single-node \
  --hostname arcgis-server \
  -p 6443:6443 \
  -p 6080:6080 \
  -v /mnt/efs/arcgis/directories:/home/arcgis/server/usr/directories \
  -v /mnt/efs/arcgis/config-store:/home/arcgis/server/usr/config-store \
  -e ARCGIS_ADMIN_USER=siteadmin
  -e ARCGIS_ADMIN_PASS=apassword
  ags:latest
