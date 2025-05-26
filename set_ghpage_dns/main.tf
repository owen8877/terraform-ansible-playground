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

resource "cloudflare_dns_record" "cname_record" {
  zone_id = var.cloudflare_zone_id
  name    = var.sub_domain
  content = "${var.gh_username}.github.io"
  type    = "CNAME"
  ttl     = 300
}