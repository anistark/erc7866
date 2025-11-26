# ERC-7866 Specification

## Abstract

ERC-7866 defines a standard interface for decentralized user profiles implemented as Soul Bound Tokens (SBTs). These profiles are non-transferable, immutable identity containers that enable interoperable user representation across multiple blockchain networks.

## Motivation

Current blockchain applications lack a unified identity standard. ERC-7866 provides:

1. **Interoperability**: Consistent profile format across dApps and chains
2. **Privacy**: User-controlled visibility for sensitive profile data
3. **Flexibility**: dApp-specific avatars and metadata
4. **Decentralization**: No central authority controls profiles
5. **Efficiency**: Off-chain storage with on-chain verification

## Specification

### Data Structures

#### Profile
Represents a user's core identity:
```solidity
struct Profile {
    string username;           // Unique, human-readable identifier
    string defaultAvatarURI;   // Primary avatar/metadata pointer
    string bio;                // User biography
    string website;            // Associated website
}
```

Constraints:
- Username: 1-32 characters, globally unique, immutable
- Avatar URI: Points to off-chain metadata (IPFS/Arweave)
- One profile per address

#### DappAvatar
dApp-specific avatar context:
```solidity
struct DappAvatar {
    string dappName;           // Associated dApp identifier
    string avatarURI;          // dApp-specific avatar/metadata
    bool isPublic;             // Visibility control
}
```

Constraints:
- One avatar per dApp per user
- Privacy enforced at function level
- Immutable dApp name

### Interface (IERC7866)

#### State-Changing Functions

```solidity
function createProfile(
    string memory username,
    string memory defaultAvatarURI
) external
```
- Creates new profile for caller
- Validates username uniqueness and length
- Emits `ProfileCreated` event
- Reverts if profile already exists

```solidity
function setDefaultAvatar(string memory avatarURI) external
```
- Updates primary avatar URI
- Only callable by profile owner
- Emits `DefaultAvatarUpdated` event

```solidity
function setDappAvatar(
    string memory dappName,
    string memory avatarURI,
    bool isPublic
) external
```
- Creates or updates dApp-specific avatar
- Caller controls visibility (public/private)
- Emits `DappAvatarSet` event
- Overwrites existing avatar if dApp already set

```solidity
function removeDappAvatar(string memory dappName) external
```
- Deletes dApp avatar mapping
- Only callable by profile owner
- Emits `DappAvatarRemoved` event

#### View Functions

```solidity
function getProfile(address owner)
    external view returns (Profile memory)
```
- Returns complete profile struct
- Reverts if profile doesn't exist

```solidity
function getDefaultAvatar(address owner)
    external view returns (string memory)
```
- Returns primary avatar URI
- Reverts if profile doesn't exist

```solidity
function getDappAvatar(
    address owner,
    string memory dappName
) external view returns (DappAvatar memory)
```
- Returns dApp avatar
- **Privacy Enforcement**: Returns empty URI if private and caller isn't owner
- Returns empty DappAvatar if not found

```solidity
function getProfileByUsername(string memory username)
    external view returns (address)
```
- Reverse lookup: username → address
- Returns address(0) if not found

```solidity
function hasProfile(address owner)
    external view returns (bool)
```
- Boolean check for profile existence

### Events

```solidity
event ProfileCreated(address indexed owner, string username);
```

```solidity
event DefaultAvatarUpdated(address indexed owner, string avatarURI);
```

```solidity
event DappAvatarSet(
    address indexed owner,
    string dappName,
    string avatarURI,
    bool isPublic
);
```

```solidity
event DappAvatarRemoved(address indexed owner, string dappName);
```

## Profile Identifiers

### Human-Readable Format
```
username@network_slug.soul
```
Examples:
- `alice@eth.soul` (Ethereum mainnet)
- `bob@polygon.soul` (Polygon)
- `charlie@arb.soul` (Arbitrum)

### Decentralized Identifier (DID)
```
did:chain:address
```
Examples:
- `did:eip155:1:0xAlice...` (Ethereum mainnet)
- `did:eip155:137:0xAlice...` (Polygon)

## Metadata Storage

### Off-Chain Format
Profile metadata is stored externally and referenced via URI:

```json
{
  "username": "alice",
  "avatar": "https://cdn.example.com/avatar.png",
  "bio": "Web3 developer and artist",
  "website": "https://alice.com",
  "socialLinks": {
    "twitter": "@alice",
    "github": "alice-dev",
    "discord": "alice#1234"
  },
  "dappProfiles": {
    "GameA": {
      "character": "Warrior",
      "level": 42
    },
    "GameB": {
      "avatar": "nft-metadata-uri"
    }
  }
}
```

Recommended storage:
- **IPFS**: Decentralized, immutable (use for static profiles)
- **Arweave**: Permanent storage with fees upfront

## Privacy Model

### Avatar Visibility

**Public Avatars**:
- Readable by anyone
- All queries return full data
- Use case: Branding, marketing avatars

**Private Avatars**:
- Readable only by owner
- Other callers receive empty URI
- Use case: Account-specific, sensitive metadata

### Enforcement

Privacy is enforced in `getDappAvatar()`:
```solidity
if (!avatar.isPublic && msg.sender != owner) {
    return DappAvatar({dappName: dappName, avatarURI: "", isPublic: false});
}
```

Not at storage level—visibility is computed per request.

## Implementation Patterns

### Single Chain
Deploy on one network, manage one identity:
```
SoulProfile (Ethereum)
├── alice
├── bob
└── charlie
```

### Multi-Chain
Same username on multiple chains:
```
Chain: Ethereum
├── alice@eth.soul → 0xAlice...

Chain: Polygon
├── alice@polygon.soul → 0xAlice...

Chain: Arbitrum
├── alice@arb.soul → 0xAlice...
```

### Resolver Pattern
Dedicated resolver for enhanced profile discovery:

```solidity
SoulProfileResolver
├── getDappResolver(dappName)
├── resolveUsername(address)
├── resolveDappAvatar(owner, dappName)
└── resolveDappAvatarPublic(owner, dappName)
```

## Compatibility

### References
- **ERC165**: Implement to signal ERC-7866 support
- **EIP191**: For signature-based profile creation
- **EIP712**: For typed profile updates

### With Existing Standards

**Alongside ERC-721/ERC-1155**:
- Profiles are SBTs, not NFTs
- Can complement NFT collections
- Use for user identity layer

**With ENS**:
- Both serve identity
- ERC-7866 is avatar/metadata focused
- ENS is name service focused

## Security Considerations

### Username Squatting
- Usernames are first-come, first-served
- No recovery mechanism
- Consider allowlists for sensitive names

### Avatar URI Validation
- Implementers should validate URIs
- Be cautious with javascript: protocols
- Use URI scheme whitelisting

### Privacy
- Private avatars expose ownership through events
- `DappAvatarSet` events are public
- Consider off-chain indexing for discovery

### Reentrancy
- State changes happen before external calls
- No cross-contract calls in core functions
- Safe from reentrancy attacks

## Gas Optimization

### Current Implementation
- Profile creation: ~50,000 gas
- Avatar update: ~30,000 gas per operation
- View functions: ~3,000-5,000 gas

### Possible Optimizations
- Packed storage for booleans
- Batch avatar updates
- Lazy initialization of dApp avatars

## Future Directions

1. **Account Abstraction**: EIP-4337 integration for gasless profile creation
2. **Governance**: Decentralized username reservation
3. **Social Graph**: Following/reputation extensions
4. **Interoperability**: Cross-chain profile sync
5. **Compression**: Reduced metadata size standards

## References

- [EIP-7866](https://eips.ethereum.org/EIPS/eip-7866)
- [Soul Bound Tokens](https://vitalik.ca/general/2022/01/26/soulbound.html)
- [Ethereum Name Service](https://ens.domains/)
- [IPFS](https://ipfs.io/)
- [Arweave](https://www.arweave.org/)
