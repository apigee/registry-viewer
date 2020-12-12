#!/bin/bash
#
# Copyright 2020 Google LLC. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Compile .proto files into the files needed to build the registry viewer.
#

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
