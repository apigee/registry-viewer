#!/bin/sh
#
# Download dependencies needed to build the registry tools.
#

if [ ! -d "api-common-protos" ]
then
  git clone https://github.com/googleapis/api-common-protos
else
  echo "Using previous download of third_party/api-common-protos."
fi

if [ ! -d "gnostic" ]
then
  git clone https://github.com/google/gnostic
else
  echo "Using previous download of third_party/gnostic."
fi

if [ ! -d "registry" ]
then
  git clone https://github.com/apigee/registry
else
  echo "Using previous download of apigee/registry."
fi
