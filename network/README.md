# Network Stack

Back to [Main README](../README.md)

The Ubiquiti Gateway Max (UGM) is the network gateway, VLAN router, firewall,
and WireGuard VPN server. Docker provides the local network services that run
on the Debian host: Nginx Proxy Manager, Pi-hole, and DDNS Updater.

## Network topology

The UGM separates the network into these VLANs:

| VLAN | Purpose | Access policy |
|------|---------|---------------|
| Management | Network infrastructure and administration | Reachable from the WireGuard VPN |
| Trusted / server | Debian server, trusted clients, and the administrator's PC | Normal trusted access to services |
| Guest | Guest clients | Internet-only; isolated from internal VLANs |
| IoT | Home automation and other constrained devices | No access to Wi-Fi networks; only the explicitly allowed flows to Management |

Firewall policies on the UGM allow:

- WireGuard clients to reach the Management VLAN for administration and access
  to the required server services.
- Selected IoT-to-Management traffic so Home Assistant can discover and
  control approved IoT devices.
- No general IoT access to Wi-Fi or other internal networks.

Keep the authoritative VLAN IDs, subnets, DHCP scopes, and firewall rules in
the UGM configuration. Do not put live addresses, passwords, VPN keys, or
exported client profiles in this repository.

## Debian host networking

The Debian server uses NetworkManager (`nmcli`) rather than a static
`/etc/network/interfaces` configuration.

- `br1.20` is the primary VLAN interface on the trusted/server VLAN.
- The host has five addresses assigned through the NetworkManager
  configuration on that interface.
- `/opt/docker` is the stable repository path and resolves to
  `/mnt/raid1/docker-configs`.
- Docker's engine data root is `/mnt/raid1/docker-data`; this is separate from
  the `/mnt/media` HDD used for media files.
- A separate bridge is used for the Home Assistant KVM/libvirt VM so Home
  Assistant can communicate with Wi-Fi-connected devices.
- Docker services bind to the host addresses or Docker networks defined in
  their Compose files.

Useful inspection commands:

```bash
nmcli connection show
nmcli device status
ip -br address show br1.20
ip route
bridge link
```

When changing VLANs or addresses, update the UGM firewall policy and any
Compose binding addresses together. Avoid documenting live `.env` values or
private network exports here.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| **Nginx Proxy Manager** | 80 / 443 / 81 (admin) | Reverse proxy and Let's Encrypt TLS |
| **Pi-hole** | 53 / 80 | DNS resolution and ad blocking |
| **DDNS Updater** | 8000 | Keeps DuckDNS in sync with the WAN address |
| **WireGuard** | UGM-managed | Remote access to the Management VLAN and permitted server services |

The old Docker OpenVPN stack is not part of the active design. Keep its
configuration only for historical reference; do not start it alongside the
UGM WireGuard server.

## Quick start

```bash
cp .env.example .env
# Fill in local values on the deployment host only.
docker compose up -d
```

## Environment

`.env` is deployment-local and ignored by Git. Use `.env.example` as a
placeholder template:

```dotenv
NPM_IP=replace-with-server-address
PIHOLE_IP=replace-with-server-address
PIHOLE_PASSWORD=replace-me
DUCKDNS_DOMAIN=your-subdomain.duckdns.org
DUCKDNS_TOKEN=replace-me
TZ=Europe/Lisbon
CONFIG_PATH=/opt/docker
```

## Access

- **NPM admin**: `http://<NPM_IP>:81` — change the default password
  immediately.
- **Pi-hole**: `http://<PIHOLE_IP>/admin`
- **DDNS UI**: `http://<server-address>:8000`
- **Remote access**: connect to the WireGuard server on the UGM, then use
  only the internal addresses allowed by the UGM firewall policies.

## UGM WireGuard

1. Create or enable the WireGuard server on the UGM.
2. Create one client profile per device and transfer profiles securely.
3. Configure the client routes to include the Management VLAN and only the
   server networks that the client needs.
4. Confirm the UGM firewall permits WireGuard-to-Management traffic.
5. Test DNS, server access, and Home Assistant access from a VPN client.

Treat client profiles and private keys as secrets. Store them outside the
repository and never paste them into README files, issues, or chat.

## Home Assistant and IoT traffic

Home Assistant runs as a KVM/libvirt VM on the Debian host. Its VM network is
attached to the dedicated host bridge so it can reach Wi-Fi-connected IoT
devices through the UGM's permitted firewall flows.

If an integration cannot discover or control a device:

1. Confirm the device is on the IoT VLAN.
2. Confirm the Home Assistant VM is attached to the intended bridge.
3. Check that the UGM policy allows the required protocol and destination
   from IoT to Management.
4. Check multicast discovery requirements separately; only enable the
   minimum relay or reflector scope required by the integration.
5. Confirm that the IoT VLAN still has no general route to Wi-Fi networks.

## Security notes

- Keep `.env`, WireGuard profiles, private keys, and exported gateway
  configuration out of Git.
- Use one WireGuard key per client so lost devices can be revoked individually.
- Keep Guest and IoT policies deny-by-default.
- Allow only the IoT-to-Management flows required by Home Assistant.
- Review UGM firewall logs after changing inter-VLAN policies.
- Regularly update Docker images and the UGM firmware.

## Backup

Back up the UGM configuration, WireGuard peer definitions, NetworkManager
connection profiles, Docker Compose files, and Home Assistant VM separately.
Encrypt backups because gateway exports and VPN profiles contain secrets.

## Maintenance

```bash
docker compose pull && docker compose up -d
docker compose logs -f npm
docker compose logs -f pihole
nmcli connection show
```

## Troubleshooting

| Problem | Checks |
|---------|--------|
| VPN connects but services are unreachable | Verify the WireGuard routes and UGM VPN-to-Management firewall policy |
| IoT device is not visible in Home Assistant | Verify the VM bridge, IoT-to-Management rule, and multicast discovery requirements |
| IoT device reaches Wi-Fi | Review UGM inter-VLAN policies and remove broad allow rules |
| NPM returns 502 | Check the upstream container, its bound server address, and `proxy_network` |
| DNS fails on a VLAN | Confirm DHCP DNS settings and Pi-hole reachability from that VLAN |
| DDNS is stale | Check `docker compose logs ddns-updater` and the UGM WAN address |
| Server lost its addresses | Check `nmcli connection show`, `ip -br address show br1.20`, and the VLAN parent link |

---

Updated October 2026.
