#!/bin/bash

# This points to the .proto files distributed with protoc.
export PROTOC="$HOME/local/include"

# This is a third_party directory containing .proto files used by many APIs.
export COMMON="../third_party/api-common-protos"

# This is a third_party directory containing the Registry API protos.
export REGISTRY="../third_party/registry"

mkdir -p lib/generated

echo "Generating dart support code."
protoc \
	--proto_path=${PROTOC} \
	--proto_path=${COMMON} \
	--proto_path=${REGISTRY} \
	${PROTOC}/google/protobuf/any.proto \
    ${PROTOC}/google/protobuf/timestamp.proto \
    ${PROTOC}/google/protobuf/field_mask.proto \
    ${PROTOC}/google/protobuf/empty.proto \
	${REGISTRY}/google/cloud/apigee/registry/v1alpha1/registry_models.proto \
	${REGISTRY}/google/cloud/apigee/registry/v1alpha1/registry_service.proto \
	--dart_out=grpc:lib/generated
