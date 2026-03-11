# Proxmox Datacenter Overview

## Purpose

Define a small datacenter platform based on Proxmox VE that can run virtual machines and lightweight Kubernetes or container workloads with predictable operations, remote management, and recoverable failure modes.

## Scope

This design covers:

- Proxmox cluster topology
- Compute roles
- Network segmentation
- Day-2 operations

This design fixes the intended platform architecture and operating model. Exact hardware SKUs, rack drawings, and per-service guest layouts are implementation details that follow this design.

## Design goals

- Keep the platform simple enough to operate without full-time staff.
- Prefer recovery and observability over high-complexity HA features.
- Keep routing simple and predictable from day one.
- Use Proxmox-managed OpenFabric for the cluster underlay.
- Align with the Proxmox SDN EVPN model and its exit-node pattern.
- Minimize manual FRR configuration on Proxmox nodes.
- Support remote administration over a secured management path.
- Separate management and workload traffic.
- Start cleanly on a single node and expand to a few nodes without redesigning the routing model.
- Integrate cleanly with an external on-prem router.
- Use a cloud-hosted public edge so the on-prem site does not need native public addressing on the hypervisors.
- Make IPv6 a first-class public connectivity model.

## Baseline topology

## Initial footprint

- `schous`: primary on-prem Proxmox node and initial SDN exit node.
- `humle`: Scaleway VM, public edge, WireGuard endpoint toward `schous`, and BIRD-based routing node.

## Target-state cluster

- The design starts on one on-prem Proxmox node.
- The design scales to a small 3-node Proxmox cluster without changing the routing model.
- The cluster does not depend on HA for correctness in the initial phase.
- `schous` is the operational control point for monitoring aggregation, template management, and shared operational tooling.

## Platform model

- Hypervisor: Proxmox VE
- Guest types: mostly VMs, with LXC only for low-risk infrastructure services
- Host OS management: Proxmox-native for hypervisor lifecycle, Ansible for surrounding system configuration
- Remote access: WireGuard into the management plane
- Underlay fabric: Proxmox SDN OpenFabric
- Overlay networking: Proxmox SDN EVPN
- North-south routing: external router plus designated Proxmox SDN exit node
- Public edge: `humle`, running BIRD and forwarding public reachability toward the on-prem environment
- Public IPv6: delegated `/64` prefixes from Scaleway assigned to public service networks
- IPAM strategy: external source of truth for prefixes and tenant ownership, with Proxmox SDN implementing the resulting networks

## Routing model

The routing design is:

- Use Proxmox SDN OpenFabric as the internal node-to-node routing fabric.
- Use Proxmox SDN EVPN for workload network distribution between nodes.
- Use `schous` as the primary exit node for north-south traffic.
- Keep the external router as the upstream default gateway domain and policy boundary.
- Use `humle` as the public edge and BIRD-based upstream source of public IP reachability.
- Do not maintain custom per-node FRR logic outside the Proxmox SDN model.

This keeps the control plane centered on Proxmox SDN instead of a hand-built FRR configuration set.

## Network stack

The intended stack is:

- OpenFabric for the Proxmox node underlay
- EVPN/VXLAN for multi-node workload networks
- Exit-node routing for north-south traffic
- External BGP or static routing only at the boundary to the on-prem router and cloud edge

This split keeps the cluster fabric internal and leaves upstream complexity at clearly defined integration points.

## Public edge model

- `humle` runs on Scaleway and acts as the internet-facing edge.
- `humle` runs BIRD for routing related to the Proxmox environment.
- `humle` forwards traffic and routed public prefixes toward `schous` over WireGuard.
- Public IPv6 service prefixes are allocated as dedicated `/64` networks from Scaleway.
- Those `/64` networks are then assigned to Proxmox SDN-backed public service networks rather than attached directly to hypervisor management interfaces.

This separates public address ownership from the physical site while keeping service addressing stable.

## IPAM strategy

IP address management is a separate control-plane concern from Proxmox SDN itself.

Implementation:

- Use NetBox as the source of truth for prefixes, tenant ownership, and allocation intent.
- Use Proxmox SDN to realize VNets, subnets, gateways, and routing behavior from that plan.
- Avoid making ad hoc address assignments directly in guests without recording them in the IPAM source of truth.

Design intent:

- Prefix ownership remains understandable even as nodes and tenants are added.
- Public IPv6 allocations from Scaleway can be tracked cleanly.
- The routing and firewall model can refer to stable network objects instead of undocumented address choices.

Allocation principles:

- One VNet maps to one clearly owned prefix per address family.
- Each public-facing service VNet receives a dedicated Scaleway IPv6 `/64`.
- Infrastructure networks use stable, reserved addresses for gateways, control-plane services, and monitoring endpoints.
- Dynamic allocation is not part of the initial design; guest addressing is recorded and allocated explicitly from tenant-owned prefixes.

## Node roles

### Single-node phase

- One Proxmox node hosts compute and the SDN exit-node role.
- OpenFabric is configured from the start so the underlay model does not change later.
- The external router uses BGP with that node from the start.
- `humle` forwards public prefixes and public ingress toward that same node.

### Small multi-node phase

- `schous` remains the primary exit node.
- Nodes join the OpenFabric underlay first.
- Additional nodes join the EVPN fabric and advertise attached workload reachability through Proxmox SDN.
- The external router continues to integrate at the edge instead of learning every internal implementation detail.
- `humle` continues to see one stable on-prem integration boundary even as more nodes are added.

This preserves the same routing model while adding nodes.

## Availability model

- Assume node failure is recoverable, not invisible.
- Do not depend on Proxmox HA in the initial design.
- Keep critical control services isolated from experimental workloads.
- Prefer documented rebuild procedures over implicit cluster behavior.
- Routing remains single-exit-node by design.

## Security model

- Management access only over trusted paths such as WireGuard and approved admin networks.
- No direct public exposure of the Proxmox web UI.
- Separate admin identities from workload service accounts.
- Store secrets outside this repository or encrypted with an approved mechanism.
