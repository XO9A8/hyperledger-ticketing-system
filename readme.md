# DistB-OT: Distributed Secure Blockchain-based Online Ticketing System

> A decentralized, multi-modal e-ticketing platform built on Hyperledger Fabric.

## 📖 Abstract

**DistB-OT** is a consortium blockchain solution designed to unify ticketing across **Railway**, **Airway**, and **Bus** transportation networks. By leveraging **Hyperledger Fabric**, the system eliminates centralized intermediaries, ensuring:
- **Immutability:** Ticket records cannot be tampered with.
- **Transparency:** All participating organizations share a single source of truth.
- **Security:** Cross-organization identity management via MSPs and TLS.

The system utilizes **Raft consensus** (Crash Fault Tolerance) for ordering and **Go-based Smart Contracts** to manage the lifecycle of passenger identities and ticket assets.

---

## �� Network Architecture

The network topology is designed for high availability and decentralized governance:

| Component | Details |
|-----------|---------|
| **Ordering Service** | 1 Raft Orderer node (`orderer.example.com`) |
| **Organizations** | 3 Peer Orgs: **Railway**, **Airway**, **Bus** |
| **Peers** | `peer0.railway`, `peer0.airway`, `peer0.bus` |
| **Channel** | `mychannel` (Shared ledger) |
| **Consensus** | Raft (Crash Fault Tolerance) |
| **Security** | Mutual TLS (mTLS) enabled |

---

## 🛠 Technologies Used

- **Blockchain:** Hyperledger Fabric v3.1
- **Smart Contracts:** Go (Golang) v1.20
- **Containerization:** Docker & Docker Compose
- **Benchmarking:** Hyperledger Caliper v0.5.0
- **OS:** Linux / WSL2 (Ubuntu)

---

## 📋 Prerequisites

Before running the network, ensure you have the following installed:

- **Docker** & **Docker Compose**
- **Go** (v1.20 or higher)
- **Node.js** & **NPM** (for Caliper workload scripts)
- **Hyperledger Fabric Binaries** (`cryptogen`, `configtxgen`, `peer`, etc.) added to your PATH or in the `bin/` folder.

---

## 🚀 Getting Started

### 1. Infrastructure Setup
Generate the cryptographic material (certs) and the genesis block to bootstrap the network trust layer.

```bash
# Generate Crypto Materials (MSPs and TLS certs)
./bin/cryptogen generate --config=./crypto-config.yaml --output="organizations"

# Generate Genesis Block
./bin/configtxgen -profile TicketingNetworkGenesis -outputBlock ./channel-artifacts/genesis.block -channelID mychannel
```

### 2. Launch the Network
Spin up the containers (Orderer, Peers, CLIs) using Docker Compose.

```bash
docker-compose up -d
```

### 3. Deploy Chaincode
(Note: These steps are typically handled by a script, e.g., `install-fabric.sh` or manual peer commands)
1.  **Package** the Go chaincode.
2.  **Install** on all peers (`peer0.railway`, `peer0.airway`, `peer0.bus`).
3.  **Approve** the definition for each organization.
4.  **Commit** the chaincode definition to the channel.

---

## 🧩 Smart Contract Logic

The business logic (`chaincode/ticketing/`) supports two primary use cases:

### 1. Passenger Registration (`RegisterPassenger`)
- **Input:** `ID`, `Name`, `Email`
- **Logic:** Creates a verifiable digital identity on the ledger.
- **Constraint:** Prevents duplicate registrations for the same ID.

### 2. Ticket Purchase (`BuyTicket`)
- **Input:** `SeatNumber`, `PassengerID`
- **Logic:**
    1.  Verifies `PassengerID` exists.
    2.  Checks if `SeatNumber` is `AVAILABLE`.
    3.  Transfers ownership and updates status to `SOLD`.
- **Constraint:** Prevents double-booking via endorsement policies.

---

## 📊 Performance Benchmarking

We use **Hyperledger Caliper** to stress-test the network.

### Benchmark Scenarios
1.  **Register Passenger:** High-throughput write operations.
2.  **Buy Ticket:** High-contention state updates (simulating race conditions).

### Running the Benchmark
Execute the following command from the root directory:

```bash
docker run --network research-fabric_test --name caliper --rm \
-v $(pwd)/caliper-workspace:/hyperledger/caliper/workspace \
-v $(pwd)/organizations:/hyperledger/caliper/organizations \
hyperledger/caliper:0.5.0 launch manager \
--caliper-workspace /hyperledger/caliper/workspace \
--caliper-networkconfig network.yaml \
--caliper-benchconfig bench-config.yaml \
--caliper-flow-only-test \
--caliper-bind-sut fabric:2.2
```

> **Note:** Ensure the Docker network name (`research-fabric_test`) matches your actual running network.

---

## 📂 Project Structure

```text
distb-ot-network/
├── bin/                    # Fabric binaries
├── configtx.yaml           # Channel definitions
├── crypto-config.yaml      # Identity (MSP) definitions
├── docker-compose.yaml     # Container infrastructure
├── chaincode/              # Smart Contract Source Code
│   └── ticketing/
│       ├── go.mod
│       └── smartcontract.go
├── caliper-workspace/      # Benchmarking Configuration
│   ├── network.yaml        # Connection profile
│   ├── bench-config.yaml   # Test rounds & rate control
│   ├── workload.js         # Workload: RegisterPassenger
│   └── workload-buyTicket.js # Workload: BuyTicket
└── channel-artifacts/      # Generated blocks & tx files
```

---

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## 📄 License

This project is licensed under the Apache-2.0 License.
