/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  gateway_address = (
    var.gateway_address_create
    ? google_compute_address.gateway[0].address
    : var.gateway_address
  )
  router = (
    var.router_config.create
    ? try(google_compute_router.router[0].name, null)
    : var.router_config.name
  )
  secret = random_id.secret.b64_url
}

resource "google_compute_address" "gateway" {
  count   = var.gateway_address_create ? 1 : 0
  name    = "vpn-${var.name}"
  project = var.project_id
  region  = var.region
}

resource "google_compute_forwarding_rule" "esp" {
  name        = "vpn-${var.name}-esp"
  project     = var.project_id
  region      = var.region
  target      = google_compute_vpn_gateway.gateway.self_link
  ip_address  = local.gateway_address
  ip_protocol = "ESP"
}

resource "google_compute_forwarding_rule" "udp-500" {
  name        = "vpn-${var.name}-udp-500"
  project     = var.project_id
  region      = var.region
  target      = google_compute_vpn_gateway.gateway.self_link
  ip_address  = local.gateway_address
  ip_protocol = "UDP"
  port_range  = "500"
}

resource "google_compute_forwarding_rule" "udp-4500" {
  name        = "vpn-${var.name}-udp-4500"
  project     = var.project_id
  region      = var.region
  target      = google_compute_vpn_gateway.gateway.self_link
  ip_address  = local.gateway_address
  ip_protocol = "UDP"
  port_range  = "4500"
}

resource "google_compute_router" "router" {
  count   = var.router_config.create ? 1 : 0
  name    = coalesce(var.router_config.name, "vpn-${var.name}")
  project = var.project_id
  region  = var.region
  network = var.network
  bgp {
    advertise_mode = (
      var.router_config.custom_advertise != null
      ? "CUSTOM"
      : "DEFAULT"
    )
    advertised_groups = (
      try(var.router_config.custom_advertise.all_subnets, false)
      ? ["ALL_SUBNETS"]
      : []
    )
    dynamic "advertised_ip_ranges" {
      for_each = try(var.router_config.custom_advertise.ip_ranges, {})
      iterator = range
      content {
        range       = range.key
        description = range.value
      }
    }
    keepalive_interval = try(var.router_config.keepalive, null)
    asn                = var.router_config.asn
  }
}

resource "google_compute_router_peer" "bgp_peer" {
  for_each                  = var.tunnels
  region                    = var.region
  project                   = var.project_id
  name                      = "${var.name}-${each.key}"
  router                    = coalesce(each.value.router, local.router)
  peer_ip_address           = each.value.bgp_peer.address
  peer_asn                  = each.value.bgp_peer.asn
  advertised_route_priority = each.value.bgp_peer.route_priority
  advertise_mode = (
    try(each.value.bgp_peer.custom_advertise, null) != null
    ? "CUSTOM"
    : "DEFAULT"
  )
  advertised_groups = concat(
    try(each.value.bgp_peer.custom_advertise.all_subnets, false) ? ["ALL_SUBNETS"] : [],
    try(each.value.bgp_peer.custom_advertise.all_vpc_subnets, false) ? ["ALL_VPC_SUBNETS"] : [],
    try(each.value.bgp_peer.custom_advertise.all_peer_vpc_subnets, false) ? ["ALL_PEER_VPC_SUBNETS"] : []
  )
  dynamic "advertised_ip_ranges" {
    for_each = try(each.value.bgp_peer.custom_advertise.ip_ranges, {})
    iterator = range
    content {
      range       = range.key
      description = range.value
    }
  }
  interface = google_compute_router_interface.router_interface[each.key].name
}

resource "google_compute_router_interface" "router_interface" {
  for_each = var.tunnels
  project  = var.project_id
  region   = var.region
  name     = "${var.name}-${each.key}"
  router   = coalesce(each.value.router, local.router)
  # FIXME: can bgp_session_range be null?
  ip_range   = each.value.bgp_session_range == "" ? null : each.value.bgp_session_range
  vpn_tunnel = google_compute_vpn_tunnel.tunnels[each.key].name
}

resource "google_compute_vpn_gateway" "gateway" {
  name    = var.name
  project = var.project_id
  region  = var.region
  network = var.network
}

resource "google_compute_vpn_tunnel" "tunnels" {
  for_each           = var.tunnels
  project            = var.project_id
  region             = var.region
  name               = "${var.name}-${each.key}"
  router             = coalesce(each.value.router, local.router)
  peer_ip            = each.value.peer_ip
  ike_version        = each.value.ike_version
  shared_secret      = coalesce(each.value.shared_secret, local.secret)
  target_vpn_gateway = google_compute_vpn_gateway.gateway.self_link
  depends_on         = [google_compute_forwarding_rule.esp]
}

resource "random_id" "secret" {
  byte_length = 8
}
