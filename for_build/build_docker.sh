#!/usr/bin/env bash

image_tag="andreaboscutti/palm:5.0"

docker run repronim/neurodocker:latest generate docker \
  --base-image ubuntu:20.04 \
  --pkg-manager apt \
  --yes
  --fsl version=6.0.7 \
  --matlabmcr version=2021b \
  --copy ./startup.sh /opt/startup.sh \
  --copy ./mcr /opt/palm-mcr \
  --entrypoint /opt/startup.sh > Dockerfile

sed -i '/multiarch-support/d' Dockerfile

docker build -t ${image_tag} .
docker push ${image_tag}
