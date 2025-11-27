# Features

## Comprehensive Profile Management

ERC-7866 provides a complete identity layer for Web3 applications.

### Unique Usernames

Claim a human-readable, globally unique identifier tied to your address:

```solidity
profile.createProfile("alice", "ipfs://avatar...");
```

Benefits:
- Easy to remember and share
- Immutable (cannot be changed)
- Prevents username squatting through first-come-first-served
- Reverse lookup: username → address

### Multi-Avatar System

Set different avatars for different contexts:

```solidity
// Default avatar (used everywhere by default)
profile.setDefaultAvatar("ipfs://professional-avatar...");

// dApp-specific avatars
profile.setDappAvatar("GameA", "ipfs://game-character...", true);
profile.setDappAvatar("GameB", "ipfs://different-avatar...", true);
```

Use cases:
- Gaming: In-game character avatars
- Professional: LinkedIn-style work avatar
- Privacy: Keep sensitive avatars private
- Branding: dApp-specific character customization

### Privacy Control

Mark avatars as public or private:

```solidity
// Public avatar - anyone can see
profile.setDappAvatar("PublicDApp", "ipfs://...", true);

// Private avatar - only owner can see
profile.setDappAvatar("PrivateDApp", "ipfs://...", false);
```

Privacy enforcement happens at function level:
- Private avatars return empty URI to non-owners
- No special setup needed
- Works across chains

### Multi-Chain Identity

Same username and address across multiple blockchain networks:

```
Ethereum:  alice@eth.soul      → 0xAlice
Polygon:   alice@polygon.soul  → 0xAlice
Arbitrum:  alice@arb.soul      → 0xAlice
```

Deploy SoulProfile to each network and users maintain consistent identity.

## Soul Bound (Non-Transferable)

Profiles are bound to addresses and cannot be transferred:

- Profile is tied to the address that created it
- Immutable core data (username, creation address)
- Only owner can modify
- Cannot be sold or transferred
- Survives wallet changes through recovery mechanisms

## Event-Driven

Complete event logging for profile changes:

```solidity
event ProfileCreated(address indexed owner, string username);
event DefaultAvatarUpdated(address indexed owner, string avatarURI);
event DappAvatarSet(address indexed owner, string dappName, string avatarURI, bool isPublic);
event DappAvatarRemoved(address indexed owner, string dappName);
```

Applications can:
- Listen for new profiles
- Track avatar updates
- Build real-time discovery systems
- Index profiles for search

## Off-Chain Storage

Minimize on-chain footprint with off-chain metadata:

```
Contract stores:
├── username (string)
├── defaultAvatarURI (pointer to IPFS/Arweave)
├── dAppAvatars (mapping of URIs)
└── visibility flags (boolean)

IPFS/Arweave stores:
├── avatar image
├── bio
├── website
├── social links
└── dApp-specific metadata
```

Benefits:
- Lower gas costs for profile creation
- Larger metadata capacity
- Decentralized storage
- Immutable history on IPFS

## Resolver Pattern

Optional helper contract for safe profile discovery:

```solidity
SoulProfileResolver resolver = new SoulProfileResolver(address(soulProfile));

// Resolve with privacy checks
string memory avatar = resolver.resolveDappAvatar(userAddress, "MyDApp");

// Resolve only public avatars
string memory publicAvatar = resolver.resolveDappAvatarPublic(userAddress, "MyDApp");

// Resolve username
string memory username = resolver.resolveUsername(userAddress);
```

## Security Guarantees

- **Non-transferable**: Soul bound to address
- **Immutable usernames**: Cannot be changed after creation
- **Privacy enforced**: Private data hidden at function level
- **Reentrancy safe**: State changes before external calls
- **Ownership verified**: Only owner can modify profile
