#!/bin/bash

# Ensure the script exits if any command fails
set -e

# Execute each script in the specified order

bash blender-run.sh
bash c-ray-run.sh
bash build-imagemagick-run.sh
bash build-apache-run.sh
bash tensorflow-lite-run.sh

echo "All scripts executed successfully."
