#!/bin/bash

# ============================================
# Monitoring Target Setup Script
# Installs:
#   - Node Exporter
#   - Prometheus Alertmanager
# ============================================

set -e

echo "Updating system..."
sudo apt update -y

# ============================================
# Create users
# ============================================

echo "Creating users..."
sudo useradd --no-create-home --shell /bin/false node_exporter || true
sudo useradd --no-create-home --shell /bin/false alertmanager || true

# ============================================
# Install Node Exporter
# ============================================

echo "Installing Node Exporter..."
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/latest/download/node_exporter-1.8.2.linux-amd64.tar.gz
tar -xzf node_exporter-1.8.2.linux-amd64.tar.gz

sudo mv node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create Node Exporter service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ============================================
# Install Alertmanager
# ============================================

echo "Installing Alertmanager..."
cd /tmp
wget -q https://github.com/prometheus/alertmanager/releases/latest/download/alertmanager-0.27.0.linux-amd64.tar.gz
tar -xzf alertmanager-0.27.0.linux-amd64.tar.gz

sudo mkdir -p /etc/alertmanager
sudo mkdir -p /var/lib/alertmanager

sudo mv alertmanager-0.27.0.linux-amd64/alertmanager /usr/local/bin/
sudo mv alertmanager-0.27.0.linux-amd64/amtool /usr/local/bin/

sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager
sudo chown alertmanager:alertmanager /usr/local/bin/amtool

# Create default config
sudo tee /etc/alertmanager/alertmanager.yml > /dev/null <<EOF
global:
  resolve_timeout: 5m

route:
  receiver: "default"

receivers:
- name: "default"
EOF

sudo chown -R alertmanager:alertmanager /etc/alertmanager
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager

# Create Alertmanager service
sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<EOF
[Unit]
Description=Alertmanager
After=network.target

[Service]
User=alertmanager
Group=alertmanager
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# ============================================
# Start services
# ============================================

echo "Starting services..."

sudo systemctl daemon-reexec
sudo systemctl daemon-reload

sudo systemctl enable node_exporter
sudo systemctl start node_exporter

sudo systemctl enable alertmanager
sudo systemctl start alertmanager

# ============================================
# Status
# ============================================

echo ""
echo "=================================="
echo "Installation completed!"
echo "=================================="

echo "Node Exporter status:"
sudo systemctl status node_exporter --no-pager

echo ""
echo "Alertmanager status:"
sudo systemctl status alertmanager --no-pager

echo ""
echo "Access URLs:"
echo "Node Exporter:"
echo "http://$(hostname -I | awk '{print $1}'):9100/metrics"

echo ""
echo "Alertmanager:"
echo "http://$(hostname -I | awk '{print $1}'):9093"

echo ""
echo "IMPORTANT:"
echo "Open ports in EC2 Security Group:"
echo "9100 - Node Exporter"
echo "9093 - Alertmanager"

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


