# Full Specification

Complete technical specification for ERC-7866.

## Abstract

ERC-7866 defines a standard interface for decentralized user profiles implemented as Soul Bound Tokens (SBTs). These profiles are non-transferable, immutable identity containers that enable interoperable user representation across multiple blockchain networks and dApps.

## Motivation

Current blockchain applications lack unified identity standards. Users face:

1. **Fragmentation** — Separate profiles across each dApp
2. **No Portability** — Identity tied to single application
3. **Privacy Issues** — Wallet history exposed to all dApps
4. **No Standards** — Each app implements identity differently

ERC-7866 solves these by providing:

1. **Interoperability** — Consistent profile format across dApps
2. **Portability** — Identity follows user across networks
3. **Privacy** — User-controlled visibility for profile data
4. **Standardization** — Everyone implements the same interface

## Specification

### Profile Data Structure

```solidity
struct Profile {
    string username;           // Unique, immutable identifier
    string defaultAvatarURI;   // Primary avatar/metadata pointer
    string bio;                // User biography
    string website;            // Associated website
}
```

**Properties**:

- **username**: 1-32 characters, globally unique, immutable
- **defaultAvatarURI**: Pointer to off-chain metadata (IPFS/Arweave)
- **bio**: Optional user description
- **website**: Optional website link

### DApp Avatar Structure

```solidity
struct DappAvatar {
    string dappName;           // Associated dApp identifier
    string avatarURI;          // dApp-specific metadata
    bool isPublic;             // Public/private visibility flag
}
```

**Properties**:

- **dappName**: Identifies which dApp (e.g., "GameA", "Twitter")
- **avatarURI**: Off-chain metadata pointer
- **isPublic**: `true` for public, `false` for private avatars

### Profile Identifiers

#### Human-Readable Format

```
username@network_slug.soul
```

Examples:
- `alice@eth.soul` (Ethereum)
- `bob@polygon.soul` (Polygon)
- `charlie@arb.soul` (Arbitrum)

#### Decentralized Identifier (DID)

```
did:eip155:chainId:address
```

Examples:
- `did:eip155:1:0xAlice...` (Ethereum mainnet)
- `did:eip155:137:0xBob...` (Polygon)
- `did:eip155:42161:0xCharlie...` (Arbitrum)

### Interface Definition

#### State-Changing Functions

##### createProfile

```solidity
function createProfile(
    string memory username,
    string memory defaultAvatarURI
) external
```

Creates a new profile for the caller.

**Parameters**:
- `username`: Unique identifier (1-32 chars)
- `defaultAvatarURI`: Initial avatar URI

**Preconditions**:
- Caller must not have existing profile
- Username must not be taken
- Username must be 1-32 characters

**State Changes**:
- Create Profile struct
- Add to username registry
- Emit ProfileCreated event

**Emits**: `ProfileCreated(msg.sender, username)`

##### setDefaultAvatar

```solidity
function setDefaultAvatar(string memory avatarURI) external
```

Updates the default avatar.

**Parameters**:
- `avatarURI`: New avatar URI

**Preconditions**:
- Caller must have existing profile

**State Changes**:
- Update defaultAvatarURI in Profile

**Emits**: `DefaultAvatarUpdated(msg.sender, avatarURI)`

##### setDappAvatar

```solidity
function setDappAvatar(
    string memory dappName,
    string memory avatarURI,
    bool isPublic
) external
```

Sets or updates a dApp-specific avatar.

**Parameters**:
- `dappName`: dApp identifier
- `avatarURI`: Avatar metadata URI
- `isPublic`: Visibility flag

**Preconditions**:
- Caller must have existing profile
- dappName must not be empty

**State Changes**:
- Create or update DappAvatar entry
- One avatar per dApp per user

**Emits**: `DappAvatarSet(msg.sender, dappName, avatarURI, isPublic)`

##### removeDappAvatar

```solidity
function removeDappAvatar(string memory dappName) external
```

Removes a dApp avatar.

**Parameters**:
- `dappName`: dApp identifier to remove

**Preconditions**:
- Caller must have existing profile

**State Changes**:
- Delete DappAvatar mapping entry

**Emits**: `DappAvatarRemoved(msg.sender, dappName)`

#### View Functions

##### getProfile

```solidity
function getProfile(address owner)
    external view
    returns (Profile memory)
```

Retrieves complete profile.

**Parameters**:
- `owner`: Profile owner address

**Returns**: Full Profile struct

**Reverts**: If profile doesn't exist

##### getDefaultAvatar

```solidity
function getDefaultAvatar(address owner)
    external view
    returns (string memory)
```

Retrieves default avatar URI.

**Parameters**:
- `owner`: Profile owner address

**Returns**: Avatar URI string

**Reverts**: If profile doesn't exist

##### getDappAvatar

```solidity
function getDappAvatar(
    address owner,
    string memory dappName
) external view
    returns (DappAvatar memory)
```

Retrieves dApp-specific avatar.

**Parameters**:
- `owner`: Profile owner address
- `dappName`: dApp identifier

**Returns**: DappAvatar struct

**Privacy Enforcement**:
- If `avatar.isPublic == false` AND `msg.sender != owner`:
  - Return DappAvatar with empty `avatarURI`
- Otherwise: Return full DappAvatar

##### getProfileByUsername

```solidity
function getProfileByUsername(string memory username)
    external view
    returns (address)
```

Reverse lookup: username to address.

**Parameters**:
- `username`: Profile username

**Returns**: Owner address, or address(0) if not found

##### hasProfile

```solidity
function hasProfile(address owner)
    external view
    returns (bool)
```

Check if profile exists.

**Parameters**:
- `owner`: Address to check

**Returns**: `true` if profile exists, `false` otherwise

### Events

#### ProfileCreated

```solidity
event ProfileCreated(address indexed owner, string username)
```

Emitted when new profile is created.

#### DefaultAvatarUpdated

```solidity
event DefaultAvatarUpdated(address indexed owner, string avatarURI)
```

Emitted when default avatar is updated.

#### DappAvatarSet

```solidity
event DappAvatarSet(
    address indexed owner,
    string dappName,
    string avatarURI,
    bool isPublic
)
```

Emitted when dApp avatar is set or updated.

#### DappAvatarRemoved

```solidity
event DappAvatarRemoved(address indexed owner, string dappName)
```

Emitted when dApp avatar is removed.

## Off-Chain Metadata

Profile metadata is stored off-chain to minimize gas costs.

### Recommended Format

```json
{
  "username": "alice",
  "avatar": "https://example.com/avatar.png",
  "bio": "Web3 developer",
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

### Storage

Metadata should be stored on:
- **IPFS**: Content-addressable, immutable
- **Arweave**: Permanent, pay-once storage
- **HTTPS**: Traditional web servers (centralized)

## Privacy Model

### Avatar Visibility

Avatars support two visibility levels:

**Public Avatars**:
- Readable by anyone
- Returned as-is to all callers
- Use for user branding, identity

**Private Avatars**:
- Readable only by owner
- Returns empty URI to non-owners
- Use for account-specific, sensitive data

### Enforcement Mechanism

Privacy enforced at read time in `getDappAvatar()`:

```solidity
if (!avatar.isPublic && msg.sender != owner) {
    return DappAvatar({dappName: dappName, avatarURI: "", isPublic: false});
}
return avatar;
```

**Characteristics**:
- Computed per request (not stored)
- Cannot be bypassed at Solidity level
- Requires smart contract enforcement

### Event Transparency

Note: All events are public on-chain
- Observers can see that an avatar was set
- Observers see visibility flag (public/private)
- Observers cannot see private avatar URIs

## Multi-Chain Support

### Same Address Across Chains

Users maintain same address on all EVM chains (derived from same private key).

### Independent Deployments

Each chain has independent SoulProfile deployment:
- Ethereum SoulProfile contract
- Polygon SoulProfile contract
- Arbitrum SoulProfile contract

### Profile Consistency

Users can create same username on multiple chains:

```
Alice on Ethereum:  alice@eth.soul      → 0xAlice
Alice on Polygon:   alice@polygon.soul  → 0xAlice
Alice on Arbitrum:  alice@arb.soul      → 0xAlice
```

All owned by same address: `0xAlice`

### No Cross-Chain Synchronization

Profiles are **not** synchronized between chains:
- Each chain's profile is independent
- No bridging required
- Users must create separately per chain

## Implementation Requirements

### Implementations MUST

1. Store exactly one profile per address
2. Enforce username uniqueness
3. Prevent username changes
4. Enforce privacy on private avatars
5. Support all required functions
6. Emit required events
7. Revert on invalid operations

### Implementations MAY

1. Add additional profile fields
2. Implement custom metadata schemas
3. Add reputation/verification
4. Implement governance for reserved names
5. Add rate limiting
6. Cache for optimization

### Implementations SHOULD NOT

1. Allow profile transfers
2. Allow username changes
3. Allow others to modify profiles
4. Bypass privacy enforcement
5. Add centralized control

## Gas Efficiency

### Expected Costs

- Profile creation: ~50,000 gas
- Avatar update: ~30,000 gas
- Profile read: ~5,000 gas
- Avatar read: ~3,000 gas

### Optimization Strategies

1. Use off-chain metadata to reduce on-chain data
2. Keep usernames short (saves calldata)
3. Batch operations to amortize overhead
4. Deploy on L2s for lower costs

## Backwards Compatibility

### With Existing Standards

- **ERC165**: Can implement to signal support
- **ERC191**: Can use for signature-based operations
- **ERC712**: Can use for typed data operations
- **ERC721/ERC1155**: Not related (SBTs are non-fungible, non-transferable)

### Future Upgrades

Future versions could add:
- Profile metadata versioning
- Cross-chain profile sync
- Governance for name reservation
- Reputation systems
- Social graph features

## Rationale

### Why Soul Bound?

Non-transferable profiles ensure:
- Identity tied to specific address
- No ability to "sell" identity
- Prevents impersonation and hijacking
- Aligns with personal identity use case

### Why Immutable Usernames?

Immutability ensures:
- Permanent, reliable reverse lookup
- Prevents username squatting/takeover
- Enables long-term identity
- Simplifies indexing and discovery

### Why Off-Chain Metadata?

Off-chain storage minimizes:
- Gas costs (critical for adoption)
- On-chain storage bloat
- While maintaining on-chain verification

### Why Privacy at Read Time?

Runtime privacy checks enable:
- Flexible privacy model per avatar
- No special storage requirements
- Simple implementation
- Clear access control

## Security Considerations

### Addressed

- **Non-transferability**: Prevents identity theft
- **Immutable usernames**: Prevents hijacking
- **Access control**: Only owner can modify
- **Privacy enforcement**: Hidden from non-owners
- **No reentrancy**: Safe implementation pattern

### Out of Scope

- **URI validation**: Frontends should validate
- **Content moderation**: Off-chain responsibility
- **Homograph attacks**: Client-level validation
- **Flash loan attacks**: Not applicable to profiles

## References

- [Soul Bound Tokens](https://vitalik.ca/general/2022/01/26/soulbound.html)
- [EIP191: Signed Data](https://eips.ethereum.org/EIPS/eip-191)
- [EIP712: Typed structured data hashing](https://eips.ethereum.org/EIPS/eip-712)
- [ERC165: Standard Interface Detection](https://eips.ethereum.org/EIPS/erc-165)
- [IPFS](https://ipfs.io/)
- [Arweave](https://www.arweave.org/)

## Test Cases

All implementations should pass these tests:

- Profile creation with valid username
- Profile creation fails with duplicate username
- Profile creation fails with invalid username length
- Only owner can update avatar
- Private avatars hidden from non-owners
- Public avatars visible to all
- Username lookup returns correct address
- Profile existence check works correctly
- Avatar removal works correctly
- All events emit correctly

## Version History

**v1.0** (Current)
- Initial specification
- Core profile functionality
- Multi-chain support
- Privacy enforcement
