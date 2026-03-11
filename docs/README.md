# Proxmox Datacenter Design

This directory contains design documents for a small Proxmox-based datacenter.

## Documents

- [Overview](./proxmox-datacenter-overview.md): scope, goals, topology, and platform decisions.
- [Network design](./network-design.md): management, service, and external network layout.
- [Operations](./operations.md): lifecycle, backup, monitoring, patching, and failure handling.

## Current assumptions

- The current repository manages two hosts: `humle` and `schous`.
- Management connectivity already uses WireGuard.
- Public edge connectivity is provided by a Scaleway VM.
- Scaleway can allocate multiple IPv6 `/64` prefixes for public-facing networks.
- The Proxmox SDN design uses OpenFabric as the cluster underlay.
- These documents describe a target-state design and call out decisions that still need to be made.

## Suggested next step

After the physical hardware and VLAN plan are fixed, update these documents with exact hostnames, interface names, subnets, and rack placement.
