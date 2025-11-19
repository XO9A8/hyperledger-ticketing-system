'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class BuyTicketWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.passengerId = '';
        this.seatNumbers = ['RAIL-A1', 'BUS-101', 'AIR-F1'];
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);

        // Register a passenger for this worker to use
        this.passengerId = `Passenger_Worker${workerIndex}_${Date.now()}`;
        const request = {
            contractId: 'ticketing',
            contractFunction: 'RegisterPassenger',
            contractArguments: [this.passengerId, `Worker${workerIndex}`, 'worker@example.com'],
            readOnly: false
        };

        console.log(`Worker ${workerIndex}: Registering passenger ${this.passengerId}`);
        try {
            await this.sutAdapter.sendRequests(request);
        } catch (error) {
            console.error(`Worker ${workerIndex}: Failed to register passenger: ${error}`);
        }
    }

    async submitTransaction() {
        // Pick a random seat
        const seat = this.seatNumbers[Math.floor(Math.random() * this.seatNumbers.length)];

        const request = {
            contractId: 'ticketing',
            contractFunction: 'BuyTicket',
            contractArguments: [seat, this.passengerId],
            readOnly: false
        };

        await this.sutAdapter.sendRequests(request);
    }
}

function createWorkloadModule() {
    return new BuyTicketWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
