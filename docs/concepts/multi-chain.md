# Multi-Chain Profiles

How ERC-7866 enables consistent identities across blockchains.

## Single Identity, Multiple Chains

Deploy SoulProfile to multiple EVM networks and users maintain a consistent identity:

```
User: 0xAlice (same address across all chains)

Ethereum:    username "alice" → alice@eth.soul
Polygon:     username "alice" → alice@polygon.soul
Arbitrum:    username "alice" → alice@arb.soul
Base:        username "alice" → alice@base.soul
Optimism:    username "alice" → alice@op.soul
```

## Setup

### Deploy to Multiple Networks

Deploy the same `SoulProfile` contract to each network:

```bash
# Deploy to Ethereum
forge create contracts/core/SoulProfile.sol:SoulProfile \
    --rpc-url $ETHEREUM_RPC

# Deploy to Polygon
forge create contracts/core/SoulProfile.sol:SoulProfile \
    --rpc-url $POLYGON_RPC

# Deploy to Arbitrum
forge create contracts/core/SoulProfile.sol:SoulProfile \
    --rpc-url $ARBITRUM_RPC
```

### Create Profile Once Per Chain

Users create profiles on each network they want to participate in:

```solidity
// On Ethereum
ethereumProfile.createProfile("alice", "ipfs://avatar...");

// On Polygon
polygonProfile.createProfile("alice", "ipfs://avatar...");

// On Arbitrum
arbitrumProfile.createProfile("alice", "ipfs://avatar...");
```

<Warning>
The same address owns the profile on all chains. Network-specific deployments are independent contracts.
</Warning>

## Profile Format

### Human-Readable Identifiers

Format: `username@network_slug.soul`

```
alice@eth.soul        (Ethereum mainnet)
alice@sepolia.soul    (Ethereum Sepolia)
alice@polygon.soul    (Polygon mainnet)
alice@mumbai.soul     (Polygon Mumbai testnet)
alice@arb.soul        (Arbitrum One)
alice@base.soul       (Base)
alice@op.soul         (Optimism)
```

### Decentralized Identifiers (DIDs)

Format: `did:eip155:chainId:address`

Based on EIP-155 chain identifiers:

```
did:eip155:1:0xAlice...       (Ethereum mainnet)
did:eip155:11155111:0xAlice...  (Ethereum Sepolia)
did:eip155:137:0xAlice...     (Polygon)
did:eip155:80001:0xAlice...   (Polygon Mumbai)
did:eip155:42161:0xAlice...   (Arbitrum One)
did:eip155:8453:0xAlice...    (Base)
did:eip155:10:0xAlice...      (Optimism)
```

## Use Cases

### Cross-Chain Gaming

A player maintains one identity across games on different chains:

```
GameA on Ethereum  → alice@eth.soul (Warrior level 50)
GameB on Polygon   → alice@polygon.soul (Mage level 30)
GameC on Arbitrum  → alice@arb.soul (Ranger level 45)

All owned by: 0xAlice
```

Each game can:
- Look up profiles by address on their chain
- Set game-specific avatars
- Read the default avatar as fallback
- Discover players cross-chain through indexing

### Multi-Chain DApps

A DApp deployed on multiple networks:

```solidity
// app.sol on Ethereum
IErc7866 ethereumProfiles = new SoulProfile();

// app.sol on Polygon
IErc7866 polygonProfiles = new SoulProfile();

function userProfile(address user) returns (Profile memory) {
    // Fetch from current chain's profile contract
    if (!_currentChainProfiles.hasProfile(user)) {
        return empty;
    }
    return _currentChainProfiles.getProfile(user);
}
```

### Profile Discovery

Index profiles across chains:

```typescript
// Build a multi-chain username registry
const profiles: Record<string, ChainProfiles> = {};

async function indexProfiles() {
    const chains = [
        { name: "ethereum", rpc: "..." },
        { name: "polygon", rpc: "..." },
        { name: "arbitrum", rpc: "..." }
    ];

    for (const chain of chains) {
        const contract = new ethers.Contract(
            PROFILE_ADDRESS,
            ABI,
            new ethers.JsonRpcProvider(chain.rpc)
        );

        // Listen for ProfileCreated events
        contract.on("ProfileCreated", (owner, username) => {
            if (!profiles[username]) {
                profiles[username] = {};
            }
            profiles[username][chain.name] = owner;
        });
    }
}

// Look up where a user has profiles
function getUserProfiles(username: string) {
    return profiles[username] || {};
    // Returns: { ethereum: 0xAlice, polygon: 0xAlice, arbitrum: 0xAlice }
}
```

## Address Consistency

Users keep the same address across all EVM chains. This is a fundamental property of EVM:

- Same mnemonic/private key → same address on every chain
- No bridging or cross-chain messaging needed
- Each chain's contract is independent
- Profiles are not synchronized (each chain is separate)

## Multi-Chain Avatars

Each network has independent avatar settings:

```solidity
// On Ethereum
ethereumProfile.setDappAvatar("GameA", "ipfs://eth-avatar", true);

// On Polygon (different avatar for same dApp)
polygonProfile.setDappAvatar("GameA", "ipfs://polygon-avatar", true);

// Game reads from the chain it's deployed on
// Ethereum GameA sees eth-avatar
// Polygon GameA sees polygon-avatar
```

This enables:
- **Network-specific branding** — Different avatars per chain
- **Chain-specific contexts** — Layer 2 avatars differ from mainnet
- **Independent state** — Each chain manages its own profile state

## Indexing Across Chains

To provide a unified multi-chain experience:

```typescript
// Listen to all chains simultaneously
async function buildMultiChainIndex() {
    const chains = [
        { id: 1, name: "ethereum", contract: ethereumSoulProfile },
        { id: 137, name: "polygon", contract: polygonSoulProfile },
        { id: 42161, name: "arbitrum", contract: arbitrumSoulProfile }
    ];

    const userProfiles = new Map<string, Map<string, any>>();

    for (const chain of chains) {
        chain.contract.on("ProfileCreated", (owner, username) => {
            if (!userProfiles.has(username)) {
                userProfiles.set(username, new Map());
            }

            const chainProfiles = userProfiles.get(username)!;
            chainProfiles.set(chain.name, {
                address: owner,
                chainId: chain.id,
                fullId: `did:eip155:${chain.id}:${owner}`
            });
        });
    }

    return userProfiles;
}
```

## Bridge Considerations

ERC-7866 profiles are **not bridged** between chains:

- Each chain has a separate, independent SoulProfile contract
- No cross-chain messaging required
- No wrapped tokens or bridges
- Each profile is sovereign to its chain

If you need synchronized profiles across chains, you would implement:
- Off-chain indexing and replication
- Custom cross-chain messaging
- Centralized registry (defeats decentralization)

The recommended approach is **per-chain independence** — users create profiles where they participate.

## Best Practices

### For Users

1. Create profiles on chains where you're active
2. Use the same username across chains for discoverability
3. Keep addresses consistent (same wallet)
4. Update avatars on each chain independently

### For dApps

1. Support profile lookups on your deployed chain
2. Use addresses as primary identifier (not username)
3. Fall back to default avatar if dApp-specific avatar not set
4. Consider the user's multi-chain presence in UX

### For Indexers

1. Run RPC nodes for each chain
2. Listen to ProfileCreated events on each chain
3. Aggregate data off-chain
4. Index by username for discovery
5. Track DIDs for multi-chain lookups
