#!/usr/bin/env bash

set -euxo pipefail

docker buildx build -f ./kd-iree-dev.Dockerfile -t kd-iree-dev .
docker tag kd-iree-dev:latest ghcr.io/krzysz00/kd-iree-dev:latest
docker push ghcr.io/krzysz00/kd-iree-dev:latest
