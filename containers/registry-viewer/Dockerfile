# This Dockerfile builds an image that runs the web server.

# Use the official Golang image to create a build artifact.
# This is based on Debian and sets the GOPATH to /go.
# https://hub.docker.com/_/golang
FROM golang:1.15 as builder

# Create and change to the app directory.
WORKDIR /app

# Retrieve application dependencies.
# This allows the container build to reuse cached dependencies.
COPY site/go.* ./
RUN go mod download

# Copy local code to the container image.
COPY site/cmd ./cmd

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
COPY site/public /public

# Run the web service on container startup.
CMD ["/web-server"]
