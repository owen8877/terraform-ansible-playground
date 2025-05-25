provider "google" {
  credentials = file("../secrets/primary.json")
  project     = var.project_id
  region      = var.region
}

resource "google_compute_instance" "vm_instance" {
  name         = "my-instance"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = 30            # has to be this size for free billing
      type  = "pd-standard" # has to be this type for free billing
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  # deletion_protection = false
  enable_display      = false

  network_interface {
    subnetwork = google_compute_subnetwork.dual_stack_subnet.id
    stack_type = "IPV4_IPV6"
    # ipv6_access_type = "EXTERNAL"
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

resource "google_compute_subnetwork" "dual_stack_subnet" {
  name          = "dual-stack-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = "us-east1"
  network       = google_compute_network.custom_network.id
  stack_type    = "IPV4_IPV6"

  ipv6_access_type = "EXTERNAL"
}

resource "google_compute_network" "custom_network" {
  name                    = "custom-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  enable_ula_internal_ipv6 = true
}

resource "google_compute_firewall" "fw1" {
  name    = "fw1"
  network = google_compute_network.custom_network.id
  priority = 1000
  direction = "INGRESS"

  allow {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-all-ingress"]
}

resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.custom_network.id
  priority = 65534
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-enabled"]
}