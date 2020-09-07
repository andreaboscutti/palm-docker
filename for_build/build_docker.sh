#!/usr/bin/env bash

image_tag="aevia/palm:1.0"

docker run repronim/neurodocker:0.7.0 generate docker -b ubuntu:16.04 -p apt --fsl version=6.0.3 --matlabmcr version=2018b --add-to-entrypoint "[ -d /input ] && cd /input" --add-to-entrypoint '/opt/palm-mcr/palm/for_redistribution_files_only/run_palm.sh /opt/matlabmcr-2018b/v95/ $@' --run "sed -i '\$d' \$ND_ENTRYPOINT" --copy mcr /opt/palm-mcr > Dockerfile

docker build -t ${image_tag} .
docker push ${image_tag}
