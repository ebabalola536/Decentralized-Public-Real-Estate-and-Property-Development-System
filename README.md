# Decentralized Public Real Estate and Property Development System

A comprehensive blockchain-based system for managing public real estate operations, including affordable housing development, property assessments, zoning decisions, maintenance enforcement, and transaction recording.

## System Overview

This system consists of five interconnected smart contracts that handle different aspects of public real estate management:

### 1. Affordable Housing Development Contract (`affordable-housing.clar`)
- Manages construction projects for low-income housing
- Tracks project funding, progress, and allocation
- Handles tenant applications and unit assignments
- Monitors compliance with affordable housing requirements

### 2. Property Tax Assessment and Appeals Contract (`tax-assessment.clar`)
- Manages property valuations and tax assessments
- Handles assessment appeals and disputes
- Tracks assessment history and adjustments
- Calculates tax obligations based on assessed values

### 3. Land Use Planning and Zoning Contract (`zoning.clar`)
- Manages zoning classifications and regulations
- Handles zoning change requests and approvals
- Tracks land use permits and compliance
- Manages community development planning

### 4. Property Maintenance and Code Enforcement Contract (`maintenance.clar`)
- Tracks property maintenance requirements
- Manages code violation reports and enforcement
- Handles inspection schedules and results
- Monitors compliance with safety standards

### 5. Real Estate Transaction Recording Contract (`transactions.clar`)
- Records property sales and transfers
- Maintains secure ownership history
- Handles deed transfers and title changes
- Tracks transaction fees and taxes

## Key Features

- **Transparency**: All operations are recorded on the blockchain
- **Accountability**: Clear audit trails for all decisions and transactions
- **Efficiency**: Automated processes reduce bureaucratic delays
- **Fairness**: Standardized criteria and appeals processes
- **Security**: Immutable records prevent fraud and manipulation

## Data Structures

### Property Information
- Property ID (unique identifier)
- Address and location details
- Zoning classification
- Assessed value and tax status
- Ownership information
- Maintenance status

### Housing Projects
- Project ID and details
- Funding sources and amounts
- Construction timeline
- Unit allocations and tenant assignments
- Compliance status

### Assessment Records
- Current and historical valuations
- Assessment methodology
- Appeal history and outcomes
- Tax calculations and payments

## Access Control

The system implements role-based access control:
- **Administrators**: Full system access and configuration
- **Assessors**: Property valuation and tax assessment
- **Inspectors**: Maintenance and code enforcement
- **Planners**: Zoning and land use decisions
- **Citizens**: Property information access and appeals

## Getting Started

1. Deploy the contracts to a Stacks blockchain network
2. Initialize system parameters and administrator accounts
3. Configure zoning classifications and assessment criteria
4. Begin registering properties and managing operations

## Testing

The system includes comprehensive tests using Vitest to ensure all functionality works correctly:

\`\`\`bash
npm test
\`\`\`

## Contract Interactions

While contracts operate independently, they share common data structures and can reference each other's public data for comprehensive property management.

## Compliance and Regulations

The system is designed to support compliance with:
- Fair Housing Act requirements
- Property tax assessment standards
- Building codes and safety regulations
- Zoning and land use laws
- Public records and transparency requirements
