#!/bin/bash -e

# Source Swift config
source $(dirname $0)/../configs/swift.public.novarc

set -x

IMAGE_NAME=$1
# Timeout and sleep time in seconds
TIMEOUT=${2:-300}
SLEEP_TIME=5

staging_area=$(mktemp -d)

mkdir -p "${staging_area}/${IMAGE_NAME}"

touch "${staging_area}/${IMAGE_NAME}/lockfile.lock"

pushd "${staging_area}"

# check if the ${IMAGE_NAME}/lockfile.lock exists in the swift container
# if it does, wait until the timeout is reached and emit an error
# if it does not, upload the lockfile.lock to the swift container
# and exit
while [ $TIMEOUT -gt 0 ]; do
    swift list $SWIFT_CONTAINER_NAME -p $IMAGE_NAME | grep "lockfile.lock" && sleep $SLEEP_TIME || break
    TIMEOUT=$(( $TIMEOUT - $SLEEP_TIME ))
    if [ $TIMEOUT -eq 0 ]; then
        echo "Timeout reached while waiting for lockfile.lock to be removed from the swift container"
        exit 1
    fi
done

# SWIFT_CONTAINER_NAME comes from env
swift upload "$SWIFT_CONTAINER_NAME" "${IMAGE_NAME}"
