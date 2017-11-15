FROM ubuntu:xenial

MAINTAINER Alex Pardo <alex.pardo@whabtech.com>

ENV OSRM_VERSION 5.7.0-latest.6

# Let the container know that there is no TTY
ENV DEBIAN_FRONTEND noninteractive

# Params
ENV OSRM_DATA_PATH /osrm-data
ENV OSRM_DATA_LABEL data
ENV OSRM_GRAPH_PROFILE_CAR car
ENV OSRM_GRAPH_PROFILE_FOOT foot
# ENV OSRM_PBF_URL http://download.geofabrik.de/europe/germany/berlin-latest.osm.pbf
ENV OSRM_PBF_URL http://download.geofabrik.de/europe/spain-latest.osm.pbf
ENV OSRM_CREATE_CAR_GRAPH no
ENV OSRM_CREATE_FOOT_GRAPH no
ENV OSRM_DOWNLOAD no

# Install packages
RUN apt-get -y update \
 && apt-get install -y -qq --no-install-recommends \
    build-essential \
    cmake \
    curl \
    ca-certificates \
    libbz2-dev \
    libstxxl-dev \
    libstxxl1v5 \
    libxml2-dev \
    libzip-dev \
    libboost-all-dev \
    lua5.2 \
    liblua5.2-dev \
    libtbb-dev \
    libluabind-dev \
    pkg-config \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/* /var/tmp/*

# Build osrm-backend
RUN mkdir /osrm-src \
 && cd /osrm-src \
 && curl --silent -L https://github.com/Project-OSRM/osrm-backend/archive/v$OSRM_VERSION.tar.gz -o v$OSRM_VERSION.tar.gz \
 && tar xzf v$OSRM_VERSION.tar.gz \
 && cd osrm-backend-$OSRM_VERSION \
 && mkdir build \
 && cd build \
 && cmake .. -DCMAKE_BUILD_TYPE=Release \
 && cmake --build . \
 && cmake --build . --target install \
 && mkdir /osrm-data \
 && mkdir /osrm-profiles \
 && cp -r /osrm-src/osrm-backend-$OSRM_VERSION/profiles/* /osrm-profiles \
 && rm -rf /osrm-src



VOLUME /osrm-data
VOLUME /osrm-profiles

EXPOSE 5000 5001

# Set the entrypoint
COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
