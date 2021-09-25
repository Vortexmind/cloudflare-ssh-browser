output "success_message" { 
    value = <<EOF
    
    Your droplet is up and running at ${digitalocean_droplet.ssh_droplet.ipv4_address}
    
    Direct SSH Command (only allowed from ${chomp(data.http.my_ip.body)} : 
        ssh -i ${var.digitalocean_priv_key_path} root@${digitalocean_droplet.ssh_droplet.ipv4_address}

    Logs (on droplet)
        Cloud-Init:     less /var/log/cloud-init-output.log
        Cloudflared:    less /var/log/cloudflared.log

    EOF
}