# WorldLand Contracts

## Overview

| Network | Solidity | Framework |
|---------|----------|-----------|
| BSC (BNB Smart Chain) | ^0.8.20 / ^0.8.27 | OpenZeppelin v5.x |

---

## 1. Token Contract

### Audit Scope
| File | Contract | Description |
|------|----------|-------------|
| `token_contracts/contracts/MyToken.sol` | `WorldLandNativeToken` | ERC20, 1B fixed supply |

### Dependencies (+ all related dependencies)
| File | Source |
|------|--------|
| `@openzeppelin/contracts/token/ERC20/ERC20.sol` | OZ v5.4.0 |

---

## 2. Vesting Contracts (Finance)

### Audit Scope

**Custom Contracts**
| File | Contract | Description |
|------|----------|-------------|
| `vesting_contracts/finance/VestingWalletStair.sol` | `VestingWalletStair` | Step/stair vesting with cliff |
| `vesting_contracts/finance/WorldLandStairVesting.sol` | `WorldLandVesting` | WorldLand implementation |
| `vesting_contracts/finance/RevocableStairVesting.sol` | `RevocableStairVesting` | + Revocation capability |

**OpenZeppelin Base**
| File | Source |
|------|--------|
| `vesting_contracts/finance/VestingWallet.sol` | OZ v5.5.0 |
| `vesting_contracts/finance/VestingWalletCliff.sol` | OZ v5.1.0 |

### Dependencies (+ all related dependencies)
| File | Source |
|------|--------|
| `Ownable.sol` | OZ v5.0.0 |
| `SafeERC20.sol` | OZ v5.5.0 |
| `Address.sol` | OZ v5.5.0 |
| `LowLevelCall.sol` | OZ v5.5.0 |
| `SafeCast.sol` | OZ v5.0.0 |
| `Context.sol`, `Errors.sol` | OZ v5.x |

### Architecture
```
Ownable (OZ)
    └── VestingWallet (OZ)
            ├── VestingWalletCliff (OZ)
            └── VestingWalletStair (Custom)
                    ├── WorldLandVesting (Custom)
                    └── RevocableStairVesting (Custom)
```

---

## Deployment

| Setting | Value |
|---------|-------|
| Network | BSC Mainnet |
| Compiler | 0.8.27 |

---

## License

MIT
