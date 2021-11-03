#!/bin/bash -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$DIR/.build"

docker build -t "$TAG" "$DIR/Dockerfile"

