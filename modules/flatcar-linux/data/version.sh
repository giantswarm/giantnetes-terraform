#!/bin/sh

set -e

if [ ! "$(command -v jq)" ]; then
  echo "jq is not installed."
  exit 1
fi

eval "$(jq -r '@sh "FLATCAR_CHANNEL=\(.flatcar_channel) FLATCAR_VERSION=\(.flatcar_version) AWS_REGION=\(.aws_region)"')"

if [ "$FLATCAR_VERSION" = "latest" ]; then
  if [ "$AWS_REGION" != "cn-north-1" ] && [ "$AWS_REGION" != "cn-northwest-1" ]; then
    version=$(curl -s https://"$FLATCAR_CHANNEL".release.flatcar-linux.net/amd64-usr/current/version.txt | sed -n 's/FLATCAR_VERSION=\(.*\)$/\1/p')
  else
    version=$(curl -s https://flatcar-prod-ami-import-cn-north-1.s3.cn-north-1.amazonaws.com.cn/version.txt | sed -n 's/FLATCAR_VERSION=\(.*\)$/\1/p')
  fi
else
  version="$FLATCAR_VERSION"
fi

jq -n --arg version "$version" '{"flatcar_version": $version}'
