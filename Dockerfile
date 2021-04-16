FROM debian:10-slim

Maintainer Roland
LABEL arcgisserver for Citygeo

# These are required files.
ADD ./arcgisserver.tar.gz /tmp/arcgisserver/
COPY ./arcgisserver.prvc /tmp/arcgisserver.prvc

# Force apt-get to use ipv4, ipv6 as always causes problems
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# procps gives us pgrep which the arcig server start script requires
# /arcgis/server/startserver.sh
RUN apt-get update -y && \
    apt-get install apt-utils -y && \
    apt-get install -y iproute2 procps vim tar hostname gettext locales && \
    apt-get clean

# Arcgisserver requires a properly set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8 

# The value below is a default if hostname is not declared through the --build-arg flag.
ARG hostname=arcgis-server.default.com
# Because of limitations with the hosts file in docker, we have to force
# arcgisserver to use the hostname we want by replacing the hostname binary
RUN mv /bin/hostname /bin/hostname.bkp; \
  echo "echo ${hostname}" > /bin/hostname; \
  chmod +x /bin/hostname

# Arcgisserver user and directory dependencies.
RUN groupadd arcgis && \
    useradd -m -r arcgis -g arcgis && \
    mkdir -p /arcgis/server && \
    chown -R arcgis:arcgis /arcgis && \
    chown -R arcgis:arcgis /tmp && \
    chmod -R 755 /arcgis

# File limits because Java is hungry
RUN echo -e "arcgis soft nofile 65535\narcgis hard nofile 65535\narcgis soft nproc 25059\narcgis hard nproc 25059" >> /etc/security/limits.conf

# Expose all these ports
EXPOSE 1098 4000 4001 4002 4003 4004 6006 6080 6099 6443

# The actual install.
USER arcgis
RUN /tmp/arcgisserver/ArcGISServer/Setup -m silent -l yes -a /tmp/arcgisserver.prvc -d /

# If your license doesn't work, the installer won't tell you.
# Manually attempt to authorize and then check if it worked, fail if it doesn't.
RUN /arcgis/server/tools/authorizeSoftware -f /tmp/arcgisserver.prvc && \
    /arcgis/server/tools/authorizeSoftware -s | grep "Not Authorized." && exit 1 || echo 0

# Remove setup files
RUN rm -rf /tmp/arcgisserver.tar.gz; \
    rm -rf /tmp/arcgisserver

# Run arcgisserver
CMD /arcgis/server/startserver.sh && tail -f /arcgis/server/framework/etc/service_error.log
