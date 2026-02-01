# Audit Submission Checklist

## Contracts in Scope

### Primary Audit Targets

| # | Contract | Path | Lines |
|---|----------|------|-------|
| 1 | WorldLandNativeToken | `token_contracts/contracts/MyToken.sol` | ~14 |
| 2 | VestingWallet | `vesting_contracts/finance/VestingWallet.sol` | ~160 |
| 3 | VestingWalletCliff | `vesting_contracts/finance/VestingWalletCliff.sol` | ~54 |

**Total Lines of Code (Custom):** ~228 lines

### Dependencies (OpenZeppelin - Out of Scope)

These are standard OpenZeppelin contracts, typically excluded from audit scope:

- ERC20.sol, IERC20.sol, IERC20Metadata.sol
- Ownable.sol, Context.sol, SafeERC20.sol
- Address.sol, Errors.sol, SafeCast.sol

---

## Required Submission Documents

### 1. Source Code
- [ ] All `.sol` files in `token_contracts/contracts/`
- [ ] All `.sol` files in `vesting_contracts/`
- [ ] Flatten contracts if required (use `forge flatten` or Remix)

### 2. Technical Documentation
- [ ] README.md (included)
- [ ] Contract architecture diagram (optional)
- [ ] Token economics / vesting schedule documentation

### 3. Deployment Information
- [ ] Target network(s): (e.g., Ethereum Mainnet, Polygon, etc.)
- [ ] Compiler version: `0.8.27`
- [ ] Optimizer settings: `enabled`, `200 runs`
- [ ] EVM version: `Paris` or later

### 4. Test Suite
- [ ] Unit tests (if available)
- [ ] Test coverage report
- [ ] `token_contracts/tests/MyToken_test.sol` (Remix test)

### 5. Known Issues / Assumptions
- [ ] Document any known limitations
- [ ] Document design decisions
- [ ] Document trust assumptions

---

## Information to Provide to Auditors

### Project Overview
```
Project Name: WorldLand
Token Symbol: WL
Token Type: ERC20 (Fixed Supply)
Total Supply: 1,000,000,000 WL
Decimals: 18
```

### Vesting Configuration
```
Type: Linear vesting with optional cliff
Beneficiary: Configurable at deployment
Start Time: Configurable at deployment
Duration: Configurable at deployment
Cliff: Optional, configurable
```

### Trust Model
- Token contract has NO owner/admin
- Vesting wallet owner = beneficiary (can transfer ownership)
- No upgradeability (immutable contracts)
- No pause/freeze mechanism

### External Interactions
- Token: Standard ERC20 transfers only
- Vesting: Holds and releases ERC20 tokens and native ETH

---

## Audit Firm Requirements (Typical)

### Before Audit
1. **Freeze code** - No changes during audit period
2. **Git commit hash** - Provide exact commit being audited
3. **NDA** - Sign mutual non-disclosure agreement
4. **Scope agreement** - Define what's in/out of scope
5. **Timeline** - Agree on delivery date

### During Audit
1. **Communication channel** - Slack/Discord for questions
2. **Point of contact** - Technical person who can answer questions
3. **Availability** - Respond to queries within 24h

### Deliverables to Expect
1. **Preliminary report** - Initial findings
2. **Fix review period** - Time to address issues
3. **Final report** - With fixes verified
4. **Public disclosure** - Timeline for publishing report

---

## Recommended Auditors (2024-2025)

| Firm | Specialty | Est. Cost (USD) |
|------|-----------|-----------------|
| OpenZeppelin | Enterprise, DeFi | $50K-200K+ |
| Trail of Bits | Security research | $50K-150K+ |
| Consensys Diligence | Ethereum native | $30K-100K+ |
| Cyfrin | DeFi, competitive | $15K-50K |
| Code4rena | Competitive audit | $20K-100K |
| Sherlock | Bug bounty + audit | $15K-50K |
| Pashov | Solo auditor | $5K-20K |
| Guardian Audits | Cost-effective | $5K-15K |

*Prices vary based on complexity, timeline, and scope*

---

## Pre-Audit Checklist

### Code Quality
- [ ] Remove console.log / debug code
- [ ] Remove unused imports
- [ ] Consistent formatting (use Prettier)
- [ ] NatSpec comments on public functions

### Security Basics
- [x] Use latest stable Solidity (0.8.27)
- [x] Use audited libraries (OpenZeppelin v5.4+)
- [x] No floating pragma in production
- [ ] Verify all dependencies match official releases

### Testing
- [ ] 100% test coverage on custom code
- [ ] Fuzz testing for math operations
- [ ] Integration tests for vesting scenarios

### Documentation
- [x] README with contract overview
- [x] Deployment parameters documented
- [ ] Vesting schedule examples
- [ ] Token distribution plan

---

## Git Command for Audit Submission

```bash
# Create clean export for auditors
git archive --format=zip HEAD -o worldland_audit_$(date +%Y%m%d).zip

# Get commit hash
git rev-parse HEAD
```
