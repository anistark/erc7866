# Gas Costs & Benchmarking

Understanding gas consumption for ERC-7866 operations.

## Estimated Costs

Costs based on the SoulProfile.sol reference implementation:

| Operation | Gas | Notes |
|-----------|-----|-------|
| `createProfile()` | ~50,000 | Stores Profile struct, username mapping, state flag |
| `setDefaultAvatar()` | ~30,000 | Updates avatar URI string in storage |
| `setDappAvatar()` | ~30,000 | Creates/updates dApp avatar mapping entry |
| `removeDappAvatar()` | ~5,000 | Deletes mapping entry |
| `getProfile()` | ~5,000 | View function, storage read |
| `getDefaultAvatar()` | ~3,000 | View function, single string read |
| `getDappAvatar()` | ~3,000 | View function, mapping lookup + privacy check |
| `getProfileByUsername()` | ~3,000 | View function, mapping lookup |
| `hasProfile()` | ~2,100 | View function, boolean check |

**Note**: These are rough estimates. Actual costs vary significantly.

## What Affects Gas Costs

### Network & Configuration

- **EVM Network**: Ethereum L1 costs differ from Polygon, Arbitrum, Base
- **Compiler Version**: Solidity optimizer settings affect bytecode
- **Network Congestion**: Affects base fee (not contract cost, but total cost)

### Storage State

- **Cold vs. Warm Storage**
  - First access to a storage slot: ~20,000 gas (SSTORE)
  - Subsequent accesses in same transaction: ~2,900 gas
  - Reading cold storage: ~3,100 gas (SLOAD)
  - Reading warm storage: ~100 gas

- **String Storage**
  - Strings longer than 31 bytes incur additional storage costs
  - Username length affects profile creation cost
  - Avatar URI length affects avatar update cost

### Input Data

- **Call Data**: ~16 gas per non-zero byte, ~4 per zero byte
- Long usernames or URIs increase calldata costs

### Transaction Overhead

These gas estimates **don't include**:
- **Base transaction cost**: 21,000 gas per transaction
- **Call data**: Variable based on input parameters
- **Memory operations**: If your contract uses memory

## Real-World Examples

### User Creates Profile

```solidity
profile.createProfile("alice", "ipfs://QmXxxx...");
```

**Cost Breakdown**:
- Base transaction: 21,000 gas
- createProfile execution: ~50,000 gas
- Calldata (~40 bytes): ~160 gas

**Total**: ~71,160 gas

At 20 gwei on Ethereum: 0.0014232 ETH (~$4.27)

### User Updates Avatar

```solidity
profile.setDefaultAvatar("ipfs://QmYyyy...");
```

**Cost Breakdown**:
- Base transaction: 21,000 gas
- setDefaultAvatar execution: ~30,000 gas
- Calldata (~50 bytes): ~200 gas

**Total**: ~51,200 gas

At 20 gwei on Ethereum: 0.0010240 ETH (~$3.07)

### Reading Profile (View Function)

```solidity
profile.getProfile(userAddress);
```

**Cost**: 0 gas (read-only, but requires gas simulation)

View functions don't consume gas on-chain, but simulating them locally may cost RPC provider resources.

## Layer 2 Comparison

Gas costs on L2s are significantly lower:

| Network | ~50k Gas Cost | Price (USD) |
|---------|--------------|------------|
| Ethereum | 0.001 ETH | $3.00 |
| Polygon | 0.01 MATIC | $0.002 |
| Arbitrum | 0.00005 ETH | $0.15 |
| Optimism | 0.00005 ETH | $0.15 |
| Base | 0.00005 ETH | $0.15 |

## Optimization Strategies

### 1. Batch Operations

Instead of multiple transactions:

```solidity
// Inefficient: 3 transactions
soulProfile.createProfile("alice", "ipfs://avatar");
soulProfile.setDappAvatar("Game1", "ipfs://game1", true);
soulProfile.setDappAvatar("Game2", "ipfs://game2", true);

// More efficient: Use factory or multi-call
// Reduce overhead, batch calldata
```

### 2. Lazy Avatar Loading

Don't set all avatars at once:

```solidity
// User creates profile without avatar
profile.createProfile("alice", "");

// Set avatars later, when needed
profile.setDefaultAvatar("ipfs://avatar");  // Later
profile.setDappAvatar("Game", "ipfs://...", true);  // Even later
```

### 3. Use Proxy Pattern

For upgradeable profiles:

```solidity
// Delegates to implementation, small overhead
// But worth it if you need to update logic
```

### 4. Pack Storage

Solidity automatically packs small values:

```solidity
// More efficient storage
struct CompactProfile {
    string username;        // 32+ bytes
    string defaultAvatar;   // 32+ bytes
    bool isActive;          // 1 byte (packed)
    uint8 version;          // 1 byte (packed)
}
```

### 5. Resolver for Bulk Lookups

Use the resolver for privacy-aware reads to avoid repeated DappAvatar lookups:

```solidity
// Single call with privacy enforced
string memory avatar = resolver.resolveDappAvatar(user, "Game");

// vs. direct call + privacy check in your code
```

## Benchmarking

### Foundry

Test actual gas on your setup:

```solidity
function test_ProfileCreationGas() public {
    vm.prank(alice);

    // Measure gas
    uint256 gasStart = gasleft();
    soulProfile.createProfile("alice", "ipfs://avatar");
    uint256 gasUsed = gasStart - gasleft();

    emit log_uint(gasUsed);
    // Output: 48723
}

function test_AvatarUpdateGas() public {
    vm.prank(alice);
    soulProfile.createProfile("alice", "ipfs://avatar");

    uint256 gasStart = gasleft();
    soulProfile.setDefaultAvatar("ipfs://newavatar");
    uint256 gasUsed = gasStart - gasleft();

    emit log_uint(gasUsed);
    // Output: 29104
}
```

Run with:

```bash
forge test -v --gas-report
```

### Hardhat

```javascript
describe("SoulProfile Gas", function () {
    it("should measure createProfile gas", async function () {
        const tx = await soulProfile.createProfile(
            "alice",
            "ipfs://avatar"
        );
        const receipt = await tx.wait();

        console.log("Gas used:", receipt.gasUsed.toString());
    });
});
```

### Live Network Benchmarking

Using Etherscan or block explorer:

1. Deploy to testnet
2. Execute transaction
3. Check "Gas Used" in transaction receipt
4. Real cost = Gas Used × Gas Price

Example on Sepolia:
- Transaction: 0x123abc...
- Gas Used: 48,923
- Gas Price: 10 gwei
- Cost: 489,230 wei = 0.00048923 ETH

## Cost Optimization Tips

### For dApps

1. **Batch profile operations** — Create once, update avatars separately
2. **Cache results** — Store off-chain to avoid repeated reads
3. **Use events** — Index from events instead of scanning storage
4. **L2 deployment** — Use cheaper networks for mass adoption

### For Users

1. **Create during low-congestion times** — Lower base fee
2. **Bundle operations** — Create profile + set avatar in same block
3. **Consider L2s** — 90%+ cheaper than Ethereum L1
4. **Set minimum avatar info** — Shorter strings = lower calldata costs

### For Indexers

1. **Listen to events** — Don't scan all storage
2. **Batch queries** — Use eth_call with multiple accounts
3. **Archive nodes** — Fast historical lookups
4. **Cache aggressively** — Profile data changes infrequently

## Cost Prediction Calculator

### Rough Formula

```
Cost = (21,000 + execution_gas + calldata_gas) × gas_price

Where:
- execution_gas ≈ 30,000 - 50,000 (varies by operation)
- calldata_gas ≈ (input_bytes × 16) + (zero_bytes × 4)
- gas_price = current network fee (gwei)
```

### Example

Profile creation with 32-character username + IPFS hash:
- Base: 21,000
- Execution: 50,000
- Calldata (60 bytes): ~960
- **Total: ~71,960 gas**

At 20 gwei:
- 71,960 × 20 = 1,439,200 gwei = 0.0014392 ETH

## Security Note

Gas costs don't compromise security. Lower gas doesn't mean less secure. The standard is equally secure across all networks.

## Further Reading

- [EVM Gas Explained](https://evm.codes)
- [Solidity Gas Optimization](https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html)
- [Foundry Gas Reports](https://book.getfoundry.sh/forge/gas-reports)
- [Layer 2 Comparisons](https://l2beat.com)
