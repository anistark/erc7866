# ERC-7866: Decentralised User Profiles

**Gravatar for Web3** — A production-ready standard for decentralized, interoperable user profiles on EVM blockchains. Users can claim unique usernames, set avatars, and maintain customizable identities across multiple dApps and networks.

Just like Gravatar lets you set a global avatar once and use it everywhere, ERC-7866 lets you claim a soul-bound username and avatar on-chain. But with full control, privacy options, and dApp-specific customization.

📖 **[Read the EIP-7866 specification](https://eips.ethereum.org/EIPS/eip-7866)**

## Requirements

- **Node.js**: 22+ (recommended: 24)
- **npm**: 10+
- **Foundry**: For smart contract development (optional)

## Features

- **Unique Identities**: Claim a human-readable username (`alice@eth.soul`) mapped to your address
- **Cross-dApp Avatars**: Set different avatars for different applications (gaming avatar, professional avatar, etc.)
- **Privacy Control**: Mark avatars as public or private with on-chain enforcement
- **Multi-Chain Ready**: Same identity format works across Ethereum, Polygon, Arbitrum, and other EVM chains
- **Off-Chain Efficient**: Metadata stored on IPFS/Arweave with minimal on-chain footprint
- **Event-Driven**: Full event logging for profile discovery and indexing

## Documentation

View the full documentation at https://anistark.github.io/erc7866

### Render Docs Locally

```sh
# Install Mintlify globally
npm install -g mintlify

# Start local development server
npm run docs:dev

# Open http://localhost:3000 in your browser
```

The docs will hot-reload as you make changes.

### Build Static Site

```sh
# Build production-ready static site
npm run docs:build

# Output in ./out directory
```

## Quick Start

### Deploy SoulProfile

```solidity
import { SoulProfile } from "./contracts/core/SoulProfile.sol";

// Deploy contract
SoulProfile profile = new SoulProfile();
```

### Create Your Profile

```solidity
// Create profile with username and avatar
profile.createProfile(
    "alice",
    "ipfs://QmXxxxx..." // Avatar metadata URI
);
```

### Set Avatars

```solidity
// Set default avatar (used across all dApps by default)
profile.setDefaultAvatar("ipfs://QmYyyyy...");

// Set dApp-specific avatar (public for everyone to see)
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

### Retrieve Profiles

```solidity
// Get full profile
SoulProfile.Profile memory profile = soulProfile.getProfile(userAddress);

// Look up address by username
address alice = soulProfile.getProfileByUsername("alice");

// Get dApp-specific avatar (with privacy enforcement)
SoulProfile.DappAvatar memory gameAvatar = soulProfile.getDappAvatar(
    userAddress,
    "MyGameDApp"
);
```

## Profile Structure

Each profile contains:

```solidity
struct Profile {
    string username;           // Unique, immutable identifier
    string defaultAvatarURI;   // Primary avatar (IPFS/Arweave URI)
    string bio;                // User biography
    string website;            // Associated website
}
```

And can have unlimited dApp-specific avatars:

```solidity
struct DappAvatar {
    string dappName;           // Which dApp this avatar is for
    string avatarURI;          // Avatar metadata (IPFS/Arweave)
    bool isPublic;             // Visibility setting
}
```

## How It Works

### Profile Lifecycle

1. **Create**: User calls `createProfile()` with unique username
2. **Customize**: Set default avatar and dApp-specific avatars
3. **Discover**: Other contracts/apps look up profiles by address or username
4. **Update**: User can change avatars anytime (username is permanent)

### Privacy Model

- **Public Avatars**: Anyone can see and retrieve
- **Private Avatars**: Only the profile owner can see; others get empty URI
- **Enforcement**: Privacy is checked at read time in `getDappAvatar()`

### Multi-Chain Profiles

Use the same username across chains by deploying to multiple networks:

```
Ethereum:  alice@eth.soul      → 0xAlice
Polygon:   alice@polygon.soul  → 0xAlice
Arbitrum:  alice@arb.soul      → 0xAlice
```

## Smart Contracts

### IERC7866 Interface
`contracts/interfaces/IERC7866.sol`

Standard interface defining the ERC-7866 specification. All implementations must support these functions.

### SoulProfile
`contracts/core/SoulProfile.sol`

Full-featured implementation with:
- Profile creation and management
- Username registry
- dApp avatar management
- Privacy enforcement
- Event emissions for indexing

### SoulProfileResolver
`contracts/extensions/SoulProfileResolver.sol`

Optional resolver contract for:
- Safe profile discovery
- Privacy-aware lookups
- Username resolution
- dApp integration helpers

## Use Cases

### User Identity
Create a portable identity that follows you across Web3 apps without needing MetaMask to reveal your history.

### Gaming
Different games can set their own character avatars on your profile. Players see game-specific art and metadata.

### Professional Profiles
Maintain separate avatars for work (LinkedIn-style) and personal use (Twitter-style).

### dApp Discovery
dApps can search for users by username or avatar, enabling social features and communities.

### Account Recovery
If you lose access to a wallet, your username and verified identity remain on-chain.

## Integration Example

```solidity
// In your dApp smart contract
import { IERC7866 } from "./interfaces/IERC7866.sol";

contract MyDApp {
    IERC7866 public soulProfiles;

    constructor(address _soulProfileAddress) {
        soulProfiles = IERC7866(_soulProfileAddress);
    }

    function getPlayerProfile(address player)
        external
        view
        returns (string memory username, string memory avatar)
    {
        if (!soulProfiles.hasProfile(player)) {
            return ("", "");
        }

        IERC7866.Profile memory profile = soulProfiles.getProfile(player);

        // Try to get game-specific avatar first
        IERC7866.DappAvatar memory gameAvatar = soulProfiles.getDappAvatar(
            player,
            "MyDApp"
        );

        // Fall back to default if game avatar not set
        string memory displayAvatar = bytes(gameAvatar.avatarURI).length > 0
            ? gameAvatar.avatarURI
            : profile.defaultAvatarURI;

        return (profile.username, displayAvatar);
    }
}
```

## Gas Costs

Estimated costs based on the SoulProfile.sol implementation:

- **Profile Creation**: ~50,000 gas (stores Profile struct, username mapping, and state flags)
- **Update Avatar**: ~30,000 gas per operation (SSTORE for avatar URI and visibility)
- **Profile Lookup**: ~5,000 gas (view function, reading Profile struct from storage)
- **Avatar Lookup**: ~3,000 gas (view function, reading from dappAvatars mapping)

**Important Notes:**
- These are rough estimates; actual gas depends on network, compiler optimizations, and EVM version
- Add 21,000 base transaction cost plus calldata costs to on-chain operations
- Gas varies between networks (Ethereum mainnet vs. Layer 2s like Polygon, Arbitrum)
- Costs do not include external calls or reentrancy checks
- For production, benchmark on your target network before deployment

## Documentation

- **[Implementation Guide](./guides/IMPLEMENTATION.md)** — Complete guide with practical examples and patterns
- **[Specification](./docs/SPECIFICATION.md)** — Technical specification, data structures, and security considerations
- **[EIP-7866](https://eips.ethereum.org/EIPS/eip-7866)** — Original proposal

## Security

- **Non-transferable**: Profiles are soul bound to addresses, cannot be transferred
- **Immutable Usernames**: Once created, usernames cannot be changed
- **Privacy Enforced**: Private avatar URIs hidden at function level, not just in storage
- **No Reentrancy**: Safe from reentrancy attacks; state changes before external calls
- **Ownership**: Only profile owner can modify their profile

**[License - MIT](./LICENSE)**
