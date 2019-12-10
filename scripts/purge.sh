#!/usr/bin/env sh
#
# Delete Docker Hub Image Tag
# https://github.com/ashenm/workspace
#
# Ashen Gunaratne
# mail@ashenm.ml
#

# errexit
set -e

# script reference
SELF="$(basename $0)"

# default parameters
DOCKER_IMAGE="ashenm/shell"
EXCLUDES="latest developer"

# parse arguments
while [ $# -ne 0 ]
do

  case "$1" in

    --username)
      DOCKER_USERNAME="${2:?Invalid USERNAME}"
      shift 2
      ;;

    --password)
      DOCKER_PASSWORD="${2:?Invalid PASSWORD}"
      shift 2
      ;;

    -*|--*)
      echo >&2 "${SELF}: Invalid option $1"
      exit 1
      ;;

    *)
      DOCKER_IMAGE="$1"
      shift
      ;;

  esac

done

# ensure credentials
test -z "$DOCKER_USERNAME" || test -z "$DOCKER_PASSWORD" || \
  test -z "GITHUB_TOKEN" && { echo >&2 "${SELF}: Missing credentials"; exit 1; }

cat <<EOF

     Docker Hub Image Tags
================================
EOF

# fetch active image tags
curl --fail --silent --show-error --url "https://hub.docker.com/v2/repositories/ashenm/workspace/tags" | \
  jq --raw-output '.results[].name' | tee /tmp/tags

cat <<EOF

    GitHub Active Branches
================================
EOF

# fetch active git branches
curl --fail --silent --show-error --header "Authorization: token $GITHUB_TOKEN" \
  --url "https://api.github.com/repos/${DOCKER_IMAGE}/branches" | jq --raw-output '.[].name' | tee /tmp/upstreams

cat <<EOF

   Docker Hub Image Deletions
================================
EOF

# fetch token
DOCKER_TOKEN=$(curl --fail --silent --request POST --header "Content-Type: application/json" --url "https://hub.docker.com/v2/users/login/" \
  --data "{\"username\": \"$DOCKER_USERNAME\", \"password\": \"$DOCKER_PASSWORD\"}" | jq --raw-output '.token')

# ensure successful authentication
test -z "$DOCKER_TOKEN" || test "$DOCKER_TOKEN" = "null" && {
  echo >&2 "${SELF}: Authentication failed"; exit 1; }

while read -r TAG; do

  # ignore active branch deployments
  test "$(grep --count --extended-regexp "^$TAG$" /tmp/upstreams)" -ge 1 && \
    continue

  # ignore exclusions
  test "$(echo $EXCLUDES | grep --count --extended-regexp "$TAG")" -eq 1 && {
    echo "${TAG}\t\t[Skipped]"; continue; }

  # attempt deletion
  curl --silent --show-error --fail-early --request DELETE --header "Authorization: JWT $DOCKER_TOKEN" \
    --url "https://hub.docker.com/v2/repositories/${DOCKER_IMAGE}/tags/${TAG}/"

  echo "${TAG}\t\t[OK]"

done < /tmp/tags

# cleanup
rm --force /tmp/tags /tmp/upstreams

# vim: set expandtab shiftwidth=2 syntax=sh:
