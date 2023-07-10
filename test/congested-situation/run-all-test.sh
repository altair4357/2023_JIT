#!/bin/bash

# Check if the run-test.sh file exists.
if ! [[ -f run-test.sh ]]; then
  echo "The run-test.sh file does not exist. Please place the file in the current directory."
  exit 1
fi

# Process all YAML files passed as arguments.
for yaml_file in "$@"; do
  echo "Running test for ${yaml_file}"
  ./run-test.sh "${yaml_file}"
  echo "Finished test for ${yaml_file}"
  echo " "
done

