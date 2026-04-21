# Network Design

## Principles

- Keep management traffic isolated from workload traffic.
- Avoid stretching layer 2 further than necessary.
- Make remote administration independent from public service exposure.
- Make routing behavior obvious enough to troubleshoot from `r01` inward.
- Prefer Proxmox SDN-managed EVPN behavior and explicit routed underlay configuration over manual FRR customization.

## Routing goals

- Single node must work without redesign.
- The same model must extend to a few nodes later.
- `r01` must have a clean, explicit integration point with Proxmox SDN.
- Operational routing changes should happen in Proxmox SDN first, not in handcrafted FRR files.
- Public internet reachability should terminate on an external routed edge, not directly on the Proxmox hosts.
- Public IPv6 should be allocated in clean `/64` units that map to service networks.
- Address ownership should be visible at the tenant and network level, not buried in guest-local configuration.

## Underlay and overlay

Design split:

- A simple routed node underlay provides reachability between Proxmox nodes.
- EVPN/VXLAN provides the tenant and service overlay networks.
- Exit-node behavior handles north-south traffic.
- BGP or static routing is used only where routes leave the Proxmox SDN domain.

Boundary model:

- The EVPN zone is the shared transport container.
- The VNet is the actual tenant, routing, and firewall boundary.
- Each VNet gets its own prefix.

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

- EVPN zone: `dc-evpn`
- VNets: `infra-private`, `shared-public`, `tenant-a-private`, `tenant-a-public`, `tenant-b-private`, `tenant-b-public`, `lab-private`

- Back these workload networks with Proxmox SDN VNets.
- Use EVPN/VXLAN for multi-node extension.
- Keep tenant and service addressing stable so the upstream router sees summarized or explicitly assigned prefixes rather than node-local exceptions.

Concrete boundary rule:

- Use one VNet per distinct routing and security boundary.
- Do not use the EVPN zone itself as the tenant boundary.
- Use one public `/64` per public VNet.
- Use one ULA `/64` per private VNet.
- Do not rely on Proxmox itself to generate Router Advertisements for EVPN VNets.

IPAM guidance:

- Allocate prefixes per tenant VNet, not per node.
- Keep the same prefixes when workloads move between nodes.
- Reserve fixed addresses for tenant gateway or firewall appliances before allocating general workload pools.
- Use explicit IPv6 addressing inside VNets unless a dedicated RA source is deployed for that VNet.

### Public service networks

Use a separate class of service network for internet-facing workloads:

- Source public IPv6 prefixes from a Route64-delegated `/56`.
- Allocate one `/64` prefix per public service VNet by slicing the Route64 `/56`.
- Attach those prefixes to SDN-managed networks instead of directly to hypervisor management bridges.
- Keep private east-west addressing separate even when workloads also have public IPv6 addresses.
- Record ownership of each `/64` by tenant, service class, or environment.

Initial allocation model:

- `infra-private`: ULA `/64`
- `shared-public`: one public `/64` carved from the Route64 `/56`
- `tenant-a-private`: ULA `/64`
- `tenant-a-public`: one public `/64` carved from the Route64 `/56`
- `tenant-b-private`: ULA `/64`
- `tenant-b-public`: one public `/64` carved from the Route64 `/56`
- `lab-private`: ULA `/64`

IPv6 host configuration model:

- Public VNets use explicit IPv6 address assignments from their routed public `/64`.
- Private VNets use explicit ULA assignments.
- SLAAC is not assumed to work unless a dedicated RA service is introduced inside the VNet.

## 3. Out-of-band / hardware management

Purpose:

- IPMI, iDRAC, iLO, or switch management

Requirements:

- Strictly limited admin access
- Not routed to general workload networks

## Remote administration

The repository already indicates a WireGuard-based management path for `schous`. Keep that pattern and treat WireGuard as the operator entry network, not as a replacement for internal VLAN separation.

Rule set:

- Admins connect to WireGuard first.
- Proxmox UI, SSH, and automation endpoints bind only to management addresses.
- Public services are published from dedicated guest workloads, not from hypervisor nodes.
- Router Advertisements for guest addressing are not assumed to originate from Proxmox SDN.

## Public IPv6 edge integration

Layout:

- Route64 is the upstream provider for a delegated public IPv6 `/56`.
- `r01` establishes WireGuard connectivity to Route64's Sandefjord instance.
- Route64 routes the delegated public IPv6 `/56` toward `r01` over that WireGuard session.
- `r01` routes the relevant public service prefixes toward the Proxmox SDN edge.

Design intent:

- Public address management stays detached from the office ISP and physical site.
- The public IPv6 edge can evolve independently of the Proxmox node count.
- Internet ingress remains concentrated at a dedicated upstream boundary that is easier to audit and secure.

## EVPN and exit-node model

Layout:

- A documented routed underlay provides internal reachability between nodes.
- Proxmox SDN manages EVPN for east-west reachability of workload networks.
- `schous` is the primary Proxmox SDN exit node for north-south traffic.
- `r01` is the installed upstream edge and peers with `schous` for routed workload reachability.
- Route64 provides the upstream public IPv6 edge, with `r01` connected to Route64's Sandefjord instance over WireGuard.
- Non-exit nodes do not carry separate bespoke upstream routing policy.

Why this model:

- It works on one node immediately.
- It scales to a few nodes without changing tenant addressing.
- It keeps intra-cluster reachability explicit and easy to verify.
- It limits the amount of FRR state that operators need to maintain manually.
- It gives `r01` one clear Proxmox boundary to integrate with.

## r01 Integration

Path:

- Establish routed adjacency between `r01` and `schous`.
- Exchange only the workload prefixes that need north-south reachability.
- Keep management prefixes outside the tenant routing exchange.
- Do not make `r01` responsible for the internal node-to-node underlay topology.

Practical export model:

- Proxmox SDN installs EVPN VNet routes in the tenant VRF on `schous` rather than in the default BGP table.
- Unicast routing peers on `schous` only see prefixes that are explicitly leaked from that VRF.
- Use `frr.conf.local` on `schous` for selective VRF-to-default leaking when Proxmox's generated FRR config does not expose the required policy directly.
- Export only the prefixes that need to be reachable by each external peer.
- Example: leak `fdb1:4242:b1ef:2002::/64` from `vrf_myvpn` to the `r01` peer while leaving unrelated Route64-backed public `/64`s unexported.

## IPAM and prefix ownership

Strategy:

- Treat each VNet subnet as an explicitly owned prefix with a recorded tenant and purpose.
- Keep prefix allocation independent from node placement.
- Use stable naming and allocation rules so route advertisements can be understood by looking at the prefix inventory.

Practical policy:

- Management and underlay networks use fixed allocations only.
- Tenant-private networks use reserved pools for explicit static allocations.
- Tenant-public networks map one `/64` carved from the Route64 `/56` to one VNet.
- Public `/64` prefixes are not shared between unrelated tenants.
- Prefixes exported to external BGP peers are selected explicitly, not leaked wholesale from the tenant VRF.

This means the prefix boundary follows the VNet boundary, not the EVPN zone boundary.

## Route64 edge integration

Path:

- Use Route64 as the upstream location for public IPv6 space.
- Use `r01`'s WireGuard connectivity to Route64's Sandefjord instance.
- Route the delegated Route64 `/56` toward `r01`.
- Route selected public service `/64`s from `r01` toward the Proxmox SDN edge.
- Expose only explicitly selected public service networks across that edge.
- Keep hypervisor management and control-plane prefixes private.

Practical use of the delegated Route64 `/56`:

- Assign a dedicated `/64` from the delegated `/56` to each public-facing network, environment, or service tier when that improves clarity.
- Avoid slicing prefixes smaller than operationally necessary; the `/64` boundary is already convenient and standard for IPv6 service networks.
- Keep a documented mapping from each Route64 `/64` to its SDN VNet and consuming workloads.

## Deployment progression

- Start with `schous` as the only on-prem Proxmox node and the only exit node.
- Bring up the routed underlay model and EVPN on day one even in the single-node phase.
- Use routing between `r01` and `schous` from the start.
- Terminate the Route64 WireGuard session on `r01`, then route selected `/64`s from the delegated `/56` toward public VNets.
- Add additional Proxmox nodes into the same routed underlay and EVPN design without changing tenant prefixes or upstream topology.

## Example logical layout

```text
Administrator
  -> WireGuard
  -> Management VLAN
  -> Proxmox nodes

Internet
  -> Route64
  -> delegated public IPv6 /56
  -> WireGuard tunnel
  -> r01
  -> schous
  -> EVPN/VXLAN overlay

Proxmox nodes
  -> Routed node underlay
  -> EVPN/VXLAN overlay
  -> Exit node
  -> r01

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
- Permit routing adjacencies only between `r01` and the designated exit-node interfaces.
- Limit public-prefix advertisement and acceptance to the Route64 edge path on `r01` and the designated Proxmox exit-node path.
- Keep node-to-node underlay reachability limited to the intended internal interfaces.
