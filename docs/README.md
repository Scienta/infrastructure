# Proxmox Datacenter Design

This directory contains design documents for a small Proxmox-based datacenter.

## Documents

- [Overview](./proxmox-datacenter-overview.md): scope, goals, topology, and platform decisions.
- [Network design](./network-design.md): management, service, and external network layout.
- [Operations](./operations.md): lifecycle, backup, monitoring, patching, and failure handling.

## Current assumptions

- `schous` is the on-prem Proxmox node and initial SDN exit node.
- Management connectivity already uses WireGuard.
- `r01` is installed and connects over WireGuard to Route64's Sandefjord instance for public IPv6 reachability.
- Route64 delegates a public IPv6 `/56`, which is sliced into `/64` prefixes for public-facing networks.
- The Proxmox SDN design uses explicit routed node-to-node reachability as the cluster underlay.
- These documents describe the target design that the platform will implement.

## Suggested next step

Update these documents with exact interface names, subnets, route policies, and rack placement as the installed network is verified.
