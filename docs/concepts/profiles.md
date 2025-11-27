# Profile Structure

Understanding the core data structures in ERC-7866.

## Profile

The main user profile containing core identity information:

```solidity
struct Profile {
    string username;           // Unique, immutable identifier
    string defaultAvatarURI;   // Primary avatar (IPFS/Arweave URI)
    string bio;                // User biography
    string website;            // Associated website
}
```

### Properties

**Username**
- Unique across the contract (globally unique if same contract for all)
- Immutable (cannot be changed after creation)
- 1-32 characters
- Used for human-readable identification
- Reverse-lookup enabled (username → address)

**Default Avatar URI**
- Pointer to off-chain metadata (IPFS or Arweave)
- Used by all dApps by default if no specific avatar set
- Can be updated anytime
- Typically points to metadata JSON or image

**Bio**
- User biography or description
- Optional field
- Can be updated

**Website**
- Associated website or homepage
- Optional field
- Can be updated

## DApp Avatar

Context-specific avatar for individual applications:

```solidity
struct DappAvatar {
    string dappName;           // Which dApp this avatar is for
    string avatarURI;          // Avatar metadata (IPFS/Arweave)
    bool isPublic;             // Visibility setting
}
```

### Properties

**dApp Name**
- Identifier for which dApp
- Immutable once set (delete and recreate to change)
- Examples: "GameA", "MyDApp", "SocialNetwork"

**Avatar URI**
- Metadata pointer similar to default avatar
- Can be updated independently
- Game-specific, app-specific, or context-specific data

**Visibility Flag**
- `true` = public (anyone can see)
- `false` = private (only owner can see)
- Enforced at function call time
- Can be toggled on updates

## Storage Layout

```solidity
mapping(address => Profile) private profiles;
mapping(address => mapping(string => DappAvatar)) private dappAvatars;
mapping(string => address) private usernameToAddress;
mapping(address => bool) private _hasProfile;
```

**Profiles Mapping**
- Key: User address
- Value: Profile struct
- One profile per address

**DApp Avatars Mapping**
- Key 1: User address
- Key 2: dApp name (string)
- Value: DappAvatar struct
- Multiple avatars per user (unlimited dApps)

**Username Registry**
- Key: Username (string)
- Value: Owner address
- Enables reverse lookup

**Profile Existence Flag**
- Key: User address
- Value: Boolean
- Quick check if profile exists

## Metadata Schema

Off-chain metadata stored on IPFS/Arweave:

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
      "level": 42,
      "avatar": "ipfs://QmGameA..."
    },
    "GameB": {
      "avatar": "ipfs://QmGameB...",
      "customData": {}
    }
  }
}
```

### Schema Fields

- **username**: Matches on-chain username
- **avatar**: Image URL or IPFS pointer
- **bio**: Longer biography
- **website**: Personal/professional website
- **socialLinks**: Social media handles
- **dappProfiles**: Per-dApp metadata and customization

The on-chain contract only stores URIs pointing to this metadata, keeping gas costs low while allowing rich data.

## Creation and Ownership

Profiles are created by the address that will own them:

```solidity
function createProfile(string memory username, string memory defaultAvatarURI)
    external
{
    // msg.sender becomes the owner
    profiles[msg.sender] = Profile({...});
    usernameToAddress[username] = msg.sender;
    _hasProfile[msg.sender] = true;
}
```

**Ownership Rules**
- Only the address that created the profile can modify it
- Ownership is permanent (cannot be transferred)
- Only owner can set/update avatars
- Only owner can see private avatars

## Profile Identifiers

### On-Chain Address
```
0xAlice1234567890abcdef1234567890ABCDEF123
```

### Username
```
alice
```

### Human-Readable Format
```
alice@eth.soul          (Ethereum)
alice@polygon.soul      (Polygon)
alice@arb.soul          (Arbitrum)
```

### Decentralized Identifier (DID)
```
did:eip155:1:0xAlice...        (Ethereum mainnet)
did:eip155:137:0xAlice...      (Polygon)
did:eip155:42161:0xAlice...    (Arbitrum)
```
