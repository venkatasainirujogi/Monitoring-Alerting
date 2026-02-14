#!/bin/bash

# =====================================================

# Prometheus + Grafana + Alertmanager + Node Exporter

# Ubuntu All-in-One Installation Script

# =====================================================

set -e

echo "Updating system..."
sudo apt update -y
sudo apt install -y wget curl tar software-properties-common apt-transport-https

cd /opt

echo "Creating users..."
sudo useradd --no-create-home --shell /bin/false prometheus || true
sudo useradd --no-create-home --shell /bin/false alertmanager || true
sudo useradd --no-create-home --shell /bin/false node_exporter || true

# =====================================================

# Install Prometheus

# =====================================================

echo "Installing Prometheus..."

PROM_VERSION="2.48.0"

wget -q https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz

tar xvf prometheus-${PROM_VERSION}.linux-amd64.tar.gz

sudo mv prometheus-${PROM_VERSION}.linux-amd64 prometheus

sudo mkdir -p /opt/prometheus/data

# =====================================================

# Install Alertmanager

# =====================================================

echo "Installing Alertmanager..."

ALERT_VERSION="0.27.0"

wget -q https://github.com/prometheus/alertmanager/releases/download/v${ALERT_VERSION}/alertmanager-${ALERT_VERSION}.linux-amd64.tar.gz

tar xvf alertmanager-${ALERT_VERSION}.linux-amd64.tar.gz

sudo mv alertmanager-${ALERT_VERSION}.linux-amd64 alertmanager

# =====================================================

# Install Node Exporter

# =====================================================

echo "Installing Node Exporter..."

NODE_VERSION="1.8.2"

wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/node_exporter-${NODE_VERSION}.linux-amd64.tar.gz

tar xvf node_exporter-${NODE_VERSION}.linux-amd64.tar.gz

sudo mv node_exporter-${NODE_VERSION}.linux-amd64 node_exporter

# =====================================================

# Install Grafana

# =====================================================

echo "Installing Grafana..."

wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -

echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt update -y
sudo apt install grafana -y

# =====================================================

# Prometheus Config

# =====================================================

echo "Creating Prometheus config..."

sudo tee /opt/prometheus/prometheus.yml > /dev/null <<EOF
global:
scrape_interval: 15s

rule_files:

* "/opt/prometheus/alert.rules.yml"

alerting:
alertmanagers:
- static_configs:
- targets:
- "localhost:9093"

scrape_configs:

* job_name: "prometheus"
  static_configs:

  * targets: ["localhost:9090"]
    labels:
    target_server: "monitor-server"

* job_name: "node-exporter"
  static_configs:

  * targets: ["localhost:9100"]
    labels:
    target_server: "target-server"
    EOF

# =====================================================

# Alert Rules

# =====================================================

echo "Creating alert rules..."

sudo tee /opt/prometheus/alert.rules.yml > /dev/null <<EOF
groups:

* name: server-alerts

  rules:

  * alert: HighCPUUsage
    expr: 100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 40
    for: 1m
    labels:
    severity: critical
    annotations:
    summary: "High CPU on {{ $labels.instance }}"

  * alert: HighDiskUsage
    expr: (node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_free_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"} * 100 > 80
    for: 1m
    labels:
    severity: critical
    annotations:
    summary: "High Disk usage on {{ $labels.instance }}"

  * alert: NodeDown
    expr: up == 0
    for: 1m
    labels:
    severity: critical
    annotations:
    summary: "Node down {{ $labels.instance }}"

  * alert: HTTP400Errors
    expr: increase(http_requests_total{status="400"}[1m]) > 0
    for: 1m
    labels:
    severity: warning
    annotations:
    summary: "HTTP 400 errors detected"
    EOF

# =====================================================

# Alertmanager Config (PagerDuty)

# =====================================================

echo "Creating Alertmanager config..."

sudo tee /opt/alertmanager/alertmanager.yml > /dev/null <<EOF
global:
resolve_timeout: 5m

route:
receiver: pagerduty

receivers:

* name: pagerduty
  pagerduty_configs:

  * routing_key: "REPLACE_WITH_PAGERDUTY_KEY"
    description: "{{ .CommonAnnotations.summary }}"
    EOF

# =====================================================

# Systemd Services

# =====================================================

echo "Creating systemd services..."

sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus
After=network.target

[Service]
ExecStart=/opt/prometheus/prometheus --config.file=/opt/prometheus/prometheus.yml --storage.tsdb.path=/opt/prometheus/data
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<EOF
[Unit]
Description=Alertmanager
After=network.target

[Service]
ExecStart=/opt/alertmanager/alertmanager --config.file=/opt/alertmanager/alertmanager.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
ExecStart=/opt/node_exporter/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# =====================================================

# Start Services

# =====================================================

sudo systemctl daemon-reexec
sudo systemctl daemon-reload

sudo systemctl enable prometheus
sudo systemctl enable alertmanager
sudo systemctl enable node_exporter
sudo systemctl enable grafana-server

sudo systemctl start prometheus
sudo systemctl start alertmanager
sudo systemctl start node_exporter
sudo systemctl start grafana-server

# =====================================================

# Done

# =====================================================

echo "========================================"
echo "INSTALLATION COMPLETE"
echo "========================================"

echo "Prometheus: http://localhost:9090"
echo "Alertmanager: http://localhost:9093"
echo "Grafana: http://localhost:3000"

echo "Grafana login:"
echo "username: admin"
echo "password: admin"

echo "Replace PagerDuty key in:"
echo "/opt/alertmanager/alertmanager.yml"

#====================step-2====================for replacing key =========

#========================================================
#http://your-server-ip:9090 http://your-server-ip:9090     # "Checking  Prometheus "
#========================================================
#http://your-server-ip:3000     # "Checking  grafana"
#========================================================
#http://your-server-ip:9093

#========================================================
sudo vi /opt/alertmanager/alertmanager.yml
#===================REPLACE_WITH_PAGERDUTY_KEY===============
#========need to resatart the it=========================
sudo systemctl restart alertmanager
