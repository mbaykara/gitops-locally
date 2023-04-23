## GitOps Locally

This is a sample example how to setup GitOps locally in few minutes.

### Prerequisites

- A Linux machine
- Access to the internet
- Root or sudo privileges

### Tools

- K3S or kind or kds or minikube(I am using k3s for this demo)
- Flux V2
- Docker (not strictly necessary if you have prebuilt image and stored ssh keys)

## Summary

The `start.sh` script sets up a GitOps workflow using k3s and FluxCD. It installs docker.io and k3s, generates SSH keys, builds and pushes a Docker image to Docker Hub, creates a Kubernetes secret, updates the deployment file, and bootstraps Flux by cloning a Git repository from local git instance also running in same cluster.

#### Clone the repository:

The script uses `eval "$(ssh-agent -s)"` and `ssh-add` commands to add the private key to the agent and clones the repository.
