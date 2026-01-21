# DistB-OT: Distributed Secure Blockchain-based Online Ticketing System

> A decentralized, multi-modal e-ticketing platform built on Hyperledger Fabric v3.1 with Chaincode-as-a-Service (CCaaS)

## 📖 Abstract

**DistB-OT** is a consortium blockchain solution designed to unify ticketing across **Railway**, **Airway**, and **Bus** transportation networks. By leveraging **Hyperledger Fabric**, the system eliminates centralized intermediaries, ensuring:
- **Immutability:** Ticket records cannot be tampered with.
- **Transparency:** All participating organizations share a single source of truth.
- **Security:** Cross-organization identity management via MSPs and TLS.

The system utilizes **Raft consensus** for ordering, **Chaincode-as-a-Service (CCaaS)** for external chaincode deployment, and **Go-based Smart Contracts** to manage passenger identities and ticket assets.

---

## 🏗 Network Architecture

| Component | Details |
|-----------|---------|
| **Ordering Service** | 1 Raft Orderer node (`orderer.example.com`) |
| **Organizations** | 3 Peer Orgs: **Railway**, **Airway**, **Bus** |
| **Peers** | `peer0.railway`, `peer0.airway`, `peer0.bus` |
| **Channel** | `mychannel` (Shared ledger) |
| **Chaincode** | External CCaaS container (`ticketing-ccaas`) |
| **Consensus** | Raft (Crash Fault Tolerance) |
| **Security** | Mutual TLS (mTLS) enabled |

---

## ⚡ Performance Tuning

To achieve high throughput (>300 TPS), the following optimizations were applied to the `docker-compose.yaml` peer configurations:

```yaml
environment:
  - CORE_PEER_LIMITS_CONCURRENCY_GATEWAYSERVICE=2500 # Default is 500
```

This prevents `EndorseError: 2 UNKNOWN: too many requests... exceeding concurrency limit` during high-load benchmarks.

---

## 🛠 Technologies Used

- **Blockchain:** Hyperledger Fabric v3.1
- **Smart Contracts:** Go (Golang) v1.20 with CCaaS
- **Containerization:** Docker & Docker Compose
- **Benchmarking:** Hyperledger Caliper v2.0.0
- **OS:** Linux / WSL2 (Ubuntu)

---

## � Test Environment

Benchmarks were conducted on the following hardware/software configuration:

| Component | Specification |
|-----------|---------------|
| **OS** | Ubuntu 24.04.3 LTS (Noble Numbat) |
| **CPU** | Intel® Core™ i9-14900K (32 vCPUs) |
| **RAM** | 16 GB |
| **Docker** | v29.1.3 |
| **Node.js** | v22.22.0 |
| **Optimization** | Gateway Concurrency Limit: 2500 |

---

## �📋 Prerequisites

- **Docker** & **Docker Compose**
- **Go** (v1.20 or higher)
- **Node.js** & **NPM** (for Caliper benchmarking)
- **Hyperledger Fabric Binaries** in `bin/` folder

---

## 🚀 Quick Start

### Deploy the Complete Network

```bash
# One-command deployment
./deploy-ccaas.sh
```

The deployment script automatically:
1. Builds the chaincode Docker image
2. Joins the orderer to `mychannel`
3. Joins all three peers to the channel
4. Packages and installs chaincode on all peers (CCaaS)
5. Starts the external chaincode container
6. Approves and commits the chaincode definition
7. Initializes the ledger with test data

---

## 🧩 Smart Contract Functions

### 1. Register Passenger
```bash
docker exec cli peer chaincode invoke \
  -o orderer.example.com:7050 --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C mychannel -n ticketing \
  -c '{"function":"RegisterPassenger","Args":["P001","John Doe","john@example.com"]}' \
  --peerAddresses peer0.railway.example.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt
```

### 2. Buy Ticket
```bash
docker exec cli peer chaincode invoke \
  -o orderer.example.com:7050 --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem \
  -C mychannel -n ticketing \
  -c '{"function":"BuyTicket","Args":["RAIL-A1","P001"]}' \
  --peerAddresses peer0.railway.example.com:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt
```

---

## 📊 Performance Benchmarking

Run Hyperledger Caliper benchmarks:

```bash
cd caliper-workspace
npx caliper launch manager \
  --caliper-workspace ./ \
  --caliper-networkconfig network.yaml \
  --caliper-benchconfig bench-config.yaml \
  --caliper-flow-only-test
```

### Benchmark Scenarios
1. **Register Passenger:** High-throughput write operations.
2. **Buy Ticket:** Validates ticket availability and ownership. Includes logic to **auto-create seats** if they don't exist, enabling high-throughput stress testing beyond the initial ledger size.

### Latest Results (RTX 3060 System)
- **Register Passenger:** ~301 TPS
- **Buy Ticket:** ~320 TPS

*Note: Performance was optimized by increasing `CORE_PEER_LIMITS_CONCURRENCY_GATEWAYSERVICE` to 2500.*

Results will be generated in `caliper-workspace/report.html`

---

## 📂 Project Structure

```text
hyperledger-ticketing-system/
├── bin/                    # Fabric binaries
├── configtx.yaml           # Channel definitions
├── crypto-config.yaml      # Identity (MSP) definitions
├── docker-compose.yaml     # Container infrastructure
├── deploy-ccaas.sh         # Automated CCaaS deployment script
├── chaincode/              # Smart Contract Source Code
│   └── ticketing/
│       ├── go.mod
│       ├── smartcontract.go
│       ├── Dockerfile      # Chaincode container build
│       ├── connection.json # CCaaS connection config
│       └── metadata.json   # CCaaS metadata
├── caliper-workspace/      # Benchmarking Configuration
│   ├── network.yaml
│   ├── bench-config.yaml
│   └── workload*.js
└── channel-artifacts/      # Generated blocks
```

---

## 🔧 Network Management

### Stop the Network
```bash
docker-compose down -v
docker rm -f ticketing-ccaas
```

### View Logs
```bash
# Peer logs
docker logs peer0.railway.example.com

# Chaincode logs
docker logs ticketing-ccaas

# Orderer logs
docker logs orderer.example.com
```

---

## 📄 License

This project is licensed under the Apache-2.0 License.
