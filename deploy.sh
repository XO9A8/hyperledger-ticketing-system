#!/bin/bash
set -e

# Add local bin to PATH
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/config

# Environment variables for Orderer Admin (Host paths)
export ORDERER_CA=${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export ORDERER_ADMIN_TLS_SIGN_CERT=${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/tls/client.crt
export ORDERER_ADMIN_TLS_PRIVATE_KEY=${PWD}/organizations/ordererOrganizations/example.com/users/Admin@example.com/tls/client.key

echo "----------------------------------------------------------------"
echo "Step 1: Joining Orderer to Channel 'mychannel'"
echo "----------------------------------------------------------------"
osnadmin channel join --channelID mychannel --config-block ./channel-artifacts/genesis.block -o localhost:7053 --ca-file "$ORDERER_CA" --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"

echo "----------------------------------------------------------------"
echo "Step 2: Joining Peers to Channel 'mychannel'"
echo "----------------------------------------------------------------"
# Peer0 Railway
echo "Joining peer0.railway..."
docker exec -e CORE_PEER_ADDRESS=peer0.railway.example.com:7051 -e CORE_PEER_LOCALMSPID=RailwayMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/users/Admin@railway.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt cli peer channel join -b ./channel-artifacts/genesis.block

# Peer0 Airway
echo "Joining peer0.airway..."
docker exec -e CORE_PEER_ADDRESS=peer0.airway.example.com:9051 -e CORE_PEER_LOCALMSPID=AirwayMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/users/Admin@airway.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/peers/peer0.airway.example.com/tls/ca.crt cli peer channel join -b ./channel-artifacts/genesis.block

# Peer0 Bus
echo "Joining peer0.bus..."
docker exec -e CORE_PEER_ADDRESS=peer0.bus.example.com:11051 -e CORE_PEER_LOCALMSPID=BusMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/users/Admin@bus.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/peers/peer0.bus.example.com/tls/ca.crt cli peer channel join -b ./channel-artifacts/genesis.block

echo "----------------------------------------------------------------"
echo "Step 3: Packaging Chaincode"
echo "----------------------------------------------------------------"
docker exec cli peer lifecycle chaincode package ticketing.tar.gz --path /opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode/ticketing --lang golang --label ticketing_1.0

echo "----------------------------------------------------------------"
echo "Step 4: Installing Chaincode on All Peers"
echo "----------------------------------------------------------------"
# Install on Railway
echo "Installing on peer0.railway..."
docker exec -e CORE_PEER_ADDRESS=peer0.railway.example.com:7051 -e CORE_PEER_LOCALMSPID=RailwayMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/users/Admin@railway.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt cli peer lifecycle chaincode install ticketing.tar.gz

# Install on Airway
echo "Installing on peer0.airway..."
docker exec -e CORE_PEER_ADDRESS=peer0.airway.example.com:9051 -e CORE_PEER_LOCALMSPID=AirwayMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/users/Admin@airway.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/peers/peer0.airway.example.com/tls/ca.crt cli peer lifecycle chaincode install ticketing.tar.gz

# Install on Bus
echo "Installing on peer0.bus..."
docker exec -e CORE_PEER_ADDRESS=peer0.bus.example.com:11051 -e CORE_PEER_LOCALMSPID=BusMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/users/Admin@bus.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/peers/peer0.bus.example.com/tls/ca.crt cli peer lifecycle chaincode install ticketing.tar.gz

echo "----------------------------------------------------------------"
echo "Step 5: Querying Package ID"
echo "----------------------------------------------------------------"
PACKAGE_ID=$(docker exec cli peer lifecycle chaincode queryinstalled | grep ticketing_1.0 | awk -F "Package ID: " '{print $2}' | awk -F "," '{print $1}')
echo "Package ID: $PACKAGE_ID"

echo "----------------------------------------------------------------"
echo "Step 6: Approving Chaincode Definition"
echo "----------------------------------------------------------------"
# Approve Railway
echo "Approving for Railway..."
docker exec -e CORE_PEER_ADDRESS=peer0.railway.example.com:7051 -e CORE_PEER_LOCALMSPID=RailwayMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/users/Admin@railway.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name ticketing --version 1.0 --package-id $PACKAGE_ID --sequence 1

# Approve Airway
echo "Approving for Airway..."
docker exec -e CORE_PEER_ADDRESS=peer0.airway.example.com:9051 -e CORE_PEER_LOCALMSPID=AirwayMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/users/Admin@airway.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/peers/peer0.airway.example.com/tls/ca.crt cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name ticketing --version 1.0 --package-id $PACKAGE_ID --sequence 1

# Approve Bus
echo "Approving for Bus..."
docker exec -e CORE_PEER_ADDRESS=peer0.bus.example.com:11051 -e CORE_PEER_LOCALMSPID=BusMSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/users/Admin@bus.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/peers/peer0.bus.example.com/tls/ca.crt cli peer lifecycle chaincode approveformyorg -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name ticketing --version 1.0 --package-id $PACKAGE_ID --sequence 1

echo "----------------------------------------------------------------"
echo "Step 7: Committing Chaincode Definition"
echo "----------------------------------------------------------------"
docker exec cli peer lifecycle chaincode commit -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --channelID mychannel --name ticketing --version 1.0 --sequence 1 --peerAddresses peer0.railway.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt --peerAddresses peer0.airway.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/peers/peer0.airway.example.com/tls/ca.crt --peerAddresses peer0.bus.example.com:11051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/peers/peer0.bus.example.com/tls/ca.crt

echo "----------------------------------------------------------------"
echo "Step 8: Initializing Ledger"
echo "----------------------------------------------------------------"
docker exec cli peer chaincode invoke -o orderer.example.com:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n ticketing -c '{"function":"InitLedger","Args":[]}' --peerAddresses peer0.railway.example.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt --peerAddresses peer0.airway.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/airway.example.com/peers/peer0.airway.example.com/tls/ca.crt --peerAddresses peer0.bus.example.com:11051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/bus.example.com/peers/peer0.bus.example.com/tls/ca.crt

echo "Deployment Complete!"
