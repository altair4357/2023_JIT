#!/bin/bash

function read_resource_values() {
  local index=$1
  awk -v i="$index" -F, 'NR==i+1 {print $2, $3, $4, $5}' c-ray-resources.csv
}

function create_pod_yaml() {
  local index=$1
  local cpu_request=$2
  local cpu_limit=$3
  local memory_request=$4
  local memory_limit=$5

  cat <<EOF >c-ray-${index}.yaml
apiVersion: v1
kind: Pod
metadata:
  name: c-ray
spec:
  nodeName: node01
  containers:
  - name: c-ray-${index}
    image: altair4357/2023paper:c-ray
    command: ["/bin/sh"]
    args: ["-c", "sleep 3600"]
    resources:
      requests:
        cpu: ${cpu_request}
        memory: ${memory_request}
      limits:
        cpu: ${cpu_limit}
        memory: ${memory_limit}
EOF
}

function run_test() {
  local index=$1
  local yaml_file="c-ray-${index}.yaml"

  echo "===${index}==="
  kubectl apply -f ${yaml_file} --wait

  sleep 60s

  kubectl exec -i -t c-ray -- sh ./phoronix_test.sh >> c-ray-result.txt & wait $!

  kubectl delete pod c-ray --wait

  sleep 60s

  echo "===${index} result ==="
  cat c-ray-result.txt | grep Average
}

for i in {1..13}; do
  read -r cpu_request cpu_limit memory_request memory_limit <<< "$(read_resource_values "$i")"
  create_pod_yaml "$i" "$cpu_request" "$cpu_limit" "$memory_request" "$memory_limit"
  run_test "$i"
done
