#!/bin/bash
# Check if /input exists. If so, cd into it.
if [ -d /input ]; then
  cd /input
fi
# Execute the PALM script with MATLAB Runtime
/opt/palm-mcr/palm/for_redistribution_files_only/run_palm.sh /opt/MCR-2021b/v911 "$@"
