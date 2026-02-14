#!/bin/bash

# Node Exporter Installation Script for Ubuntu EC2

# Author: Auto Script

# Usage: chmod +x node_exporter.sh && ./node_exporter.sh

set -e

echo "========================================="
echo "Installing Node Exporter..."
echo "========================================="

# Update system

echo "[1/8] Updating system packages..."
sudo apt update -y

# Create node_exporter user

echo "[2/8] Creating node_exporter user..."
if id "node_exporter" &>/dev/null; then
echo "User node_exporter already exists"
else
sudo useradd --no-create-home --shell /bin/false node_exporter
fi

# Download node exporter

echo "[3/8] Downloading Node Exporter..."
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/latest/download/node_exporter-1.8.2.linux-amd64.tar.gz

# Extract files

echo "[4/8] Extracting files..."
tar -xzf node_exporter-1.8.2.linux-amd64.tar.gz

# Move binary

echo "[5/8] Moving binary to /usr/local/bin..."
sudo mv node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/

# Set ownership

sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create systemd service

echo "[6/8] Creating systemd service..."
sudo bash -c 'cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd

echo "[7/8] Starting Node Exporter service..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Cleanup

echo "[8/8] Cleaning temporary files..."
rm -rf /tmp/node_exporter-1.8.2.linux-amd64*

# Check status

echo ""
echo "========================================="
echo "Node Exporter installation completed!"
echo "========================================="

sudo systemctl status node_exporter --no-pager

echo ""
echo "Metrics URL:"
echo "http://$(hostname -I | awk '{print $1}'):9100/metrics"
echo ""
echo "IMPORTANT: Make sure port 9100 is open in EC2 Security Group"
echo "========================================="
# ================================
# HOW TO USE THIS SCRIPT
# ================================

# Step 1: Create the script file
# --------------------------------
# nano node_exporter.sh
#
# Paste the script content
# Save and Exit:
#   Press CTRL + O  -> Press Enter
#   Press CTRL + X

# Step 2: Give execute permission
# --------------------------------
# chmod +x node_exporter.sh

# Step 3: Run the script
# --------------------------------
# ./node_exporter.sh

# Step 4: Verify Node Exporter status
# --------------------------------
# sudo systemctl status node_exporter
#
# You should see:
#    active (running)

# Step 5: Test in browser
# --------------------------------
# Open in browser:
# http://your-ec2-ip:9100/metrics
#
# Make sure port 9100 is open in EC2 Security Group.
# ================================


