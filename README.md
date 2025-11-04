A blockchain-based carbon credit registry built on Stacks that ensures transparency, prevents double counting, and maintains an immutable audit trail for carbon credits.

## 🎯 Problem Solved

Current carbon markets suffer from:
- 🚫 Fraud and manipulation
- 🔄 Double counting of credits
- 👁️ Lack of transparency
- 📋 Poor audit trails

## ✨ Features

- 🏭 **Verified Issuer System** - Only authorized entities can issue carbon credits
- 🆔 **Unique Credit Tracking** - Each credit has a unique ID preventing double counting
- 📊 **Project Registration** - All carbon projects must be registered before issuing credits
- 🔄 **Secure Transfers** - Safe transfer mechanism with balance validation
- ♻️ **Credit Retirement** - Permanent retirement system to prevent reuse
- 📈 **Market Statistics** - Real-time market data and analytics
- 🔍 **Audit Trail** - Complete transaction history for each credit
- 🔒 **Credit Locking** - Temporarily lock credits to prevent transfers during compliance periods
- 🔄 **Credit Merging** - Combine multiple credits from the same project into a single credit for efficiency

## 🚀 Quick Start

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Installation

```bash
git clone <repository-url>
cd Carbon-Credit-Integrity---Double-Counting-Prevention
clarinet integrate
```

### Deploy to Testnet

```bash
clarinet deployments generate --testnet
clarinet deployments apply -p deployments/default.testnet-plan.yaml
```

## 📖 Usage

### 1. Add Verified Issuer (Admin Only)

```clarity
(contract-call? .carbon-credit-integrity add-verified-issuer 'SP1ABCD...)
```

### 2. Register Carbon Project

```clarity
(contract-call? .carbon-credit-integrity register-project 
    "FOREST-001" 
    "Amazon Rainforest Protection" 
    "Brazil" 
    "REDD+" 
    "VCS")
```

### 3. Issue Carbon Credits

```clarity
(contract-call? .carbon-credit-integrity issue-carbon-credit 
    "FOREST-001"  ; project-id
    u1000         ; amount (tons CO2)
    u2024         ; vintage year
    "REDD+"       ; methodology
    "VCS")        ; verification standard
```

### 4. Transfer Credits

```clarity
(contract-call? .carbon-credit-integrity transfer-carbon-credit 
    u1            ; credit-id
    'SP1BUYER...  ; recipient
    u500)         ; amount
```

### 5. Retire Credits

```clarity
(contract-call? .carbon-credit-integrity retire-carbon-credit
    u1            ; credit-id
    u500)         ; amount to retire
```

### 6. Lock Credits

```clarity
(contract-call? .carbon-credit-integrity lock-credit
    u1            ; credit-id
    u100000)      ; lock-until block height
```

### 7. Unlock Credits

```clarity
### 8. Merge Credits

```clarity
(contract-call? .carbon-credit-integrity merge-carbon-credits
    u1            ; credit-id-1
    u2)           ; credit-id-2
```
(contract-call? .carbon-credit-integrity unlock-credit u1)
```

## 🔍 Verification Functions

### Check Credit Authenticity

```clarity
(contract-call? .carbon-credit-integrity verify-credit-authenticity u1)
```

### Verify Double Counting Prevention

```clarity
(contract-call? .carbon-credit-integrity verify-double-counting-prevention u1)
```

### Get Market Statistics

```clarity
(contract-call? .carbon-credit-integrity get-market-statistics)
```

### Check Credit Lock Status

```clarity
(contract-call? .carbon-credit-integrity get-credit-lock u1)
```

## 📊 Data Structures

### Carbon Credit
- `issuer` - Original issuer principal
- `owner` - Current owner principal  
- `project-id` - Associated project identifier
- `vintage` - Year of carbon reduction
- `amount` - Tons of CO2 equivalent
- `methodology` - Carbon accounting methodology
- `is-retired` - Retirement status
- `verification-standard` - Standard used for verification

### Project Registration
- `issuer` - Project developer principal
- `name` - Project name
- `location` - Geographic location
- `methodology` - Carbon methodology used
- `verification-standard` - Verification standard applied

### Credit Lock
- `lock-until` - Block height until which the credit is locked
- 🔄 **Credit Merging** - Combine credits to reduce fragmentation and improve efficiency

## 🛡️ Security Features

- ✅ **Issuer Verification** - Only pre-approved issuers can create credits
- 🔒 **Ownership Validation** - Only owners can transfer their credits
- 🚫 **Double Spending Prevention** - Credits cannot be spent twice
- ♻️ **Permanent Retirement** - Retired credits cannot be reactivated
- 📋 **Project Validation** - Credits must reference registered projects
- 🔒 **Credit Locking** - Prevent transfers during specified periods

## 🧪 Testing

```bash
clarinet test
```

### Test Coverage
- ✅ Credit issuance validation
- ✅ Transfer authorization
- ✅ Retirement finality
- ✅ Double counting prevention
- ✅ Balance calculations
- ✅ Audit trail integrity

## 📝 Contract Functions

- `merge-carbon-credits` - Merge two credits from the same project into one
### Public Functions
- `add-verified-issuer` - Add authorized issuer (admin only)
- `remove-verified-issuer` - Remove issuer authorization (admin only)
- `register-project` - Register new carbon project
- `issue-carbon-credit` - Issue new carbon credits
- `transfer-carbon-credit` - Transfer credits between accounts
- `retire-carbon-credit` - Permanently retire credits
- `batch-retire-credits` - Retire multiple credits at once
- `bulk-issue-credits` - Issue multiple credits at once
- `lock-credit` - Lock a credit until specified block height
- `unlock-credit` - Unlock a credit after lock period expires

### Read-Only Functions
- `get-carbon-credit` - Get credit details
- `get-owner-balance` - Get owner's total balance
- `verify-credit-authenticity` - Verify credit is genuine
- `get-credit-audit-trail` - Get complete transaction history
- `get-market-statistics` - Get market overview data
- `verify-double-counting-prevention` - Check anti-double-counting measures
- `get-credit-lock` - Get lock status of a credit

## 🔧 Configuration

Update contract owner:
```clarity
(contract-call? .carbon-credit-integrity set-contract-owner 'SP1NEW...)
```

## 📈 Market Integration

The contract provides APIs for:
- 📊 Real-time market data
- 🔍 Credit verification
- 📋 Compliance reporting
- 🌐 Cross-platform integration

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit pull request

## 📄 License

MIT License - see LICENSE file for details

---

Built with ❤️ for a sustainable future 🌱
