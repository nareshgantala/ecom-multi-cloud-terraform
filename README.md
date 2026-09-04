# E-Commerce Multi-Cloud Microservices

An enterprise-grade, highly available microservices infrastructure deployment on Google Cloud Platform (GCP) provisioned with Terraform.

---

## Multi-Region Architecture Diagram

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

For in-depth deployment instructions, log troubleshooting, and GCP debugging procedures, see [terraform/gcp/README.md](terraform/gcp/README.md).
