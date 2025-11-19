'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class MyWorkload extends WorkloadModuleBase {
    constructor() {
        super();
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
    }

    async submitTransaction() {
        // Generate a random passenger ID
        const randomId = `Passenger_${Math.floor(Math.random() * 100000)}`;
        const randomName = `User${Math.floor(Math.random() * 1000)}`;

        // Call 'RegisterPassenger' from your chaincode
        const request = {
            contractId: 'ticketing',
            contractFunction: 'RegisterPassenger',
            contractArguments: [randomId, randomName, 'user@example.com'],
            readOnly: false
        };

        await this.sutAdapter.sendRequests(request);
    }
}

function createWorkloadModule() {
    return new MyWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;