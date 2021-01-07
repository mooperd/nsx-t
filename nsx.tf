terraform {
  required_providers {
    nsxt = {
      source = "vmware/nsxt"
    }
  }
}

provider "nsxt" {
  host                  = "nsx-rhr3c5ypi8.ionoscloud.tools"
  username              = "nsx-admin@System Domain"
  password              = "J6vhhKMeDlr,kt"
  allow_unverified_ssl  = true
  remote_auth           = true
  max_retries           = 10
  retry_min_delay       = 500
  retry_max_delay       = 5000
  retry_on_status_codes = [429]
}

data "nsxt_policy_transport_zone" "overlay" {
    display_name = "overlay"
}

data "nsxt_policy_tier0_gateway" "t0-gw" {
    display_name = "t0-gw"
}

data "nsxt_policy_dhcp_server" "dhcp-server" {
    display_name = "dhcp-server"
}

data "nsxt_policy_edge_cluster" "edge-cluster" {
    display_name = "edge-cluster"
}


resource "nsxt_policy_tier1_gateway" "tier1_gw_blue" {
  description               = "Tier-1 provisioned by Terraform"
  display_name              = "Tier1-gw1-blue"
  nsx_id                    = "predefined_id"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.edge-cluster.path
  failover_mode             = "PREEMPTIVE"
  default_rule_logging      = "false"
  enable_firewall           = "false"
  enable_standby_relocation = "false"
  tier0_path                = data.nsxt_policy_tier0_gateway.t0-gw.path
  route_advertisement_types = ["TIER1_NAT", "TIER1_STATIC_ROUTES", "TIER1_CONNECTED"]
  pool_allocation           = "ROUTING"
  dhcp_config_path          = data.nsxt_policy_dhcp_server.dhcp-server.path
  tag {
    scope = "color"
    tag   = "blue"
  }
}

resource "nsxt_policy_segment" "segment1" {
  display_name        = "segment1"
  description         = "Terraform provisioned Segment"
  connectivity_path   = nsxt_policy_tier1_gateway.tier1_gw_blue.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay.path

  subnet {
    cidr        = "10.141.1.1/24"
    dhcp_ranges = ["10.141.1.50-10.141.1.150"]

    dhcp_v4_config {
      server_address = "10.141.1.2/24"
      lease_time     = 36000
    }
  }
}

resource "nsxt_policy_nat_rule" "snat1_blue" {
  display_name         = "snat_rule1_blue"
  action               = "SNAT"
  source_networks      = ["10.141.1.0/24"]
  translated_networks  = ["87.106.186.10"]
  gateway_path         = nsxt_policy_tier1_gateway.tier1_gw_blue.path
  logging              = false

  tag {
    scope = "color"
    tag   = "blue"
  }
}

/*
resource "nsxt_policy_nat_rule" "dnat1_blue" {
  display_name         = "dnat_rule1_blue"
  action               = "DNAT"
  destination_networks = ["10.141.1.100"]
  source_networks      = ["87.106.186.10"]
  translated_networks  = ["87.106.186.10"]
  gateway_path         = nsxt_policy_tier1_gateway.tier1_gw_blue.path
  logging              = false
  firewall_match       = "MATCH_INTERNAL_ADDRESS"

  tag {
    scope = "color"
    tag   = "blue"
  }
}
*/
