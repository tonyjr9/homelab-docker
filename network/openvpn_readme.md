# Legacy OpenVPN Notes

OpenVPN is no longer the primary remote-access service. The Ubiquiti gateway (small UGM) now owns the VPN endpoint, routing, and firewall policy. The server-side `wg-easy` service is retained as a fallback.

The former Docker OpenVPN definition is preserved in [`docker-compose.yml.unused`](./docker-compose.yml.unused) for reference only. Do not start it alongside the Ubiquiti VPN unless you have explicitly planned the routes, port forwarding, and DNS behavior.

For the active network setup, use [network/README.md](./README.md).
