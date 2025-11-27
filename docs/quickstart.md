# Quick Start

Get up and running with ERC-7866 in minutes.

## Deploy SoulProfile

```solidity
import { SoulProfile } from "../contracts/core/SoulProfile.sol";

// Deploy contract
SoulProfile profile = new SoulProfile();
```

## Create a Profile

```solidity
// Create profile with username and avatar
profile.createProfile(
    "alice",
    "ipfs://QmXxxxx..." // Avatar metadata URI
);
```

## Set Avatars

### Default Avatar
```solidity
// Set default avatar used across all dApps
profile.setDefaultAvatar("ipfs://QmYyyyy...");
```

### dApp-Specific Avatar
```solidity
// Set public avatar (everyone can see)
profile.setDappAvatar(
    "MyGameDApp",
    "ipfs://game-avatar-metadata...",
    true  // isPublic
);

// Set private avatar (only you can see)
profile.setDappAvatar(
    "PrivateDApp",
    "ipfs://private-metadata...",
    false  // isPublic
);
```

## Retrieve Profiles

### Get Full Profile
```solidity
SoulProfile.Profile memory profile = soulProfile.getProfile(userAddress);
// Returns: { username, defaultAvatarURI, bio, website }
```

### Look Up by Username
```solidity
address alice = soulProfile.getProfileByUsername("alice");
```

### Get dApp Avatar
```solidity
SoulProfile.DappAvatar memory gameAvatar = soulProfile.getDappAvatar(
    userAddress,
    "MyGameDApp"
);
// Privacy enforced: returns empty URI if private and caller isn't owner
```

### Check if Profile Exists
```solidity
bool exists = soulProfile.hasProfile(userAddress);
```

## Next Steps

<CardGroup cols={2}>
  <Card
    title="Full Implementation Guide"
    icon="book"
    href="/implementation/guide"
  >
    Detailed examples and patterns
  </Card>
  <Card
    title="Integration Example"
    icon="code"
    href="/implementation/integration"
  >
    Complete dApp integration
  </Card>
  <Card
    title="Gas Costs"
    icon="zap"
    href="/implementation/gas"
  >
    Cost estimates and benchmarking
  </Card>
  <Card
    title="Specification"
    icon="scroll"
    href="/reference/specification"
  >
    Technical reference
  </Card>
</CardGroup>
