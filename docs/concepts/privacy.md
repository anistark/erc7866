# Privacy Model

How ERC-7866 handles data visibility and privacy.

## Visibility Levels

ERC-7866 supports two avatar visibility levels:

### Public Avatars

```solidity
profile.setDappAvatar("PublicDApp", "ipfs://QmHash", true);  // isPublic = true
```

**Characteristics**
- Readable by anyone
- No restrictions on access
- Return full avatar data to any caller
- Events are public

**Use Cases**
- Marketing avatars
- Professional branding
- Game characters (in public games)
- Community-facing identity

### Private Avatars

```solidity
profile.setDappAvatar("PrivateDApp", "ipfs://QmHash", false); // isPublic = false
```

**Characteristics**
- Readable only by owner
- Other callers get empty URI
- No indication of existence to others
- Still emits events (events are always public)

**Use Cases**
- Personal/sensitive data
- Account-specific metadata
- Private app data
- Hidden game progress

## Privacy Enforcement

Privacy is enforced at the function call level, not storage level:

```solidity
function getDappAvatar(address owner, string memory dappName)
    external view
    returns (DappAvatar memory)
{
    DappAvatar memory avatar = dappAvatars[owner][dappName];

    // Privacy check at execution time
    if (!avatar.isPublic && msg.sender != owner) {
        return DappAvatar({dappName: dappName, avatarURI: "", isPublic: false});
    }

    return avatar;
}
```

**How It Works**
1. Function checks if avatar is private: `!avatar.isPublic`
2. Function checks if caller is owner: `msg.sender != owner`
3. If both true, return empty URI instead of actual data
4. Otherwise, return full avatar data

## Default Avatar Privacy

Default avatars are **always public**:

```solidity
function getDefaultAvatar(address owner)
    external view
    returns (string memory)
{
    require(_hasProfile[owner], "Profile does not exist");
    return profiles[owner].defaultAvatarURI;  // No privacy check
}
```

**Rationale**
- Default avatar is meant to be a public identity
- Provides a baseline, discoverable avatar
- dApp-specific avatars can override with privacy

## Profile Existence

Checking if a profile exists is always public:

```solidity
function hasProfile(address owner) external view returns (bool) {
    return _hasProfile[owner];
}
```

**Note**: The fact that an address has a profile is public knowledge. Only the avatar URIs (for private avatars) are hidden.

## Event Visibility

All events are public and on-chain:

```solidity
event DappAvatarSet(
    address indexed owner,
    string dappName,
    string avatarURI,
    bool isPublic
);
```

**Important**: Even if you set a private avatar, the event logs:
- That an avatar was set
- For which dApp
- The owner address
- Whether it's public or private

## Resolver Pattern

The `SoulProfileResolver` contract provides privacy-aware lookups:

```solidity
// Returns avatar only if public
function resolveDappAvatarPublic(address owner, string memory dappName)
    external view
    returns (string memory)
{
    DappAvatar memory avatar = soulProfile.getDappAvatar(owner, dappName);
    if (!avatar.isPublic) {
        return "";
    }
    return avatar.avatarURI;
}

// Returns avatar if public OR caller is owner
function resolveDappAvatar(address owner, string memory dappName)
    external view
    returns (string memory)
{
    DappAvatar memory avatar = soulProfile.getDappAvatar(owner, dappName);
    return avatar.avatarURI;  // Already has privacy check
}
```

## Privacy Patterns

### Public Identity
```solidity
// Set public default avatar
profile.setDefaultAvatar("ipfs://public-avatar...");

// Set public dApp avatars
profile.setDappAvatar("GameA", "ipfs://game-avatar...", true);
profile.setDappAvatar("GameB", "ipfs://other-avatar...", true);
```

Result: Your identity is discoverable everywhere

### Tiered Privacy
```solidity
// Public default avatar (everyone sees this)
profile.setDefaultAvatar("ipfs://professional-avatar...");

// Public game avatar (players see this)
profile.setDappAvatar("GameA", "ipfs://game-character...", true);

// Private app data (only you see this)
profile.setDappAvatar("PrivateApp", "ipfs://personal-data...", false);
```

Result: Different visibility for different contexts

### Fully Private
```solidity
// No default avatar set (no private option - defaults are public if set)
// Only private dApp avatars
profile.setDappAvatar("Secret1", "ipfs://...", false);
profile.setDappAvatar("Secret2", "ipfs://...", false);
```

Result: Minimal public footprint

## Frontend Privacy Handling

When building UIs:

```typescript
// Always respect privacy
const getAvatarForDisplay = async (userAddress: string, dappName: string) => {
    try {
        const avatar = await contract.getDappAvatar(userAddress, dappName);

        // Check if URI is empty (means private + you're not the owner)
        if (!avatar.avatarURI) {
            return defaultAvatar;
        }

        return avatar.avatarURI;
    } catch (error) {
        return defaultAvatar;
    }
};

// Only request public avatars for discovery
const discoverProfiles = async (userAddresses: string[]) => {
    const profiles = await Promise.all(
        userAddresses.map(addr =>
            contract.getDefaultAvatar(addr).catch(() => "")
        )
    );
    return profiles.filter(p => p !== "");
};
```

## Security Considerations

**Private Avatars Don't Hide Ownership**
- Smart contracts can still call `getDappAvatar()` and see the raw data
- Only non-owner external calls get empty URIs
- On-chain, privacy is about access control, not encryption

**Events Reveal Activity**
- Setting a private avatar still emits events
- Observers know you have a private avatar even if they can't read it
- Consider this before setting sensitive data

**Visibility is Immutable Per Avatar**
- Once you set an avatar as private, it stays private
- You must remove and recreate to change visibility
- Plan your privacy strategy upfront
