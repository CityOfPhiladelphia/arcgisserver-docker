FROM ubuntu:20.04

LABEL arcgisserver for Citygeo

ENV DEBIAN_FRONTEND=noninteractive

# Install required system dependencies for ArcGIS Server
RUN apt-get update && apt-get install -y \
    net-tools \
    gettext \
    locales \
    libfontconfig1 \
    libgl1-mesa-glx \
    libxi6 \
    libxrender1 \
    libxtst6 \
    xvfb \
    tar \
    gzip \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN groupadd -g 1000 arcgis && \
    useradd -u 1000 -g arcgis -m -d /home/arcgis arcgis

COPY --chown=arcgis:arcgis ArcGISGISServerAdvanced_ArcGISServer_1614027.prvc /home/arcgis/server115.prvc

# File limits because Java is hungry
RUN echo -e "arcgis soft nofile 65535\narcgis hard nofile 65535\narcgis soft nproc 25059\narcgis hard nproc 25059" >> /etc/security/limits.conf


USER arcgis
WORKDIR /home/arcgis

# Bind-mount the tarball directly from your host context. 
# It never becomes a Docker layer, and we clean up the extracted files in the same RUN command.
RUN --mount=type=bind,source=ArcGIS_Server_Linux_115_195440.tar.gz,target=/tmp/arcgisserver.tar.gz \
    mkdir -p /tmp/arcgis && \
    tar -xvf /tmp/arcgisserver.tar.gz -C /tmp/arcgis/ && \
    /tmp/arcgis/ArcGISServer/Setup -m silent -l yes -a /home/arcgis/server115.prvc && \
    rm -rf /tmp/arcgis

# Copy the startup script into the container
COPY --chown=arcgis:arcgis entrypoint.sh /home/arcgis/entrypoint.sh

# Ensure the script is executable
RUN chmod +x /home/arcgis/entrypoint.sh

#CMD ["/bin/bash", "-c", "/home/arcgis/server/startserver.sh && sleep 15 && tail -f /home/arcgis/logs.txt"]
CMD ["/home/arcgis/entrypoint.sh"]
