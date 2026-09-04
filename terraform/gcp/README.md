# E-Commerce Multi-Cloud Microservices on Google Cloud Platform (GCP)

This document details the end-to-end architecture, networking flow, and step-by-step troubleshooting and log-checking procedures for the RoboShop microservices infrastructure provisioned via Terraform on Google Cloud.

---

## Architecture Diagram

```mermaid
graph TD
    Client([Public Internet Client]) -->|HTTP Port 80| ExtALB["External Application Load Balancer\nGlobal Anycast IP: 34.160.195.31"]

    subgraph VPC ["GCP VPC: roboshop-project-demo-vpc (Global Private Network)"]

        subgraph RegionWest ["Region: us-west1 (Oregon)"]
            subgraph FrontendSubnet ["Frontend Subnet [10.1.0.0/24]"]
                ExtALB -->|Port 80| FrontVM["Frontend Nginx MIG\nPrivate IP: 10.1.0.2 : Port 80"]
            end

            subgraph ProxySubnet ["Proxy-Only Subnet [10.128.0.0/24]"]
                Envoy["Regional Envoy Proxy Pool"]
            end

            subgraph AppSubnet ["App Subnet [10.2.0.0/24]"]
                SharedILB["Regional Shared Internal ALB (ILB)\nVIP: 10.2.0.x : Port 80"]

                SharedILB --- Envoy

                Envoy -->|"catalogue.naresh-training.online:80"| CatMIG["Catalogue Service : 8002\nIP: 10.2.0.6"]
                Envoy -->|"user.naresh-training.online:80"| UserMIG["User Service : 8001\nIP: 10.2.0.3"]
                Envoy -->|"cart.naresh-training.online:80"| CartMIG["Cart Service : 8003\nIP: 10.2.0.4"]
                Envoy -->|"shipping.naresh-training.online:80"| ShipMIG["Shipping Service : 8004\nIP: 10.2.0.9"]
                Envoy -->|"payment.naresh-training.online:80"| PayMIG["Payment Service : 8005\nIP: 10.2.0.5"]
                Envoy -->|"ratings.naresh-training.online:80"| RateMIG["Ratings Service : 8006\nIP: 10.2.0.7"]
                Envoy -->|"orders.naresh-training.online:80"| OrderMIG["Orders Service : 8007\nIP: 10.2.0.8"]
            end

            NatWest["Cloud NAT & Router (us-west1)\nOutbound Internet Access"] -.-> FrontendSubnet
            NatWest -.-> AppSubnet
        end

        subgraph RegionCentral ["Region: us-central1 (Iowa)"]
            subgraph DatabaseSubnet ["Database Subnet [10.4.0.0/24]"]
                MySQL[("MySQL / MariaDB 10.11\nStatic IP: 10.4.0.10 : Port 3306")]
                Valkey[("Valkey / Redis\nStatic IP: 10.4.0.11 : Port 6379")]
                RabbitMQ[("RabbitMQ Message Broker\nStatic IP: 10.4.0.12 : Port 5672")]
                MongoDB[("MongoDB 7.0\nStatic IP: 10.4.0.13 : Port 27017")]
            end

            NatCentral["Cloud NAT & Router (us-central1)\nOutbound Internet Access"] -.-> DatabaseSubnet
        end

        %% Frontend to ILB
        FrontVM -->|"API Calls via ILB VIP"| SharedILB

        %% Cross-Region Private VPC Communication (us-west1 -> us-central1)
        CatMIG -->|"mysql.naresh-training.online:3306"| MySQL
        ShipMIG -->|"mysql.naresh-training.online:3306"| MySQL
        RateMIG -->|"mysql.naresh-training.online:3306"| MySQL

        CartMIG -->|"valky.naresh-training.online:6379"| Valkey

        OrderMIG -->|"rabbitmq.naresh-training.online:5672"| RabbitMQ
        PayMIG -->|"rabbitmq.naresh-training.online:5672"| RabbitMQ

        UserMIG -->|"mongodb.naresh-training.online:27017"| MongoDB
        OrderMIG -->|"mongodb.naresh-training.online:27017"| MongoDB
    end

    subgraph CloudDNS ["Cloud DNS Managed Zone: naresh-training.online"]
        DNSApps["App Records (*.naresh-training.online -> ILB VIP 10.2.0.x)"]
        DNSDBs["DB Records (*.naresh-training.online -> 10.4.0.10-13)"]
    end
```

---

## Traffic Flow Summary

1. **Client to Frontend**:
   * Users hit `http://naresh-training.online` or `http://34.160.195.31`.
   * The **Global External HTTP Load Balancer** proxies internet traffic to the **Frontend Nginx MIG** in `us-west1` on port 80.

2. **Frontend to Microservices**:
   * Frontend Nginx proxies API calls (e.g., `/api/catalogue/`) to `http://catalogue.naresh-training.online:80`.
   * Cloud DNS resolves `*.naresh-training.online` to the **Internal Application Load Balancer (ILB)** private VIP in `10.2.0.0/24`.
   * The ILB uses **Host-based routing** via Envoy to forward requests to the appropriate application MIG on its respective internal port (`8001` - `8007`).

3. **Microservices to Databases (Cross-Region Private VPC)**:
   * App services in `us-west1` query Cloud DNS for database endpoints (`mysql`, `valky`, `rabbitmq`, `mongodb`).
   * Cloud DNS maps to the reserved static internal IPs (`10.4.0.10` - `10.4.0.13`) located in the `us-central1` database subnet (`10.4.0.0/24`).
   * Traffic flows seamlessly across Google's private global backbone between `us-west1` and `us-central1` without traversing the public internet.
   * VPC Firewall permits TCP traffic directly from `app` VMs to `database` VMs on required ports (`3306`, `6379`, `5672`, `27017`).

---

## Service Port & IP Reference Table

| Tier | Component | Machine Type | Region | Subnet CIDR | IP / VIP | Port |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **External** | External ALB | Global Managed | Global | N/A | `34.160.195.31` | `80` |
| **Frontend** | `frontend` | `e2-small` | `us-west1` | `10.1.0.0/24` | `10.1.0.2` (DHCP) | `80` (Nginx) |
| **Internal LB** | Shared App ILB | Regional Managed | `us-west1` | `10.2.0.0/24` | Reserved ILB IP | `80` |
| **ILB Proxy** | Envoy Proxy Pool | Regional Managed | `us-west1` | `10.128.0.0/24` | Regional Proxy Subnet | Ephemeral |
| **App** | `user` | `e2-small` | `us-west1` | `10.2.0.0/24` | `10.2.0.3` | `8001` |
| **App** | `cart` | `e2-small` | `us-west1` | `10.2.0.0/24` | `10.2.0.4` | `8003` |
| **App** | `payment` | `e2-small` | `us-west1` | `10.2.0.0/24` | `10.2.0.5` | `8005` |
| **App** | `catalogue` | `e2-small` | `us-west1` | `10.2.0.0/24` | `10.2.0.6` | `8002` |
| **App** | `ratings` | `e2-small` | `us-west1` | `10.2.0.0/24` | `10.2.0.7` | `8006` |
| **App** | `orders` | `e2-small` | `us-west1` | `10.2.0.0/24` | `10.2.0.8` | `8007` |
| **App** | `shipping` | `e2-small` | `us-west1` | `10.2.0.0/24` | `10.2.0.9` | `8004` |
| **Database** | `mysql` (MariaDB 10.11) | `e2-small` | `us-central1` | `10.4.0.0/24` | `10.4.0.10` (Static) | `3306` |
| **Database** | `valky` (Redis) | `e2-small` | `us-central1` | `10.4.0.0/24` | `10.4.0.11` (Static) | `6379` |
| **Database** | `rabbitmq` | `e2-small` | `us-central1` | `10.4.0.0/24` | `10.4.0.12` (Static) | `5672` |
| **Database** | `mongodb` (Mongo 7.0) | `e2-small` | `us-central1` | `10.4.0.0/24` | `10.4.0.13` (Static) | `27017` |

---

## Log Checking & Troubleshooting Guide

### 1. Connecting to Any VM
You can connect securely using Google Cloud Identity-Aware Proxy (IAP) without needing a public IP:

```bash
# Connect using gcloud CLI:
gcloud compute ssh <INSTANCE_NAME> --zone=<ZONE> --tunnel-through-iap

# Example:
gcloud compute ssh roboshop-project-demo-frontend-igm-instance-xxxx --zone=us-west1-a --tunnel-through-iap
```

---

### 2. Checking the GCP Startup Script Logs
When a VM boots, GCP's metadata script runner executes your provisioning script (`frontend.sh`, `catalogue.sh`, etc.).

```bash
# View the entire startup script log
sudo journalctl -u google-startup-scripts.service --no-pager

# Stream/follow the startup script output live as it runs
sudo journalctl -u google-startup-scripts.service -f

# Filter startup logs from system messages
sudo grep "startup-script" /var/log/messages | less
```

---

### 3. Checking Application Service Logs (Systemd)

Check service status:
```bash
sudo systemctl status <service-name>

# Examples:
sudo systemctl status nginx
sudo systemctl status catalogue
sudo systemctl status cart
sudo systemctl status orders
sudo systemctl status valkey
sudo systemctl status mysqld
sudo systemctl status mongod
sudo systemctl status rabbitmq-server
```

Live stream service logs:
```bash
# Follow logs in real-time (-f) showing the last 100 lines (-n 100)
sudo journalctl -u <service-name> -f -n 100

# Examples:
sudo journalctl -u catalogue -f -n 100
sudo journalctl -u orders -f -n 100
sudo journalctl -u nginx -f -n 100
```

---

### 4. Checking Nginx Web Server Logs (Frontend VM)

```bash
# Check Nginx error log (crucial for 404, 502 Bad Gateway, 503 Service Unavailable)
sudo tail -f /var/log/nginx/error.log

# Check Nginx access log (shows live client requests)
sudo tail -f /var/log/nginx/access.log
```

---

### 5. Checking Load Balancer Health Status from your Local Terminal

To check if backends are healthy according to Google Cloud:

```bash
# Check External Frontend Load Balancer backend health:
gcloud compute backend-services get-health backend --global

# Check Internal Application Load Balancer backend health:
gcloud compute backend-services get-health roboshop-project-demo-catalogue-backend --region=us-west1
gcloud compute backend-services get-health roboshop-project-demo-orders-backend --region=us-west1
```

---

### 6. Checking Serial Port Logs without SSHing into the VM

If a VM fails to boot or SSH is unreachable, you can view the live console output directly:

```bash
gcloud compute instances get-serial-port-output <INSTANCE_NAME> --zone=<ZONE>
```

---

## Common Gotchas & Architectural Solutions

| Issue | Root Cause | Solution |
| :--- | :--- | :--- |
| **`Quota 'INSTANCES' exceeded (Limit: 8.0)`** | Default quota limit of 8 instances in region `us-west1`. | Split stateful databases to secondary region (`us-central1`), connected privately via VPC. |
| **`maxSurge and maxUnavailable cannot both be 0`** | Regional MIG update policy validation failure. | Set `max_surge_fixed = 0` and `max_unavailable_fixed = 3` with `update_policy { type = "OPPORTUNISTIC" }`. |
| **`Subnetwork proxy-subnet is already being used`** | Forwarding rule not fully torn down when subnet destroyed. | Add `depends_on = [google_compute_subnetwork.proxy_subnet]` to the ILB forwarding rule. |
| **`unconditional drop overload`** | 0 instances in the backend group. | Check MIG instances; ensure disk type matches machine type (`pd-balanced` for `e2`). |
| **`503 no healthy upstream`** | Health check failed on port 80. | Check `journalctl -u google-startup-scripts.service`; ensure Nginx started and served `index.html`. |
| **`None of the backends have a valid capacity`** | `balancing_mode = "UTILIZATION"` missing metrics. | Add `max_utilization = 0.8` and `capacity_scaler = 1.0` in the backend block. |
| **`Instance Template in use by IGM`** | Destroy-then-create ordering conflict. | Use `name_prefix = "*-tmpl-"` and `lifecycle { create_before_destroy = true }`. |
