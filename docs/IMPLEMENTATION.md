# ERC-7866 Implementation Guide

A practical guide to implementing ERC-7866 Soul Bound Profiles in your dApp.

## Overview

ERC-7866 defines a standard for decentralized user profiles with:
- Unique usernames tied to addresses
- Default and dApp-specific avatars
- Privacy control for avatar visibility
- Off-chain metadata with on-chain pointers

## Core Concepts

### Profile Structure
```solidity
struct Profile {
    string username;              // Unique identifier
    string defaultAvatarURI;      // Main avatar
    string bio;                   // User biography
    string website;               // Website link
}
```

### DApp Avatar
```solidity
struct DappAvatar {
    string dappName;              // Associated dApp
    string avatarURI;             // Avatar metadata URI
    bool isPublic;                // Visibility flag
}
```

## Usage Examples

### 1. Creating a Profile

```solidity
// Deploy SoulProfile contract
SoulProfile soulProfile = new SoulProfile();

// Create profile
soulProfile.createProfile(
    "alice",
    "ipfs://QmXxxx..." // Avatar IPFS hash
);
```

### 2. Managing Avatars

```solidity
// Set default avatar
soulProfile.setDefaultAvatar("ipfs://QmYyyy...");

// Set dApp-specific avatar (public)
soulProfile.setDappAvatar(
    "myGameDApp",
    "ipfs://QmZzzz...",
    true  // isPublic
);

// Set private dApp avatar
soulProfile.setDappAvatar(
    "privateApp",
    "ipfs://QmPrivate...",
    false  // isPublic
);

// Remove dApp avatar
soulProfile.removeDappAvatar("myGameDApp");
```

### 3. Retrieving Profile Data

```solidity
// Get full profile
Profile memory profile = soulProfile.getProfile(userAddress);

// Get default avatar
string memory avatar = soulProfile.getDefaultAvatar(userAddress);

// Get dApp-specific avatar
DappAvatar memory dappAvatar = soulProfile.getDappAvatar(
    userAddress,
    "myGameDApp"
);

// Lookup address by username
address user = soulProfile.getProfileByUsername("alice");

// Check if profile exists
bool exists = soulProfile.hasProfile(userAddress);
```

## Resolver Pattern

Use `SoulProfileResolver` to safely resolve profile data:

```solidity
// Deploy resolver
SoulProfileResolver resolver = new SoulProfileResolver(address(soulProfile));

// Register dApp resolver
resolver.registerDappResolver("myDapp", dappResolverAddress);

// Resolve username
string memory username = resolver.resolveUsername(userAddress);

// Resolve public avatar
string memory publicAvatar = resolver.resolveDappAvatarPublic(
    userAddress,
    "myDapp"
);

// Resolve with privacy check
string memory avatar = resolver.resolveDappAvatar(userAddress, "myDapp");
```

## Privacy Model

Avatars support two visibility levels:

**Public Avatars**: Anyone can read
```solidity
soulProfile.setDappAvatar("publicDapp", "ipfs://Qm...", true);
```

**Private Avatars**: Only owner and self can read
```solidity
soulProfile.setDappAvatar("privateDapp", "ipfs://Qm...", false);
```

The `getDappAvatar` function enforces privacy at runtime:
- If avatar is private and caller isn't owner, empty URI is returned
- Public avatars are always readable

## Off-Chain Storage

Metadata URIs typically point to:
- **IPFS**: `ipfs://QmHash`
- **Arweave**: `ar://Hash`

Metadata JSON structure:
```json
{
  "username": "alice",
  "avatar": "https://...",
  "bio": "Web3 developer",
  "website": "https://example.com",
  "social": {
    "twitter": "@alice",
    "discord": "alice#1234"
  }
}
```

## Integration Checklist

- [ ] Deploy SoulProfile contract
- [ ] Deploy SoulProfileResolver (optional)
- [ ] Users create profiles
- [ ] Store metadata on IPFS/Arweave
- [ ] Update URIs to point to off-chain storage
- [ ] Integrate profile resolution in UI
- [ ] Handle privacy checks in frontend
- [ ] Index events for profile discovery

## Gas Considerations

- Profile creation: ~50k gas
- Avatar updates: ~30k gas per dApp avatar
- Reads are view functions (no gas)

Privacy checks happen at function call time, not at storage level.

## Common Patterns

### Multi-Chain Profiles

Use the same username and addresses across chains:
```
alice@eth.soul → 0xAlice on Ethereum
alice@polygon.soul → 0xAlice on Polygon
alice@arb.soul → 0xAlice on Arbitrum
```

### dApp Integration

Each dApp can set custom avatars:
```solidity
// GameA sets NFT avatar
gameA.setDappAvatar("GameA", nftMetadataURI, true);

// GameB sets different avatar
gameB.setDappAvatar("GameB", customAvatarURI, true);

// User has context-specific identity across dApps
```

### Profile Discovery

```solidity
// Frontend listens to events
event ProfileCreated(address indexed owner, string username);

// Index usernames → addresses
// Build discovery interface
```

## References

- [EIP-7866 Specification](https://eips.ethereum.org/EIPS/eip-7866)
- [Soul Bound Tokens Concept](https://vitalik.ca/general/2022/01/26/soulbound.html)
