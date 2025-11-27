# Implementation Guide

Complete guide to implementing ERC-7866 Soul Bound Profiles in your dApp.

## Overview

ERC-7866 defines a standard for decentralized user profiles with:
- Unique usernames tied to addresses
- Default and dApp-specific avatars
- Privacy control for avatar visibility
- Off-chain metadata with on-chain pointers

## Core Contracts

### IERC7866 Interface

The standard interface all implementations must support:

```solidity
interface IERC7866 {
    function createProfile(string memory username, string memory defaultAvatarURI) external;
    function setDefaultAvatar(string memory avatarURI) external;
    function setDappAvatar(string memory dappName, string memory avatarURI, bool isPublic) external;
    function removeDappAvatar(string memory dappName) external;

    function getProfile(address owner) external view returns (Profile memory);
    function getDefaultAvatar(address owner) external view returns (string memory);
    function getDappAvatar(address owner, string memory dappName) external view returns (DappAvatar memory);
    function getProfileByUsername(string memory username) external view returns (address);
    function hasProfile(address owner) external view returns (bool);
}
```

### SoulProfile Implementation

Reference implementation with full feature support:

```solidity
import { IERC7866 } from "../interfaces/IERC7866.sol";

contract SoulProfile is IERC7866 {
    mapping(address => Profile) private profiles;
    mapping(address => mapping(string => DappAvatar)) private dappAvatars;
    mapping(string => address) private usernameToAddress;
    mapping(address => bool) private _hasProfile;

    // ... events and functions
}
```

### SoulProfileResolver

Optional resolver for safe profile discovery:

```solidity
contract SoulProfileResolver {
    IERC7866 public soulProfile;

    function resolveDappAvatar(address owner, string memory dappName)
        external view returns (string memory);

    function resolveDappAvatarPublic(address owner, string memory dappName)
        external view returns (string memory);

    function resolveUsername(address owner) external view returns (string memory);
}
```

## Deployment

### Deploy SoulProfile

```bash
# Compile
forge build

# Deploy to Ethereum
forge create contracts/core/SoulProfile.sol:SoulProfile \
    --rpc-url $ETHEREUM_RPC \
    --private-key $PRIVATE_KEY
```

### Deploy SoulProfileResolver (Optional)

```bash
# Deploy resolver with SoulProfile address
forge create contracts/extensions/SoulProfileResolver.sol:SoulProfileResolver \
    --constructor-args <SOULPROFILE_ADDRESS> \
    --rpc-url $ETHEREUM_RPC \
    --private-key $PRIVATE_KEY
```

## Usage Examples

### Create Profile

```solidity
// User creates a profile
soulProfile.createProfile(
    "alice",
    "ipfs://QmXxxx..." // Avatar metadata
);
```

**Validations**
- Username must be unique
- Username must be 1-32 characters
- Profile must not already exist

### Set Avatars

```solidity
// Set default avatar
soulProfile.setDefaultAvatar("ipfs://QmYyyy...");

// Set dApp-specific avatar (public)
soulProfile.setDappAvatar(
    "MyGameDApp",
    "ipfs://QmZzzz...",
    true  // isPublic
);

// Set private dApp avatar
soulProfile.setDappAvatar(
    "PrivateDApp",
    "ipfs://QmPrivate...",
    false  // isPublic
);

// Remove dApp avatar
soulProfile.removeDappAvatar("MyGameDApp");
```

### Retrieve Profiles

```solidity
// Get complete profile
IERC7866.Profile memory profile = soulProfile.getProfile(userAddress);
// Returns: { username, defaultAvatarURI, bio, website }

// Get default avatar
string memory avatar = soulProfile.getDefaultAvatar(userAddress);

// Get dApp-specific avatar (with privacy enforcement)
IERC7866.DappAvatar memory gameAvatar = soulProfile.getDappAvatar(
    userAddress,
    "MyGameDApp"
);

// Lookup address by username
address alice = soulProfile.getProfileByUsername("alice");

// Check if profile exists
bool exists = soulProfile.hasProfile(userAddress);
```

## Privacy Enforcement

Privacy is enforced at read time:

```solidity
function getDappAvatar(address owner, string memory dappName)
    external view
    returns (DappAvatar memory)
{
    DappAvatar memory avatar = dappAvatars[owner][dappName];

    // Return empty URI if private and caller isn't owner
    if (!avatar.isPublic && msg.sender != owner) {
        return DappAvatar({dappName: dappName, avatarURI: "", isPublic: false});
    }

    return avatar;
}
```

When building UI, always handle the case where `avatarURI` is empty (indicating private data).

## Off-Chain Metadata

Store rich metadata on IPFS or Arweave:

```json
{
  "username": "alice",
  "avatar": "https://gateway.pinata.cloud/ipfs/QmHash",
  "bio": "Web3 developer",
  "website": "https://alice.com",
  "social": {
    "twitter": "@alice",
    "github": "alice-dev",
    "discord": "alice#1234"
  }
}
```

**Upload to IPFS:**

```bash
# Using IPFS CLI
ipfs add metadata.json
# Output: QmXxxx...

# Or using Pinata/Infura
curl -X POST https://api.pinata.cloud/pinning/pinFileToIPFS \
  -F file=@metadata.json \
  -H "pinata_api_key: $KEY" \
  -H "pinata_secret_api_key: $SECRET"
```

Use the returned hash as the avatar URI:
```solidity
soulProfile.createProfile("alice", "ipfs://QmXxxx...");
```

## Integration Pattern

Integrate profiles in your dApp:

```solidity
import { IERC7866 } from "../interfaces/IERC7866.sol";

contract MyGame {
    IERC7866 public soulProfiles;

    constructor(address _soulProfileAddress) {
        soulProfiles = IERC7866(_soulProfileAddress);
    }

    function getPlayerName(address player) external view returns (string memory) {
        if (!soulProfiles.hasProfile(player)) {
            return "Anonymous";
        }

        IERC7866.Profile memory profile = soulProfiles.getProfile(player);
        return profile.username;
    }

    function getPlayerAvatar(address player) external view returns (string memory) {
        if (!soulProfiles.hasProfile(player)) {
            return "";
        }

        // Try game-specific avatar
        IERC7866.DappAvatar memory gameAvatar = soulProfiles.getDappAvatar(
            player,
            "MyGame"
        );

        if (bytes(gameAvatar.avatarURI).length > 0) {
            return gameAvatar.avatarURI;
        }

        // Fall back to default
        return soulProfiles.getDefaultAvatar(player);
    }
}
```

## Event Listening

Listen to profile events for discovery:

```typescript
const contract = new ethers.Contract(
    SOULPROFILE_ADDRESS,
    ABI,
    provider
);

// Track new profiles
contract.on("ProfileCreated", (owner, username) => {
    console.log(`New profile: ${username} by ${owner}`);
    // Index for discovery
});

// Track avatar updates
contract.on("DefaultAvatarUpdated", (owner, avatarURI) => {
    console.log(`${owner} updated avatar to ${avatarURI}`);
});

// Track dApp avatars
contract.on("DappAvatarSet", (owner, dappName, avatarURI, isPublic) => {
    console.log(`${owner} set ${dappName} avatar (public: ${isPublic})`);
});
```

## Resolver Usage

Use the resolver for safer profile lookups:

```solidity
SoulProfileResolver resolver = new SoulProfileResolver(address(soulProfile));

// Resolve with privacy checks already applied
string memory avatar = resolver.resolveDappAvatar(userAddress, "MyDApp");

// Resolve only public avatars
string memory publicAvatar = resolver.resolveDappAvatarPublic(userAddress, "MyDApp");

// Resolve username
string memory username = resolver.resolveUsername(userAddress);
```

## Best Practices

### Username Management
- Use lowercase for consistency
- Avoid special characters
- Reserve important names through governance if needed
- Consider allowing name changes in v2

### Avatar URIs
- Always validate URIs in frontend
- Use whitelist for allowed protocols (ipfs://, ar://, https://)
- Beware of javascript: and data: URIs
- Cache metadata locally with IPFS/Arweave gateway

### Privacy
- Always check `avatarURI` is not empty before using
- Private avatars return empty string, not null
- Remember that avatar existence is revealed through events
- Plan privacy strategy before deployment

### Gas Optimization
- Batch avatar updates in separate transactions
- Don't store large metadata on-chain
- Use IPFS/Arweave for all media

## Testing

Test with Foundry:

```solidity
function testCreateProfile() public {
    vm.prank(alice);
    soulProfile.createProfile("alice", "ipfs://avatar");

    IERC7866.Profile memory profile = soulProfile.getProfile(alice);
    assertEq(profile.username, "alice");
}

function testPrivateAvatar() public {
    vm.prank(alice);
    soulProfile.createProfile("alice", "ipfs://avatar");

    vm.prank(alice);
    soulProfile.setDappAvatar("Game", "ipfs://game", false);  // private

    // Owner can see
    IERC7866.DappAvatar memory avatar1 = soulProfile.getDappAvatar(alice, "Game");
    assertNotEq(bytes(avatar1.avatarURI).length, 0);

    // Non-owner cannot see
    vm.prank(bob);
    IERC7866.DappAvatar memory avatar2 = soulProfile.getDappAvatar(alice, "Game");
    assertEq(bytes(avatar2.avatarURI).length, 0);
}
```

## Common Patterns

### Multi-dApp Avatar Strategy
```solidity
// Public default for discoverability
setDefaultAvatar("ipfs://public...");

// Game-specific for context
setDappAvatar("GameA", "ipfs://character...", true);
setDappAvatar("GameB", "ipfs://different...", true);

// Private for sensitive data
setDappAvatar("PrivateApp", "ipfs://sensitive...", false);
```

### Profile Discovery
```typescript
// Build username index from events
const profiles = new Map<string, string>();

contract.on("ProfileCreated", (owner, username) => {
    profiles.set(username, owner);
});

// Later, lookup by username
const ownerAddress = profiles.get("alice");
```

### Cross-Game Avatar Sync
```solidity
// Use same dApp name on multiple games
// All integrate the same avatar across games

// Or use a custom dApp name for the sync service
soulProfile.setDappAvatar(
    "CrossGameAvatar",
    "ipfs://universal-avatar...",
    true
);
```
