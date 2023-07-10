#!/bin/bash

yaml_file=$1
if [[ -z "${yaml_file}" ]]; then
  echo "Usage: $0 <yaml-file>"
  exit 1
fi

base_name="${yaml_file%.yaml}"
IFS="_" read -ra parts <<< "${base_name}"
test_type="${parts[0]}"
test_name="${parts[1]}"

result_file="${test_type}_${test_name}-result.txt"

run_test() {
  local index=$1

  echo "===RUN ${index} start==="

  kubectl apply -f "${yaml_file}" --wait

  # Check the pod's status and wait until it's Running
  pod_status="ContainerCreating"
  while [[ ${pod_status} != "Running" ]]; do
    sleep 5s
    pod_status=$(kubectl get pod "${test_name}" -o jsonpath='{.status.phase}')
  done

  kubectl exec -i -t "${test_name}" -- sh ./phoronix_test.sh >> "${result_file}" & wait $!

  kubectl delete pod "${test_name}" --wait

  echo "===Run ${index} end==="
  echo " "
  sleep 60s
}

for i in {1..13}; do
  run_test ${i}
done

cat "${result_file}" | grep Average

