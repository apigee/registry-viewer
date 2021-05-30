FROM dart:stable as builder
RUN apt-get update
RUN apt-get install unzip make curl -y

WORKDIR /app

COPY ./tools/FETCH-PROTOC.sh FETCH-PROTOC.sh
RUN ./FETCH-PROTOC.sh
RUN dart pub global activate protoc_plugin

COPY . ./
RUN make protos
RUN cd apps/reg; pub get; make

FROM debian:buster
RUN apt-get update
RUN apt-get install git -y

COPY --from=builder /app/apps/reg/reg /bin

