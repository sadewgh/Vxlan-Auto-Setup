# VXLAN Auto Setup

**Simple interactive bash script** to quickly create a persistent VXLAN tunnel between two Linux servers (especially Ubuntu/Debian) using **systemd**.

Perfect for fast Layer-2 overlays between VPS instances, bare-metal servers, or homelab machines.

## Features

- Auto-detects your public IPv4 (with manual fallback)
- Interactive setup (just answer a few questions)
- Creates VXLAN interface + assigns IP
- Sets custom MTU (default 1350 to avoid fragmentation issues)
- Generates **persistent systemd service** (survives reboot)
- Automatically names service: `vxlan1`, `vxlan2`, … (or custom name)
- Flushes iptables filter + nat tables (for clean testing – optional in production)

## Requirements

- Linux server (Ubuntu / Debian recommended)
- Root privileges (`sudo`)
- `ip` command (from **iproute2** package – usually pre-installed)
- UDP port **4789** open / reachable between both servers
- Public IPv4 on both sides (or private IPs in the same network)

## Installation & Usage

1. Download the script

```bash
wget https://raw.githubusercontent.com/sadewgh/Vxlan-Auto-Setup/main/install.sh -O vxlan-setup.sh
# or
curl -fsSL https://raw.githubusercontent.com/sadewgh/Vxlan-Auto-Setup/main/install.sh -o vxlan-setup.sh
```

or quick install : 
```bash
bash <(curl -Ls --ipv4 https://raw.githubusercontent.com/sadewgh/Vxlan-Auto-Setup/main/install.sh)
```
## Example run

```bash
=== VXLAN Tunnel Auto Setup ===
>>> Detecting this server public IPv4...
Detected IPv4: 185.220.101.XXX
Is this the public IP of THIS server? (y/n): y

Enter DESTINATION server public IPv4:  45.76.222.XXX
Enter VXLAN ID (example: 102):         500
Enter LOCAL VXLAN IP (example: 10.70.71.2/24):  10.200.77.2/24
Enter VXLAN MTU (default 1350):        [Enter]
Enter physical interface to use (default eth0):  ens3
Enter VXLAN name (press Enter for auto: vxlan1...):  [Enter]
```



After success:

```bash

✅ VXLAN Tunnel CREATED SUCCESSFULLY
------------------------------------
VXLAN Name : vxlan1
Local IP   : 185.220.101.XXX
Remote IP  : 45.76.222.XXX
VXLAN IP   : 10.200.77.2/24
VXLAN ID   : 500
MTU        : 1350
Persistent : YES (systemd)
```
## Managing the Tunnel
```bash
# Check status
systemctl status vxlan1

# Restart tunnel
systemctl restart vxlan1

# Stop tunnel (temporary)
systemctl stop vxlan1

# Disable auto-start on boot
systemctl disable vxlan1

# Completely remove
sudo systemctl disable --now vxlan1
sudo rm /etc/systemd/system/vxlan1.service
sudo systemctl daemon-reload
```


## Important Security Notes
The script flushes iptables (iptables -F, -t nat -F, -X)
→ This is dangerous in production!
→ Comment out or remove these lines if you have important firewall rules.
VXLAN itself has no encryption.
Use it inside trusted networks or combine with:
WireGuard
IPsec
GRE + IPsec

You usually need to allow UDP 4789:

```bash
# iptables example
sudo iptables -I INPUT -p udp --dport 4789 -j ACCEPT

# or ufw
sudo ufw allow 4789/udp
```

Contributing
Pull requests welcome!
Especially interested in:

Non-interactive mode (command-line arguments)
IPv6 support
Better MTU / PMTUD handling
Automatic firewall rule suggestions
Error checking improvements

License
MIT License

Made for quick & easy VXLAN tunnels
Enjoy! 🚀
