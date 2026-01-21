package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing tickets
type SmartContract struct {
	contractapi.Contract
}

// Passenger describes the data for Use Case 1
type Passenger struct {
	ID             string `json:"id"`
	Name           string `json:"name"`
	Email          string `json:"email"`
	RegisteredTime string `json:"registeredTime"`
}

// Ticket describes the data for Use Case 2
type Ticket struct {
	SeatNumber string `json:"seatNumber"`
	OwnerID    string `json:"ownerID"`
	Price      int    `json:"price"`
	Status     string `json:"status"`  // "AVAILABLE" or "SOLD"
	OrgType    string `json:"orgType"` // "Railway", "Airway", or "Bus"
}

// InitLedger adds a few available seats to the ledger for testing
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	tickets := []Ticket{
		{SeatNumber: "RAIL-A1", OwnerID: "", Price: 50, Status: "AVAILABLE", OrgType: "Railway"},
		{SeatNumber: "BUS-101", OwnerID: "", Price: 20, Status: "AVAILABLE", OrgType: "Bus"},
		{SeatNumber: "AIR-F1", OwnerID: "", Price: 200, Status: "AVAILABLE", OrgType: "Airway"},
	}

	for _, ticket := range tickets {
		ticketJSON, err := json.Marshal(ticket)
		if err != nil {
			return err
		}
		err = ctx.GetStub().PutState(ticket.SeatNumber, ticketJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state. %v", err)
		}
	}

	return nil
}

// RegisterPassenger implements Use Case 1: One-Time Passenger Registration
// Matches "Step 1" in your Data Flow Diagram
func (s *SmartContract) RegisterPassenger(ctx contractapi.TransactionContextInterface, id string, name string, email string) error {
	exists, err := ctx.GetStub().GetState(id)
	if err != nil {
		return err
	}
	if exists != nil {
		return fmt.Errorf("the passenger %s already exists", id)
	}

	passenger := Passenger{
		ID:             id,
		Name:           name,
		Email:          email,
		RegisteredTime: time.Now().Format(time.RFC3339),
	}
	passengerJSON, err := json.Marshal(passenger)
	if err != nil {
		return err
	}

	// Writes the identity to the ledger, visible to all peers in the channel
	return ctx.GetStub().PutState(id, passengerJSON)
}

// BuyTicket implements Use Case 2: Ticket Purchase and Validation
// Matches "Step 2: Simulation & Endorsement" in your transaction lifecycle
func (s *SmartContract) BuyTicket(ctx contractapi.TransactionContextInterface, seatNumber string, passengerID string) error {

	// 1. Validate Passenger Exists
	passengerBytes, err := ctx.GetStub().GetState(passengerID)
	if err != nil {
		return err
	}
	if passengerBytes == nil {
		return fmt.Errorf("passenger %s does not exist", passengerID)
	}

	// 2. Get Ticket State (Read)
	ticketBytes, err := ctx.GetStub().GetState(seatNumber)
	if err != nil {
		return err
	}
	var ticket Ticket
	if ticketBytes == nil {
		// Auto-create seat for benchmark throughput
		ticket = Ticket{
			SeatNumber: seatNumber,
			OwnerID:    "",
			Price:      100,
			Status:     "AVAILABLE",
			OrgType:    "Benchmark",
		}
	} else {
		err = json.Unmarshal(ticketBytes, &ticket)
		if err != nil {
			return err
		}
	}

	// 3. Validate Logic (Smart Contract Rules)
	if ticket.Status == "SOLD" {
		return fmt.Errorf("seat %s is already sold", seatNumber)
	}

	// 4. Update State (Write/Endorse)
	ticket.Status = "SOLD"
	ticket.OwnerID = passengerID

	ticketJSON, err := json.Marshal(ticket)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(seatNumber, ticketJSON)
}

func main() {
	chaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		fmt.Printf("Error creating ticketing chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting ticketing chaincode: %s", err.Error())
	}
}
