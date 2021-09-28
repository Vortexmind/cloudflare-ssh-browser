resource "digitalocean_project" "cloudflare_ssh_browser" {
  name        = "cloudflare-ssh-browser"
  description = "SSH via Browser"
  purpose     = "SSH Connection"
  environment = "Production"
  resources = [digitalocean_droplet.ssh_droplet.urn]
}

data "digitalocean_ssh_key" "default" {
  name       = var.digitalocean_key_name  
}

resource "digitalocean_droplet" "ssh_droplet" {
  image  = var.digitalocean_droplet_image
  name   = "cloudflare-ssh-broswer-droplet"
  region = var.digitalocean_droplet_region
  size   = var.digitalocean_droplet_size
  ssh_keys = [
    data.digitalocean_ssh_key.default.id
  ]
  user_data = templatefile("${path.module}/cloud-init/web-cloud-init.yaml", {
      account_id = var.cloudflare_account_id
      fqdn = local.cloudflare_fqdn
      cloudflare_tunnel_id = cloudflare_argo_tunnel.ssh_browser.id
      cloudflare_tunnel_name = cloudflare_argo_tunnel.ssh_browser.name
      cloudflare_tunnel_secret = cloudflare_argo_tunnel.ssh_browser.secret
      trusted_pub_key = cloudflare_access_ca_certificate.ssh_short_lived.public_key
      user = local.user_from_mail
  })

  connection {
      user  = "root"
      type  = "ssh"
      host  = self.ipv4_address
      private_key = file(var.digitalocean_priv_key_path)
      timeout = "10m"
  }
}

data "digitalocean_droplet" "ssh_droplet" {
  name = digitalocean_droplet.ssh_droplet.name
  depends_on = [digitalocean_droplet.ssh_droplet]
}

data "cloudflare_ip_ranges" "cloudflare" {}

data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

resource "digitalocean_firewall" "cloudflare_browser_ssh" {
  name = "cloudflare-browser-ssh"
  
  droplet_ids = [digitalocean_droplet.ssh_droplet.id]

  inbound_rule {
    protocol    = "tcp"
    port_range  = "22"
    source_addresses = ["${chomp(data.http.my_ip.body)}"]
  }

  inbound_rule {
    protocol    = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol    = "tcp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol    = "udp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol    = "icmp"
    port_range = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}