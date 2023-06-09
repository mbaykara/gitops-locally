#!/bin/bash
set -euo pipefail

#Install docker
apt update && apt install -y docker.io
wait
#Install k3s
curl -sfL https://get.k3s.io | sh -
# Install Flux CLI
wait 
curl -s https://fluxcd.io/install.sh | sudo bash
wait 
echo "Deploy OCI registry"
kubectl create ns registry
kubectl apply -f container-registry.yaml
# Generate a timestamp for tagging the image and directory
timestamp=$(date +%d%m%y)

# Create a temporary directory for generating SSH keys
key_dir=$(mktemp -d --suffix="$timestamp")

# Generate SSH keys
ssh-keygen -t rsa -N "" -f "$key_dir/id_rsa"
alias k=kubectl
mkdir -p /root/.kube ./keys
cp $key_dir/* ./keys

kubectl wait --timeout=90s --for=condition=available deployment private-registry -n registry
registry_name=$(kubectl -n registry get pod -o=jsonpath='{.items[0].metadata.name}')
# Get the IP address of the pod
registry_ip=$(kubectl -n registry get pod "$registry_name" -o=jsonpath='{.status.podIP}')
echo "$registry_ip  registry" >>/etc/hosts
cat << EOF > /etc/docker/daemon.json 
{
  "insecure-registries": ["registry:5000"]
}
EOF
systemctl restart docker
wait

docker build -t "registry:5000/gitserver:$timestamp" .

# Push the Docker image to the Docker Hub
echo "docker push registry:5000/gitserver:$timestamp"
docker push registry:5000/gitserver:$timestamp
wait

# [ -d "/root/.kube" ] && echo "Directory exists" || sleep 10mkdir /root/.kube
cp /etc/rancher/k3s/k3s.yaml /root/.kube/config
export KUBECONFIG=/root/.kube/config
wait 
kubectl create ns flux-system
# Create a Kubernetes secret with the generated SSH key
kubectl -n flux-system create secret generic flux-git-key \
  --from-file="$key_dir/id_rsa" \
  --from-file="$key_dir/id_rsa.pub"
wait 

cat << EOF > /etc/rancher/k3s/registries.yaml
mirrors:
  "registry:5000":
    endpoint:
      - "http://registry:5000"
EOF
systemctl restart k3s
# Build a Docker image with the generated keys and tag it with the timestam
# Update the deployment file with the new image tag
sed -i "s/registry:5000\/gitserver:.*/registry:5000\/gitserver:$timestamp/" deployment-gitserver.yaml 
kubectl apply -f deployment-gitserver.yaml
kubectl wait --timeout=90s --for=condition=available deployment gitserver -n flux-system
 
# Get the name of the first pod in the cluster
pod_name=$(kubectl -n flux-system get pod -o=jsonpath='{.items[0].metadata.name}')
# Get the IP address of the pod
pod_ip=$(kubectl -n flux-system get pod "$pod_name" -o=jsonpath='{.status.podIP}')
echo "$pod_ip   gitserver" >>/etc/hosts
# Bootstrap Flux
flux bootstrap git \
  --url="ssh://git@gitserver/git-server/repos/cluster.git" \
  --branch=main \
  --path=clusters \
  --private-key-file=./keys/id_rsa

wait
####populate to ssh key order to clone repo###
echo "git clone ssh://git@gitserver/git-server/repos/cluster.git"
eval "$(ssh-agent -s)"
ssh-add $key_dir/id_rsa
