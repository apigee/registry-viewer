#!/bin/bash

# This points to the .proto files distributed with protoc.
export PROTOC="$HOME/local/include"

# This is a third_party directory containing .proto files used by many APIs.
export COMMON="third_party/api-common-protos"

# This is a third_party directory containing the Registry API protos.
export REGISTRY="third_party/registry"

# This is a third_party directory containing message protos used to store API metrics.
export GNOSTIC="third_party/gnostic"

mkdir -p registry/lib/generated 

echo "Generating Dart support code."
protoc \
	--proto_path=${PROTOC} \
	--proto_path=${COMMON} \
	--proto_path=${REGISTRY} \
	--proto_path=${GNOSTIC} \
	${PROTOC}/google/protobuf/any.proto \
	${PROTOC}/google/protobuf/timestamp.proto \
	${PROTOC}/google/protobuf/field_mask.proto \
	${PROTOC}/google/protobuf/empty.proto \
	${REGISTRY}/google/cloud/apigee/registry/v1alpha1/registry_models.proto \
	${REGISTRY}/google/cloud/apigee/registry/v1alpha1/registry_service.proto \
	${GNOSTIC}/metrics/complexity.proto \
	${GNOSTIC}/metrics/vocabulary.proto \
	--dart_out=grpc:registry/lib/generated
