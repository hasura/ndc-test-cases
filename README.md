# NDC Test Cases

This repository contains test cases for validating Native Database Connector (NDC) implementations against the NDC specification.

Connector authors are encouraged to use these preprepared test cases and test their connector implementations by importing the dataset 
included within this repo. Slight discrepancies might exist in the responses, but there should not be a major difference between your connector responses and the test cases in this repository.

Currently, only test cases for relational DBs exist in this repo and we are planning to add more test cases for different kinds of data sources 
like MongoDB etc.



## Overview

The test cases in this repository help verify that NDC implementations correctly handle various database operations and scenarios. 

The test suite currently includes relational database test cases and in the future, we will have additional test cases suited for other 
kinds of databases like NoSQL, document DBs etc.

## Structure

```
.
├── relational/              # Test cases for relational databases
│   ├── query/              # Query operation test cases
│   │   └── */             # Individual test cases
│   │       ├── request.json
│   │       └── expected.json
│   └── scripts/           # Helper scripts
└── static/                # Static test resources
    └── relational/       
        └── postgres/      # PostgreSQL specific resources
```

## Running Tests locally

This section provides an overview on how you can import the data on the postgres datasource and r
run tests on the Postgres connector.

### Prerequisites

- Docker and Docker Compose
- curl
- jq

### Setup

1. Clone the repository:
```bash
git clone https://github.com/hasura/ndc-test-cases
cd ndc-test-cases
```

2. Start PostgreSQL and the NDC connector:
```bash
cd static/relational/postgres
docker compose up -d
```

### Running NDC Tests 

Use the `ndc-test` CLI to run the test cases:

```bash
ndc-test replay --endpoint http://localhost:8080 --snapshots-dir relational
```

### GitHub Actions

The repository includes two GitHub Actions workflows:

1. **Main Branch Workflow**: Runs on pushes to main and manual triggers
2. **PR Workflow**: Runs on pull requests to main

Both workflows:
- Set up a PostgreSQL instance
- Configure and start the NDC Postgres connector
- Run the test suite on every commit

## Contributing

You can add a new test case by adding a new folder under the snapshot folder 

### Adding New Test Cases

Each test case should include:
1. `request.json`: The request to send to the NDC
2. `expected.json`: The expected response

Test cases should be atomic and focus on testing a specific functionality.


## Related Projects

- [NDC Spec](https://github.com/hasura/ndc-spec)
