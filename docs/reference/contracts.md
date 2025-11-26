# Smart Contracts Reference

Complete reference for all ERC-7866 contracts.

## IERC7866 Interface

```solidity
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface IERC7866 {
    struct Profile {
        string username;
        string defaultAvatarURI;
        string bio;
        string website;
    }

    struct DappAvatar {
        string dappName;
        string avatarURI;
        bool isPublic;
    }

    // Events
    event ProfileCreated(address indexed owner, string username);
    event DefaultAvatarUpdated(address indexed owner, string avatarURI);
    event DappAvatarSet(address indexed owner, string dappName, string avatarURI, bool isPublic);
    event DappAvatarRemoved(address indexed owner, string dappName);

    // State-changing functions
    function createProfile(string memory username, string memory defaultAvatarURI) external;
    function setDefaultAvatar(string memory avatarURI) external;
    function setDappAvatar(string memory dappName, string memory avatarURI, bool isPublic) external;
    function removeDappAvatar(string memory dappName) external;

    // View functions
    function getProfile(address owner) external view returns (Profile memory);
    function getDefaultAvatar(address owner) external view returns (string memory);
    function getDappAvatar(address owner, string memory dappName) external view returns (DappAvatar memory);
    function getProfileByUsername(string memory username) external view returns (address);
    function hasProfile(address owner) external view returns (bool);
}
```

## SoulProfile Implementation

Main implementation contract with full feature support.

### Constructor

```solidity
constructor()
```

No constructor arguments. Ownership is implicit (caller of functions).

### Core Functions

#### createProfile

```solidity
function createProfile(string memory username, string memory defaultAvatarURI) external
```

**Parameters**
- `username`: Unique identifier (1-32 characters)
- `defaultAvatarURI`: IPFS/Arweave URI to metadata

**Emits**: `ProfileCreated(msg.sender, username)`

**Reverts**:
- Profile already exists for caller
- Username already taken
- Username invalid length

**Gas**: ~50,000

#### setDefaultAvatar

```solidity
function setDefaultAvatar(string memory avatarURI) external
```

**Parameters**
- `avatarURI`: New avatar URI

**Emits**: `DefaultAvatarUpdated(msg.sender, avatarURI)`

**Requirements**:
- Caller must have a profile

**Gas**: ~30,000

#### setDappAvatar

```solidity
function setDappAvatar(
    string memory dappName,
    string memory avatarURI,
    bool isPublic
) external
```

**Parameters**
- `dappName`: dApp identifier
- `avatarURI`: Avatar metadata URI
- `isPublic`: Public/private visibility flag

**Emits**: `DappAvatarSet(msg.sender, dappName, avatarURI, isPublic)`

**Requirements**:
- Caller must have a profile
- dappName must not be empty

**Notes**:
- Creates new avatar if dappName doesn't exist
- Updates existing avatar otherwise
- One avatar per dApp per user

**Gas**: ~30,000

#### removeDappAvatar

```solidity
function removeDappAvatar(string memory dappName) external
```

**Parameters**
- `dappName`: dApp identifier to remove

**Emits**: `DappAvatarRemoved(msg.sender, dappName)`

**Requirements**:
- Caller must have a profile

**Gas**: ~5,000

### View Functions

#### getProfile

```solidity
function getProfile(address owner)
    external view
    returns (Profile memory)
```

**Parameters**
- `owner`: Profile owner address

**Returns**: Complete Profile struct

**Reverts**: Profile doesn't exist

**Gas**: ~5,000

#### getDefaultAvatar

```solidity
function getDefaultAvatar(address owner)
    external view
    returns (string memory)
```

**Parameters**
- `owner`: Profile owner address

**Returns**: Avatar URI string

**Reverts**: Profile doesn't exist

**Gas**: ~3,000

#### getDappAvatar

```solidity
function getDappAvatar(address owner, string memory dappName)
    external view
    returns (DappAvatar memory)
```

**Parameters**
- `owner`: Profile owner address
- `dappName`: dApp identifier

**Returns**: DappAvatar struct

**Privacy**:
- If avatar is private and `msg.sender != owner`, returns empty URI
- Public avatars always return full data

**Gas**: ~3,000

#### getProfileByUsername

```solidity
function getProfileByUsername(string memory username)
    external view
    returns (address)
```

**Parameters**
- `username`: Profile username

**Returns**: Owner address of profile, or address(0) if not found

**Gas**: ~3,000

#### hasProfile

```solidity
function hasProfile(address owner) external view returns (bool)
```

**Parameters**
- `owner`: Address to check

**Returns**: True if profile exists, false otherwise

**Gas**: ~2,100

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

## SoulProfileResolver Extension

Optional resolver contract for profile discovery and privacy enforcement.

### Constructor

```solidity
constructor(address _soulProfileAddress)
```

**Parameters**
- `_soulProfileAddress`: Address of deployed SoulProfile contract

**Reverts**: Invalid address (zero address)

### Functions

#### registerDappResolver

```solidity
function registerDappResolver(string memory dappName, address resolver) external
```

**Parameters**
- `dappName`: dApp identifier
- `resolver`: Resolver contract address

**Emits**: `DappResolverRegistered(dappName, resolver)`

**Requirements**:
- Resolver address must not be zero
- dAppName must not be empty

**Notes**:
- Caller can be anyone (open registration)
- Resolver address should implement resolver interface

#### disableDappResolver

```solidity
function disableDappResolver(string memory dappName) external
```

**Parameters**
- `dappName`: dApp identifier to disable

**Emits**: `DappResolverDisabled(dappName)`

#### resolveDappAvatar

```solidity
function resolveDappAvatar(address owner, string memory dappName)
    external view
    returns (string memory)
```

**Parameters**
- `owner`: Profile owner
- `dappName`: dApp identifier

**Returns**: Avatar URI with privacy checks applied

**Notes**:
- Returns empty string if private and caller isn't owner
- Already delegates to SoulProfile privacy checks

#### resolveDappAvatarPublic

```solidity
function resolveDappAvatarPublic(address owner, string memory dappName)
    external view
    returns (string memory)
```

**Parameters**
- `owner`: Profile owner
- `dappName`: dApp identifier

**Returns**: Avatar URI only if public, empty string otherwise

#### resolveUsername

```solidity
function resolveUsername(address owner)
    external view
    returns (string memory)
```

**Parameters**
- `owner`: Profile owner

**Returns**: Username string, empty if profile doesn't exist

#### resolveProfileURI

```solidity
function resolveProfileURI(address owner)
    external view
    returns (string memory)
```

**Parameters**
- `owner`: Profile owner

**Returns**: Default avatar URI, empty if profile doesn't exist

#### getDappResolver

```solidity
function getDappResolver(string memory dappName)
    external view
    returns (address, bool)
```

**Parameters**
- `dappName`: dApp identifier

**Returns**:
- Resolver address
- Enabled flag

## Error Handling

### Common Revert Messages

| Condition | Message |
|-----------|---------|
| Profile doesn't exist | "Profile does not exist" |
| Profile already exists | "Profile already exists" |
| Username taken | "Username already taken" |
| Invalid username length | "Invalid username length" |
| Invalid dApp name | "Invalid dapp name" |
| Invalid resolver address | "Invalid resolver address" |
| Only owner | "Only profile owner can perform this action" |

## Integration Checklist

- [ ] Import IERC7866 interface
- [ ] Reference correct SoulProfile address
- [ ] Verify on correct network
- [ ] Handle profile existence checks
- [ ] Implement privacy fallback for empty URIs
- [ ] Test avatar updates don't break dApp
- [ ] Listen to events for discovery
- [ ] Cache profile data locally

## Testing with Foundry

```solidity
import { SoulProfile } from "../contracts/core/SoulProfile.sol";
import { IERC7866 } from "../contracts/interfaces/IERC7866.sol";

contract SoulProfileTest {
    SoulProfile soulProfile;
    address alice = address(0x1);
    address bob = address(0x2);

    function setUp() public {
        soulProfile = new SoulProfile();
    }

    function test_CreateProfile() public {
        vm.prank(alice);
        soulProfile.createProfile("alice", "ipfs://avatar");

        assert(soulProfile.hasProfile(alice));
    }

    function test_PrivateAvatarHidden() public {
        vm.prank(alice);
        soulProfile.createProfile("alice", "ipfs://avatar");

        vm.prank(alice);
        soulProfile.setDappAvatar("Game", "ipfs://game", false);

        vm.prank(bob);
        IERC7866.DappAvatar memory avatar = soulProfile.getDappAvatar(alice, "Game");
        assert(bytes(avatar.avatarURI).length == 0);
    }
}
```

## Deployment Verification

After deployment, verify contracts:

```bash
# Verify on Etherscan
forge verify-contract \
    --compiler-version v0.8.0 \
    <ADDRESS> \
    contracts/core/SoulProfile.sol:SoulProfile

# Or with constructor args
forge verify-contract \
    --constructor-args $(cast abi-encode "constructor(address)" <PROFILE_ADDRESS>) \
    <RESOLVER_ADDRESS> \
    contracts/extensions/SoulProfileResolver.sol:SoulProfileResolver
```
