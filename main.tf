terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.31.0"
    }
  }
}
# Configure the Hetzner Cloud provider
provider "hcloud" {
  token = "var.token"
}


resource "hcloud_server" "my_server" {
  name        = "gitserver"
  image       = "ubuntu-22.04"
  server_type = "cx11"
  ssh_keys    = ["mbaykara@mbmbaykara-1.sva.de"]

}

output "server_ip" {
  value = hcloud_server.my_server.ipv4_address

}
