#!/bin/bash
set -e

echo "=== VXLAN Tunnel Auto Setup ==="

# --- Detect current server public IPv4 ---
echo ">>> Detecting this server public IPv4..."
DETECTED_IP=$(curl -4 -s https://api.ipify.org || true)

if [[ -z "$DETECTED_IP" ]]; then
    echo "❌ Failed to detect public IPv4 automatically."
    read -p "Enter THIS server public IPv4 manually: " LOCAL_IP
else
    echo "Detected IPv4: $DETECTED_IP"
    read -p "Is this the public IP of THIS server? (y/n): " CONFIRM
    CONFIRM=$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]' | xargs)

    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "yes" ]]; then
        LOCAL_IP="$DETECTED_IP"
    else
        read -p "Enter THIS server public IPv4 manually: " LOCAL_IP
    fi
fi

# --- Destination server IP ---
read -p "Enter DESTINATION server public IPv4: " REMOTE_IP

# --- VXLAN ID ---
read -p "Enter VXLAN ID (example: 102): " VXLAN_ID

# --- Local VXLAN IP ---
read -p "Enter LOCAL VXLAN IP (example: 10.70.71.2/24): " LOCAL_VXLAN_IP

# --- MTU ---
read -p "Enter VXLAN MTU (default 1350): " VXLAN_MTU
VXLAN_MTU=${VXLAN_MTU:-1350}

# --- Base interface ---
read -p "Enter physical interface to use (default eth0): " PHY_IFACE
PHY_IFACE=${PHY_IFACE:-eth0}

# --- VXLAN name ---
read -p "Enter VXLAN name (press Enter for auto: vxlan1, vxlan2...): " CUSTOM_NAME
CUSTOM_NAME=$(echo "$CUSTOM_NAME" | xargs)

if [[ -z "$CUSTOM_NAME" ]]; then
    i=1
    while [[ -e /etc/systemd/system/vxlan$i.service ]]; do
        ((i++))
    done
    VXLAN_NAME="vxlan$i"
else
    VXLAN_NAME="$CUSTOM_NAME"
fi

SERVICE_FILE="/etc/systemd/system/${VXLAN_NAME}.service"

echo ">>> Flushing iptables (filter + nat)"
iptables -F
iptables -t nat -F
iptables -X

echo ">>> Creating systemd service: $SERVICE_FILE"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=VXLAN Tunnel $VXLAN_NAME
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes

ExecStart=/sbin/ip link add $VXLAN_NAME type vxlan id $VXLAN_ID local $LOCAL_IP remote $REMOTE_IP dstport 4789 dev $PHY_IFACE
ExecStart=/sbin/ip addr add $LOCAL_VXLAN_IP dev $VXLAN_NAME
ExecStart=/sbin/ip link set $VXLAN_NAME mtu $VXLAN_MTU
ExecStart=/sbin/ip link set $VXLAN_NAME up

ExecStop=/sbin/ip link set $VXLAN_NAME down
ExecStop=/sbin/ip link del $VXLAN_NAME

[Install]
WantedBy=multi-user.target
EOF

echo ">>> Enabling and starting VXLAN service"
systemctl daemon-reload
systemctl enable "$VXLAN_NAME"
systemctl start "$VXLAN_NAME"

echo
echo "✅ VXLAN Tunnel CREATED SUCCESSFULLY"
echo "------------------------------------"
echo "VXLAN Name : $VXLAN_NAME"
echo "Local IP   : $LOCAL_IP"
echo "Remote IP  : $REMOTE_IP"
echo "VXLAN IP   : $LOCAL_VXLAN_IP"
echo "VXLAN ID   : $VXLAN_ID"
echo "MTU        : $VXLAN_MTU"
echo "Persistent : YES (systemd)"
