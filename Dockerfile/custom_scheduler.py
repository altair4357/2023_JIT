import os
import random
import time

from kubernetes import client, config

def main():
    try:
        config.load_incluster_config()
    except config.ConfigException:
        try:
            config.load_kube_config()
        except config.ConfigException:
            raise RuntimeError("Cannot load Kubernetes configuration")
    api = client.CoreV1Api()
    
    while True:
        custom_scheduler(api)
        time.sleep(30) # Set the scheduler to run every 30 seconds

def get_nodes(api):
    nodes = api.list_node()
    return nodes.items

def custom_scheduler(api):
    namespace = "default"
    pods = api.list_namespaced_pod(namespace)
    nodes = get_nodes(api)

    for pod in pods.items:
        target_pod_name, cpu_request, memory_request = get_pod_resources(pod)

        if target_pod_name and (pod.metadata.labels is None or "custom_scheduler" not in pod.metadata.labels):

            node01 = find_node01(nodes)
            new_pod = create_new_pod(pod, cpu_request, memory_request, node01)
            delete_old_pod(api, pod)
            deploy_new_pod(api, new_pod, namespace)

def find_node01(nodes):
    for node in nodes:
        if node.metadata.name == "node01":
            return node
    raise RuntimeError("node01 not found in the cluster")

def get_pod_resources(pod):
    if 'tensorflow-lite' in pod.metadata.name:
        return "tensorflow-lite", "5969m", "17621Mi"
    elif 'blender' in pod.metadata.name:
        return "blender", "5909m", "15318Mi"
    elif 'build-imagemagick' in pod.metadata.name:
        return "build-imagemagick", "5969m", "18484Mi"
    elif 'c-ray' in pod.metadata.name:
        return "c-ray", "6030m", "30000Mi"
    elif 'build-apache' in pod.metadata.name:
        return "build-apache", "5909m", "7833Mi"
    else:
        print("The Pod name is not valid")
        return None, None, None

def create_new_pod(pod, cpu_request, memory_request, random_node):
    new_pod_metadata = client.V1ObjectMeta(
        name=pod.metadata.name,
        namespace=pod.metadata.namespace,
        labels={"custom_scheduler": pod.metadata.name},
        annotations=pod.metadata.annotations,
        owner_references=pod.metadata.owner_references
    )

    new_pod = client.V1Pod(metadata=new_pod_metadata, spec=pod.spec)

    new_pod.spec.containers[0].resources = client.V1ResourceRequirements(
        requests={"cpu": cpu_request, "memory": memory_request}
    )

    new_pod.spec.node_name = random_node.metadata.name

    return new_pod

def delete_old_pod(api, pod):
    api.delete_namespaced_pod(name=pod.metadata.name, namespace=pod.metadata.namespace, body=client.V1DeleteOptions())

def deploy_new_pod(api, new_pod, namespace):
    api.create_namespaced_pod(namespace=namespace, body=new_pod)

if __name__ == "__main__":
    main()
