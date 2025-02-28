# AetherStore
A decentralized e-commerce marketplace built on the Stacks blockchain.

## Features
- List products for sale
- Purchase products using STX
- Manage product inventory
- Review system for products
- Seller reputation tracking
- Escrow system for secure transactions

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to run test suite

## Usage Examples
```clarity
;; List a new product
(contract-call? .aether-store list-product "Cool Product" u1000 u10 "Description")

;; Purchase a product
(contract-call? .aether-store purchase-product u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Leave a review
(contract-call? .aether-store add-review u1 u5 "Great product!")
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
