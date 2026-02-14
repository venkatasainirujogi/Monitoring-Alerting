# Prometheus + Grafana + Alertmanager + Node Exporter Setup

This repository contains the setup for a full monitoring stack on Ubuntu EC2 instances using:

- **Prometheus** – Metrics collection and alerting
- **Grafana** – Dashboard visualization
- **Alertmanager** – Alert notifications (PagerDuty integration)
- **Node Exporter** – Server metrics collection

---

## **1. Prerequisites**

- Ubuntu 22.04 / 24.04 EC2 instances
- Sudo privileges
- Security groups open for:
  - Prometheus: `9090`
  - Alertmanager: `9093`
  - Node Exporter: `9100`
  - Grafana: `3000` (default web UI)

---

## **2. Installation**

1. Upload the script to your server:

```bash
scp grafana-prometheus.sh ubuntu@<SERVER_IP>:/home/ubuntu/
Make it executable and run:

chmod +x grafana-prometheus.sh
sudo ./grafana-prometheus.sh
This will install:

Prometheus

Grafana

Alertmanager

Node Exporter

3. Accessing the Web UIs
Use your server's public IP in the browser:

Component	URL	Default Ports
Prometheus	http://<PUBLIC_IP>:9090	9090
Grafana	http://<PUBLIC_IP>:3000	3000
Alertmanager	http://<PUBLIC_IP>:9093	9093
Node Exporter	http://<SERVER_IP>:9100/metrics	9100
Default Grafana login: admin / admin

Change password on first login

4. Prometheus Configuration
Targets: Prometheus scrapes metrics from Node Exporters installed on all servers.

Alerts (example):

InstanceDown: Triggered if a target is down for 1 minute

HighCPUUsage: Triggered if CPU usage > 40% for 2 minutes

HighDiskUsage: Triggered if disk usage > 80% for 2 minutes

UnauthorizedRequests: Triggered on 401/403 errors in last 5 minutes

Prometheus config file: /etc/prometheus/prometheus.yml

Alert rules: /etc/prometheus/alert.rules.yml

5. Alertmanager & PagerDuty
Alertmanager config: /etc/alertmanager/alertmanager.yml

PagerDuty integration configured via routing_key in Alertmanager

Alerts will fire based on Prometheus rules

6. Checking Installation
Prometheus Targets:
http://<PUBLIC_IP>:9090/targets
Check all servers; UP means reachable, DOWN means unreachable

Prometheus Alerts:
http://<PUBLIC_IP>:9090/alerts
Shows all active firing alerts

Node Exporter Metrics:
http://<SERVER_IP>:9100/metrics
Grafana Dashboards:
http://<PUBLIC_IP>:3000
Add Prometheus as a data source:
URL: http://<PUBLIC_IP>:9090

Alertmanager UI:
http://<PUBLIC_IP>:9093
7. Example Prometheus Query
Check if servers are up:

up
1 → server is up

0 → server is down

Check CPU usage:

100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
8. Restarting Services
sudo systemctl restart prometheus
sudo systemctl restart alertmanager
sudo systemctl restart node_exporter
sudo systemctl restart grafana-server
9. Notes
Make sure all EC2 security groups allow the required ports

Use public IP for Grafana/Prometheus access from browser

Use private IP for Node Exporter scraping by Prometheus
