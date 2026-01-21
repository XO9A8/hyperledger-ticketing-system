#!/bin/bash
set -e

# Add local bin to PATH
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/config

echo "----------------------------------------------------------------"
echo "Step 0: Building Chaincode Docker Image"
echo "----------------------------------------------------------------"
docker build -t ticketing-ccaas:latest ./chaincode/ticketing

echo "----------------------------------------------------------------"
echo "Step 1: Joining Orderer to Channel 'mychannel' (if not joined)"
echo "----------------------------------------------------------------"
docker exec cli osnadmin channel join --channelID mychannel --config-block /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/genesis.block -o orderer.example.com:7053 --ca-file /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --client-cert /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/users/Admin@example.com/tls/client.crt --client-key /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/users/Admin@example.com/tls/client.key 2>/dev/null || echo "Orderer already joined"

echo "----------------------------------------------------------------"
echo "Step 2: Joining Peers to Channel 'mychannel' (if not joined)"
echo "----------------------------------------------------------------"
docker exec -e CORE_PEER_ADDRESS=peer0.railway.example.com:7051 -e CORE_PEER_LOCALMSPID=RailwayMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/users/Admin@railway.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt cli peer channel join -b ./channel-artifacts/genesis.block 2>/dev/null || echo "Railway already joined"

docker exec -e CORE_PEER_ADDRESS=peer0.airway.example.com:9051 -e CORE_PEER_LOCALMSPID=AirwayMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/users/Admin@airway.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/peers/peer0.airway.example.com/tls/ca.crt cli peer channel join -b ./channel-artifacts/genesis.block 2>/dev/null || echo "Airway already joined"

docker exec -e CORE_PEER_ADDRESS=peer0.bus.example.com:11051 -e CORE_PEER_LOCALMSPID=BusMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/users/Admin@bus.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/peers/peer0.bus.example.com/tls/ca.crt cli peer channel join -b ./channel-artifacts/genesis.block 2>/dev/null || echo "Bus already joined"

echo "----------------------------------------------------------------"
echo "Step 3: Packaging Chaincode (CCaaS)"
echo "----------------------------------------------------------------"
cd chaincode/ticketing
tar czf code.tar.gz connection.json
tar czf ticketing-ccaas.tar.gz code.tar.gz metadata.json
cd ../..
# Copy to a location accessible by the CLI container
docker cp chaincode/ticketing/ticketing-ccaas.tar.gz cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/

echo "----------------------------------------------------------------"
echo "Step 4: Installing Chaincode on All Peers"
echo "----------------------------------------------------------------"
# Install on Railway
echo "Installing on peer0.railway..."
docker exec -e CORE_PEER_ADDRESS=peer0.railway.example.com:7051 -e CORE_PEER_LOCALMSPID=RailwayMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/users/Admin@railway.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/ticketing-ccaas.tar.gz

# Install on Airway
echo "Installing on peer0.airway..."
docker exec -e CORE_PEER_ADDRESS=peer0.airway.example.com:9051 -e CORE_PEER_LOCALMSPID=AirwayMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/users/Admin@airway.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/peers/peer0.airway.example.com/tls/ca.crt cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/ticketing-ccaas.tar.gz

# Install on Bus
echo "Installing on peer0.bus..."
docker exec -e CORE_PEER_ADDRESS=peer0.bus.example.com:11051 -e CORE_PEER_LOCALMSPID=BusMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/users/Admin@bus.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/peers/peer0.bus.example.com/tls/ca.crt cli peer lifecycle chaincode install /opt/gopath/src/github.com/hyperledger/fabric/peer/ticketing-ccaas.tar.gz

echo "----------------------------------------------------------------"
echo "Step 5: Querying Package ID"
echo "----------------------------------------------------------------"
PACKAGE_ID=$(docker exec cli peer lifecycle chaincode queryinstalled | grep ticketing_1.0 | awk -F "Package ID: " '{print $2}' | awk -F "," '{print $1}')
echo "Package ID: $PACKAGE_ID"

echo "----------------------------------------------------------------"
echo "Step 6: Starting Chaincode Container with Package ID"
echo "----------------------------------------------------------------"
docker rm -f ticketing-ccaas 2>/dev/null || true
docker run -d --name ticketing-ccaas --network hyperledger-ticketing-system_test \
  -e CHAINCODE_SERVER_ADDRESS=0.0.0.0:9999 \
  -e CHAINCODE_ID=$PACKAGE_ID \
  -e CORE_CHAINCODE_ID_NAME=$PACKAGE_ID \
  ticketing-ccaas:latest

echo "Waiting for chaincode to start..."
sleep 5

echo "----------------------------------------------------------------"
echo "Step 7: Approving Chaincode Definition"
echo "----------------------------------------------------------------"
# Approve Railway
echo "Approving for Railway..."
docker exec -e CORE_PEER_ADDRESS=peer0.railway.example.com:7051 -e CORE_PEER_LOCALMSPID=RailwayMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/users/Admin@railway.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name ticketing --version 1.0 --package-id $PACKAGE_ID --sequence 1 --signature-policy "OR('RailwayMSP.peer','AirwayMSP.peer','BusMSP.peer')"

# Approve Airway
echo "Approving for Airway..."
docker exec -e CORE_PEER_ADDRESS=peer0.airway.example.com:9051 -e CORE_PEER_LOCALMSPID=AirwayMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/users/Admin@airway.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/peers/peer0.airway.example.com/tls/ca.crt cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name ticketing --version 1.0 --package-id $PACKAGE_ID --sequence 1 --signature-policy "OR('RailwayMSP.peer','AirwayMSP.peer','BusMSP.peer')"

# Approve Bus
echo "Approving for Bus..."
docker exec -e CORE_PEER_ADDRESS=peer0.bus.example.com:11051 -e CORE_PEER_LOCALMSPID=BusMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/users/Admin@bus.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/peers/peer0.bus.example.com/tls/ca.crt cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name ticketing --version 1.0 --package-id $PACKAGE_ID --sequence 1 --signature-policy "OR('RailwayMSP.peer','AirwayMSP.peer','BusMSP.peer')"

echo "----------------------------------------------------------------"
echo "Step 8: Committing Chaincode Definition"
echo "----------------------------------------------------------------"
docker exec cli peer lifecycle chaincode commit -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name ticketing --version 1.0 --sequence 1 --signature-policy "OR('RailwayMSP.peer','AirwayMSP.peer','BusMSP.peer')" --peerAddresses peer0.railway.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt --peerAddresses peer0.airway.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/peers/peer0.airway.example.com/tls/ca.crt --peerAddresses peer0.bus.example.com:11051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/peers/peer0.bus.example.com/tls/ca.crt

echo "----------------------------------------------------------------"
echo "Step 9: Initializing Ledger"
echo "----------------------------------------------------------------"
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n ticketing -c '{"function":"InitLedger","Args":[]}' --peerAddresses peer0.railway.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt --peerAddresses peer0.airway.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/peers/peer0.airway.example.com/tls/ca.crt --peerAddresses peer0.bus.example.com:11051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/peers/peer0.bus.example.com/tls/ca.crt

echo "Deployment Complete!"
