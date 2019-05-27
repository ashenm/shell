#!/usr/bin/env sh
# Spawn a new container for debugging

exec docker run --rm --tty --interactive --publish 3000:3000 "${TRAVIS_REPO_SLUG:-ashenm/shell}:${TRAVIS_BRANCH:-latest-alpha}"
