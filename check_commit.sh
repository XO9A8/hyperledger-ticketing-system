#!/bin/bash
export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/config/

# Environment variables for Peer0 Railway
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="RailwayMSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/railway.example.com/peers/peer0.railway.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/railway.example.com/users/Admin@railway.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_SERVERHOSTOVERRIDE=peer0.railway.example.com

peer lifecycle chaincode querycommitted --channelID mychannel --name ticketing