# Car Wash and Detailing Services - Clarity Smart Contract System

A comprehensive blockchain-based car wash and detailing service management system built on Stacks using Clarity smart contracts.

## System Overview

This system manages all aspects of a car wash and detailing business through five interconnected smart contracts:

### Core Contracts

1. **appointments.clar** - Appointment scheduling and management
2. **services.clar** - Service packages and pricing management
3. **loyalty.clar** - Customer loyalty program and rewards
4. **mobile.clar** - Mobile service coordination and location management
5. **fleet.clar** - Fleet services and commercial account management

## Features

### Appointment Management
- Schedule appointments with time slots
- Service package selection
- Customer information tracking
- Appointment status updates (scheduled, in-progress, completed, cancelled)

### Service Packages
- Predefined service packages (Basic Wash, Premium Detail, etc.)
- Dynamic pricing management
- Service duration tracking
- Quality verification system

### Loyalty Program
- Points accumulation based on spending
- Tier-based rewards (Bronze, Silver, Gold, Platinum)
- Discount application
- Referral bonuses

### Mobile Services
- Location-based service coordination
- Mobile unit assignment
- Travel time and distance calculations
- Service area management

### Fleet Management
- Commercial account setup
- Bulk appointment scheduling
- Volume discounts
- Fleet-specific service packages

## Contract Architecture

Each contract is designed to be independent while working together to provide a complete service management solution:

- **Data Isolation**: Each contract manages its own data domain
- **Event Logging**: Comprehensive event logging for all major actions
- **Error Handling**: Robust error codes and validation
- **Access Control**: Owner-only functions for administrative tasks

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm for testing
- Stacks wallet for deployment

### Installation
\`\`\`bash
npm install
clarinet check
clarinet test
\`\`\`

### Testing
\`\`\`bash
npm test
\`\`\`

### Deployment
\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Scheduling an Appointment
```clarity
(contract-call? .appointments schedule-appointment 
  u1 ;; service-id
  u1640995200 ;; timestamp
  "John Doe" ;; customer-name
  "john@example.com" ;; customer-email
  "555-0123") ;; customer-phone
