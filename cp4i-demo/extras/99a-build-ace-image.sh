#!/bin/sh
# This script requires the oc command being installed in your environment 
if [ ! command -v podman &> /dev/null ]; then echo "oc could not be found"; exit 1; fi;
######################
# SET APIC VARIABLES #
######################
ACE_SIGNATURE='c45d6e2bb78f0bad4865d38b52117fe8f57e2ef6c17d434a67c63838eef22d2d'
ACE_VER='12.0.11.2-r1'
QUAYIO_ACCT='jgomezr'
echo "Getting ACEcc image..."
podman pull cp.icr.io/cp/appc/ace-server-prod@sha256:${ACE_SIGNATURE}
echo "Getting ACEcc image id..."
IMG_ID=$(podman images | awk '$1 ~ "cp.icr.io/cp/appc/ace-server-prod" {print $3}')
echo "Tagging ACEcc image with proper version..."
podman tag $IMG_ID cp.icr.io/cp/appc/ace-server-prod:${ACE_VER}
echo "Building ACE image with sample BAR file.."
podman build -t quay.io/jgomezr/ace-${ACE_VER}-jgrcp4i-aceivt:1.0.0 --build-arg ACEVER=$ACE_VER --file extras/ACE-IS-Dockerfile
echo "Pushing ACE image to Quay.io repository"
podman push quay.io/${QUAYIO_ACCT}/ace-${ACE_VER}-jgrcp4i-aceivt:1.0.0
echo "Done!"
