#!/bin/bash

# Defaults
OSRM_DATA_PATH=${OSRM_DATA_PATH:="/osrm-data"}
OSRM_DATA_LABEL=${OSRM_DATA_LABEL:="data"}
OSRM_GRAPH_PROFILE_CAR=${OSRM_GRAPH_PROFILE_CAR:="car"}
OSRM_GRAPH_PROFILE_FOOT=${OSRM_GRAPH_PROFILE_FOOT:="foot"}
OSRM_PBF_URL=${OSRM_PBF_URL:="http://download.geofabrik.de/europe/germany/berlin-latest.osm.pbf"}
OSRM_CREATE_CAR_GRAPH=${OSRM_CREATE_CAR_GRAPH:='no'}
OSRM_CREATE_FOOT_GRAPH=${OSRM_CREATE_FOOT_GRAPH:='no'}
OSRM_DOWNLOAD=${OSRM_DOWNLOAD:='no'}


_sig() {
  kill -TERM $child 2>/dev/null
}
trap _sig SIGKILL SIGTERM SIGHUP SIGINT EXIT


# Retrieve the PBF file

if [ "$OSRM_DOWNLOAD" = "yes" ]; then
  curl $OSRM_PBF_URL --create-dirs -o $OSRM_DATA_PATH/$OSRM_GRAPH_PROFILE_CAR/$OSRM_DATA_LABEL.osm.pbf
  mkdir $OSRM_DATA_PATH/$OSRM_GRAPH_PROFILE_FOOT
  cp $OSRM_DATA_PATH/$OSRM_GRAPH_PROFILE_CAR/$OSRM_DATA_LABEL.osm.pbf $OSRM_DATA_PATH/$OSRM_GRAPH_PROFILE_FOOT/$OSRM_DATA_LABEL.osm.pbf
fi

if [ "$OSRM_CREATE_CAR_GRAPH" = "yes" ]; then
  # Build the graph
  osrm-extract $OSRM_DATA_PATH/$OSRM_GRAPH_PROFILE_CAR/$OSRM_DATA_LABEL.osm.pbf -p /osrm-profiles/$OSRM_GRAPH_PROFILE_CAR.lua
  osrm-contract $OSRM_DATA_PATH/$OSRM_GRAPH_PROFILE_CAR/$OSRM_DATA_LABEL.osrm
fi

if [ "$OSRM_CREATE_FOOT_GRAPH" = "yes" ]; then
  # Build the graph
  osrm-extract $OSRM_DATA_PATH/$OSRM_GRAPH_PROFILE_FOOT/$OSRM_DATA_LABEL.osm.pbf -p /osrm-profiles/$OSRM_GRAPH_PROFILE_FOOT.lua
  osrm-contract $OSRM_DATA_PATH/$OSRM_GRAPH_PROFILE_FOOT/$OSRM_DATA_LABEL.osrm
fi


# Start serving requests
osrm-routed $OSRM_DATA_PATH/$OSRM_GRAPH_PROFILE_CAR/$OSRM_DATA_LABEL.osrm -p 5000 --max-table-size 1000 &
osrm-routed $OSRM_DATA_PATH/$OSRM_GRAPH_PROFILE_FOOT/$OSRM_DATA_LABEL.osrm -p 5001 --max-table-size 1000 &

child=$!
wait "$child"