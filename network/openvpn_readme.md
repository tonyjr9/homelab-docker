# Legacy OpenVPN Notes

The active remote-access VPN is WireGuard running on the Ubiquiti Gateway Max
(UGM). This Docker OpenVPN guide is retained only as historical reference and
should not be used for the current deployment.

Do not run a second VPN server unless its routes, firewall policy, DNS, and
port forwarding have been reviewed deliberately. The UGM owns the VPN
endpoint and controls access to the Management VLAN.

For the current design, see [Network Stack](README.md), especially:

- UGM WireGuard setup
- VLAN and inter-VLAN firewall policy
- Debian NetworkManager configuration using `br1.20`
- Home Assistant's bridge path to the IoT VLAN

Any old OpenVPN keys, client profiles, PKI, and generated configuration files
must remain outside Git and should be removed from hosts where the legacy
service is no longer used.
