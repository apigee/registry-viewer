# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This Dockerfile builds an image that runs the web server.
ARG FLUTTER_VERSION=3.3.10
ARG PROTOBUF_VERSION=3.20.1
ARG GO_VERSION=1.18

FROM ubuntu:latest as flutter
ARG FLUTTER_VERSION
ARG PROTOBUF_VERSION

ENV PATH "$PATH:/flutter/bin:/flutter/.pub-cache/bin"

WORKDIR /app

COPY . ./

RUN apt-get update -y && apt-get install curl unzip xz-utils git make -y && \
    PB_REL="https://github.com/protocolbuffers/protobuf/releases" && \
    curl -LO $PB_REL/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip && \
    unzip protoc-${PROTOBUF_VERSION}-linux-x86_64.zip -d /usr/local

RUN curl -LO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz && \
    tar -xf flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -C / && \
    git config --global --add safe.directory /flutter && \
    flutter pub global activate protoc_plugin &&  \
    flutter config --enable-web && \
    make create && make protos && make staging

# Use the official Golang image to create a build artifact.
# This is based on Debian and sets the GOPATH to /go.
# https://hub.docker.com/_/golang
FROM golang:${GO_VERSION} as builder

# Create and change to the app directory.
WORKDIR /app

# Retrieve application dependencies.
# This allows the container build to reuse cached dependencies.
COPY site/go.* ./
RUN go mod download

# Copy local code to the container image.
COPY ./site/cmd ./cmd

# Build web-server.
RUN CGO_ENABLED=0 GOOS=linux go build -v -o web-server ./cmd/web-server

# Use the official Alpine image for a lean production container.
# https://hub.docker.com/_/alpine
# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
FROM alpine:3
RUN apk add --no-cache ca-certificates

# Copy the binary to the production image from the builder stage.
COPY --from=builder /app/web-server /web-server

# Copy site assets to the production image from the local directory.
# (if this fails, be sure that "public" isn't in .gitignore)
COPY --from=flutter /app/site/public /public

# Run the web service on container startup.
CMD ["/web-server"]
