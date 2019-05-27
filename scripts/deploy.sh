#!/usr/bin/env sh
# Deploy Image to hub.docker.com

set -e

# authenticate
echo "${DOCKER_PASSWORD}" \
  | docker login --username "${DOCKER_USERNAME}" --password-stdin

# deploy image
docker push "${TRAVIS_REPO_SLUG:-ashenm/shell}:${TRAVIS_BRANCH:-latest-alpha}"
