provider "google" {
  credentials = file("../secrets/gcp.json")
  project     = var.project_id
  region      = var.region
}

resource "google_compute_instance" "vm_instance" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size_gb
      type  = var.disk_type
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  # deletion_protection = false
  enable_display      = false

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    stack_type = "IPV4_ONLY"
    access_config {
      network_tier = "STANDARD" # has to be this type for free billing
    }
  }

  metadata = {
    enable-osconfig = "TRUE"
    ssh-keys = "${var.ssh_user}:${file(var.public_key_path)}"
  }

  tags = ["ssh-enabled", "allow-all-ingress"]
}

output "ipv4_address" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.name}-subnet" 
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.network.id
  stack_type    = "IPV4_ONLY"
}

resource "google_compute_network" "network" {
  name                    = "${var.name}-network"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  enable_ula_internal_ipv6 = true
}

resource "google_compute_firewall" "allow-all-ingress" {
  name    = "${var.name}-allow-all-ingress"
  network = google_compute_network.network.id
  priority = 1000
  direction = "INGRESS"

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-all-ingress"]
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "${var.name}-allow-ssh"
  network = google_compute_network.network.id
  priority = 65534
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-enabled"]
}

terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "5.5.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_dns_record" "set_wild_a_record" {
  zone_id = var.cloudflare_zone_id
  name    = "*.${var.sub_domain}"
  content = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
  type    = "A"
  ttl     = 300
}

resource "cloudflare_dns_record" "set_a_record" {
  zone_id = var.cloudflare_zone_id
  name    = "${var.sub_domain}"
  content = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
  type    = "A"
  ttl     = 300
}

