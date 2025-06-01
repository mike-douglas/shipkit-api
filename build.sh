#!/bin/sh

docker buildx build --platform linux/amd64,linux/arm64 --push -t ghcr.io/mike-douglas/shipkit-api:stage .

# Tried this one last
docker build --platform linux/amd64 --push -t ghcr.io/mike-douglas/shipkit-api:stage .