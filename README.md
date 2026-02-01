# WorldLand Contracts

Smart contracts for WorldLand token ecosystem.

## Contracts for Audit

### 1. Token Contract

| Item | Value |
|------|-------|
| **File** | `token_contracts/contracts/MyToken.sol` |
| **Contract Name** | `WorldLandNativeToken` |
| **Symbol** | WL |
| **Total Supply** | 1,000,000,000 (1 Billion) |
| **Decimals** | 18 |
| **Solidity Version** | ^0.8.27 |
| **Dependencies** | OpenZeppelin Contracts v5.4.0 |

### 2. Vesting Contracts

| Item | Value |
|------|-------|
| **Base Contract** | `vesting_contracts/finance/VestingWallet.sol` |
| **Cliff Extension** | `vesting_contracts/finance/VestingWalletCliff.sol` |
| **Solidity Version** | ^0.8.20 |
| **Dependencies** | OpenZeppelin Contracts v5.5.0 / v5.1.0 |

---

## Project Structure

```
WorldLand_Contracts/
├── token_contracts/
│   ├── contracts/
│   │   └── MyToken.sol              # [AUDIT TARGET] ERC20 Token
│   ├── tests/
│   │   └── MyToken_test.sol
│   └── .deps/                       # OpenZeppelin v5.4.0
│
└── vesting_contracts/
    ├── finance/
    │   ├── VestingWallet.sol        # [AUDIT TARGET] Base vesting
    │   └── VestingWalletCliff.sol   # [AUDIT TARGET] Cliff extension
    ├── access/
    │   └── Ownable.sol
    ├── token/ERC20/
    │   ├── IERC20.sol
    │   └── utils/SafeERC20.sol
    ├── utils/
    │   ├── Address.sol
    │   ├── Context.sol
    │   ├── Errors.sol
    │   └── math/SafeCast.sol
    └── interfaces/
        ├── IERC20.sol
        ├── IERC165.sol
        └── IERC1363.sol
```

---

## Dependency Verification

All dependencies have been verified against official OpenZeppelin GitHub releases:

### Token Contract Dependencies (v5.4.0)

| File | Status |
|------|--------|
| ERC20.sol | Verified |
| IERC20.sol | Verified |
| IERC20Metadata.sol | Verified |
| draft-IERC6093.sol | Verified |
| Context.sol | Verified |

### Vesting Contract Dependencies (v5.5.0 / v5.1.0)

| File | Status |
|------|--------|
| VestingWallet.sol | Verified (whitespace only diff) |
| VestingWalletCliff.sol | Verified (whitespace only diff) |
| Ownable.sol | Verified |
| SafeERC20.sol | Verified |
| Address.sol | Verified |
| Context.sol | Verified |
| Errors.sol | Verified |
| SafeCast.sol | Verified (comment grammar only diff) |

---

## Deployment Parameters

### Token Contract
```solidity
constructor(address foundation_wallet)
```
- `foundation_wallet`: Address to receive initial 1B token supply

### VestingWallet
```solidity
constructor(address beneficiary, uint64 startTimestamp, uint64 durationSeconds)
```
- `beneficiary`: Address that will receive vested tokens
- `startTimestamp`: Unix timestamp when vesting begins
- `durationSeconds`: Total vesting duration in seconds

### VestingWalletCliff (extends VestingWallet)
```solidity
constructor(uint64 cliffSeconds)
```
- `cliffSeconds`: Duration before any tokens become releasable

---

## Build & Test

### Using Remix IDE
1. Open Remix IDE (https://remix.ethereum.org)
2. Import contracts from this repository
3. Compile with Solidity 0.8.27+
4. Deploy to desired network

### Compiler Settings
- Solidity Version: 0.8.27
- EVM Version: Paris (or later)
- Optimizer: Enabled (200 runs recommended)

---

## Security Considerations

### Token Contract
- Fixed supply (no mint function exposed)
- No burn function exposed
- No pause mechanism
- No admin/owner privileges
- Standard ERC20 implementation

### Vesting Contract
- Ownable pattern for beneficiary management
- Linear vesting schedule
- Optional cliff period
- Supports both native ETH and ERC20 tokens

---

## License

MIT License (OpenZeppelin Contracts)
