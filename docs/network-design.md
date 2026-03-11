# Network Design

## Principles

- Keep management traffic isolated from workload traffic.
- Avoid stretching layer 2 further than necessary.
- Make remote administration independent from public service exposure.
- Make routing behavior obvious enough to troubleshoot from the external router inward.
- Prefer Proxmox SDN-managed OpenFabric and EVPN behavior over manual FRR customization.

## Routing goals

- Single node must work without redesign.
- The same model must extend to a few nodes later.
- The external on-prem router must have a clean, explicit integration point.
- Operational routing changes should happen in Proxmox SDN first, not in handcrafted FRR files.
- Public internet reachability should terminate on a cloud edge, not directly on the Proxmox hosts.
- Public IPv6 should be allocated in clean `/64` units that map to service networks.
- Address ownership should be visible at the tenant and network level, not buried in guest-local configuration.

## Underlay and overlay

Design split:

- OpenFabric provides the routed underlay between Proxmox nodes.
- EVPN/VXLAN provides the tenant and service overlay networks.
- Exit-node behavior handles north-south traffic.
- External BGP is used only where routes leave the Proxmox SDN domain.

## Network planes

## 1. Management

Purpose:

- Proxmox UI and API
- SSH
- Ansible
- Hardware management

Requirements:

- Reachable through WireGuard
- Not directly exposed to the public internet
- DNS entries for each node
- Logged administrative access

Implementation:

- VLAN: `mgmt`
- Dedicated management prefixes in NetBox
- Bridge: `vmbr0`

IPAM guidance:

- Use static allocations for Proxmox nodes, management gateways, and operator-facing services.
- Keep this network outside tenant allocation pools.

## 2. Service / tenant workloads

Purpose:

- VM and container application traffic
- Ingress or reverse proxy exposure

Requirements:

- Segmented by environment where needed
- Firewalling between service zones
- Public ingress terminated only on explicitly designated systems

Implementation:

- VNets: `infra`, `dmz-public`, `tenant-shared`, `lab`

- Back these workload networks with Proxmox SDN VNets.
- Use EVPN/VXLAN for multi-node extension.
- Keep tenant and service addressing stable so the upstream router sees summarized or explicitly assigned prefixes rather than node-local exceptions.

IPAM guidance:

- Allocate prefixes per tenant VNet, not per node.
- Keep the same prefixes when workloads move between nodes.
- Reserve fixed addresses for tenant gateway or firewall appliances before allocating general workload pools.

### Public service networks

Use a separate class of service network for internet-facing workloads:

- Source public IPv6 prefixes from Scaleway.
- Allocate one `/64` prefix per public service VNet.
- Attach those prefixes to SDN-managed networks instead of directly to hypervisor management bridges.
- Keep private east-west addressing separate even when workloads also have public IPv6 addresses.
- Record ownership of each `/64` by tenant, service class, or environment.

## 3. Out-of-band / hardware management

Purpose:

- IPMI, iDRAC, iLO, or switch management

Requirements:

- Strictly limited admin access
- Not routed to general workload networks

## Remote administration

The repository already indicates a WireGuard-based management path between `humle` and `schous`. Keep that pattern and treat WireGuard as the operator entry network, not as a replacement for internal VLAN separation.

Rule set:

- Admins connect to WireGuard first.
- Proxmox UI, SSH, and automation endpoints bind only to management addresses.
- Public services are published from dedicated guest workloads, not from hypervisor nodes.

## Public edge integration

Layout:

- `humle` is the Scaleway VM and public edge.
- `humle` runs BIRD for routing related to the Proxmox environment.
- `humle` owns the delegated public IPv6 prefixes.
- Traffic for those public prefixes is carried from `humle` to `schous` over WireGuard.
- `schous` injects the relevant public service prefixes into the Proxmox SDN domain.

Design intent:

- Public address management stays detached from the physical site.
- The public edge can evolve independently of the Proxmox node count.
- Internet ingress remains concentrated in one place that is easier to audit and secure.

## EVPN and exit-node model

Layout:

- Proxmox SDN OpenFabric provides the internal routed fabric between nodes.
- Proxmox SDN manages EVPN for east-west reachability of workload networks.
- `schous` is the primary exit node for north-south traffic.
- The external on-prem router peers with `schous` over BGP.
- `humle` provides the public edge for internet-routable prefixes and handles edge routing with BIRD.
- Non-exit nodes do not carry separate bespoke upstream routing policy.

Why this model:

- It works on one node immediately.
- It scales to a few nodes without changing tenant addressing.
- It uses Proxmox's own fabric model for intra-cluster routing.
- It limits the amount of FRR state that operators need to maintain manually.
- It gives the external router one clear boundary to integrate with.

## External router integration

Path:

- Establish BGP adjacency between the on-prem router and `schous`.
- Exchange only the workload prefixes that need north-south reachability.
- Keep management prefixes outside the tenant routing exchange.
- Do not make the external router responsible for the internal OpenFabric topology.

## IPAM and prefix ownership

Strategy:

- Treat each VNet subnet as an explicitly owned prefix with a recorded tenant and purpose.
- Keep prefix allocation independent from node placement.
- Use stable naming and allocation rules so route advertisements can be understood by looking at the prefix inventory.

Practical policy:

- Management and underlay networks use fixed allocations only.
- Tenant-private networks use reserved pools for explicit static allocations.
- Tenant-public networks map one public Scaleway `/64` to one VNet.
- Public `/64` prefixes are not shared between unrelated tenants.

## Scaleway edge integration

Path:

- Use `humle` as the upstream location for public IPv6 space.
- Use BIRD on `humle` to carry the routed edge policy for those public prefixes.
- Route delegated `/64` prefixes from `humle` toward `schous`.
- Expose only explicitly selected public service networks across that edge.
- Keep hypervisor management and control-plane prefixes private.

Practical use of delegated `/64` prefixes:

- Assign a dedicated `/64` to each public-facing network, environment, or service tier when that improves clarity.
- Avoid slicing prefixes smaller than operationally necessary; the delegated `/64` boundary is already convenient and standard for IPv6 service networks.
- Keep a documented mapping from each Scaleway `/64` to its SDN VNet and consuming workloads.

## Deployment progression

- Start with `schous` as the only on-prem Proxmox node and the only exit node.
- Bring up OpenFabric and EVPN on day one even in the single-node phase.
- Use BGP between the on-prem router and `schous` from the start.
- Route Scaleway-provided public `/64` prefixes from `humle` to `schous` over WireGuard, with BIRD on `humle` handling the edge routing state.
- Add additional Proxmox nodes into the same OpenFabric and EVPN design without changing tenant prefixes or upstream topology.

## Example logical layout

```text
Administrator
  -> WireGuard
  -> Management VLAN
  -> Proxmox nodes

Internet
  -> humle
  -> delegated public IPv6 /64 prefixes
  -> WireGuard tunnel
  -> schous
  -> EVPN/VXLAN overlay

Proxmox nodes
  -> OpenFabric underlay
  -> EVPN/VXLAN overlay
  -> Exit node
  -> External on-prem router

Proxmox nodes
  -> Service VLANs
  -> VMs / LXCs / Kubernetes nodes
  -> Edge proxy or load balancer
```

## Firewall posture

- Deny unsolicited inbound traffic to hypervisor hosts.
- Allow admin access only from management networks.
- Restrict east-west access between workload VLANs by default.
- Log management-plane failures and repeated auth attempts.
- Permit routing adjacencies only between the external router and the designated exit-node interfaces.
- Limit public-prefix advertisement and acceptance to the Scaleway edge path and the designated exit-node path.
- Keep OpenFabric adjacencies limited to the intended node-to-node fabric interfaces.
