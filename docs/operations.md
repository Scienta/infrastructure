# Operations

## Provisioning standard

- Install Proxmox VE with a reproducible partitioning scheme.
- Use consistent hostnames, time sync, DNS, and admin account policy.
- Apply post-install baseline configuration through Ansible where practical.
- Record each node's role, hardware, firmware version, and interface mapping.

## Change management

- Treat hypervisor updates and network changes as planned maintenance.
- Change one control-plane variable at a time.
- Keep a rollback note for every network change.
- Prefer SDN-level changes over direct FRR file edits.

## Routing operations

- Keep Proxmox SDN as the source of truth for workload network intent.
- Keep OpenFabric as the source of truth for node-to-node underlay reachability.
- Do not manage FRR directly on cluster nodes outside the Proxmox SDN model.
- Treat the WireGuard session from `schous` to Route64's Sandefjord instance as part of the public IPv6 edge design.
- Test routing changes first with one non-critical prefix before broadening advertisements.
- Maintain an inventory of the Route64-assigned public `/56` and the `/64` prefixes carved from it for mapped SDN networks.
- Validate Route64-to-on-prem reachability before changing public prefix advertisements.

## IPAM operations

- Maintain a current inventory of all management, underlay, tenant-private, and tenant-public prefixes.
- Record tenant ownership and network purpose for every routed subnet.
- Reserve fixed addresses for gateways, control-plane services, and security appliances before allocating workload addresses.
- Review public IPv6 `/64` assignments whenever a new public-facing tenant network is created.
- Do not treat node-local guest configuration as the authoritative record of address usage.
- Record any VNet that uses a dedicated RA source instead of explicit guest addressing.

## Backup status

- There is currently no defined backup strategy.
- Operational decisions should account for the absence of a recovery path for stateful workloads.

## Monitoring

Monitor at least:

- Node health and uptime
- WireGuard tunnel state
- OpenFabric neighbor state
- CPU, memory, and temperature trends
- Reachability of the Route64 WireGuard session from `schous`
- Reachability for each advertised public `/64`
- Drift between documented prefix ownership and active routed networks
- Any dedicated RA or DHCPv6 service used for guest addressing

## Patching

- Patch one node at a time.
- Be conservative before major Proxmox and kernel changes because rollback and recovery options are limited without backups.
- For multi-node clusters, migrate or stop workloads intentionally before reboots.
- Track firmware updates separately from OS updates.

## Failure handling

### Single node failure

- Rebuild the failed node and restore service placement manually.
- Do not force cluster actions until quorum state is understood.

### Network partition

- Assume split-brain risk before assuming software fault.
- Validate management and cluster links independently.
- Validate OpenFabric neighbor state before assuming the EVPN layer is at fault.
- In 2-node deployments, be conservative with HA automation.

### Public IPv6 edge failure

- Treat the Route64 WireGuard session on `schous` as a critical routing dependency for public ingress.
- Ensure rebuild steps exist for the `schous` to Route64 Sandefjord tunnel, including tunnel configuration, route policy, and prefix mapping.
- Keep private management access independent from the public IPv6 edge so public-edge failure does not block recovery work.

### Backup failure

- Not applicable yet because no backup system is currently defined.

## Capacity planning

- Reserve headroom for one node failure for any workload that must continue running.
- Track CPU ready time and memory pressure.
- Review capacity monthly or after major workload additions.

## Documentation to add later

- Host inventory sheet
- Rack and power layout
- IP/VLAN allocation table
- OpenFabric interface and addressing table
- Public IPv6 `/64` allocation table
- Tenant prefix ownership table
- Restore runbooks
- Incident response checklist
