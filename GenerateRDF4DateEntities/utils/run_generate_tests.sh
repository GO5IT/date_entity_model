#!/bin/bash

set ue
### run tests for all generate_xxx.pl
LIMIT=0

## the rest
for type in day month year decade century millenium; do
  script="generate_${type}_rdf.pl"
  if [ -x "$(command -v $script)" ]; then
     echo "$type ..."
     $script -l $LIMIT > sample_${type}.rdf
  else
    echo "not yet implemented: $type"
  fi
done
