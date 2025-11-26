# Integration Example

Complete example of integrating ERC-7866 into a dApp.

## Gaming Example: Character Profiles

A game that uses ERC-7866 for player identities.

### Setup

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC7866 } from "../interfaces/IERC7866.sol";

contract RPGGame {
    IERC7866 public soulProfiles;

    struct GameCharacter {
        address owner;
        string class;
        uint256 level;
        uint256 experience;
    }

    mapping(address => GameCharacter) public characters;

    event CharacterCreated(address indexed player, string class);
    event CharacterLeveledUp(address indexed player, uint256 newLevel);

    constructor(address _soulProfileAddress) {
        soulProfiles = IERC7866(_soulProfileAddress);
    }

    // Game-specific functions...
}
```

### Display Player Profile

```solidity
function getPlayerInfo(address player)
    external
    view
    returns (
        string memory username,
        string memory displayName,
        string memory avatar,
        string memory characterClass,
        uint256 level
    )
{
    // Default values
    username = "Anonymous";
    avatar = "";
    displayName = "Player";

    // Fetch from ERC-7866 if profile exists
    if (soulProfiles.hasProfile(player)) {
        IERC7866.Profile memory profile = soulProfiles.getProfile(player);
        username = profile.username;

        // Try to get game-specific avatar
        IERC7866.DappAvatar memory gameAvatar = soulProfiles.getDappAvatar(
            player,
            "RPGGame"
        );

        if (bytes(gameAvatar.avatarURI).length > 0) {
            avatar = gameAvatar.avatarURI;
        } else if (bytes(profile.defaultAvatarURI).length > 0) {
            avatar = profile.defaultAvatarURI;
        }

        displayName = username;
    }

    GameCharacter memory character = characters[player];

    return (
        username,
        displayName,
        avatar,
        character.class,
        character.level
    );
}
```

### Create Game Character

```solidity
function createCharacter(string memory characterClass) external {
    require(characters[msg.sender].owner == address(0), "Character already exists");
    require(
        keccak256(abi.encodePacked(characterClass)) == keccak256(abi.encodePacked("Warrior"))
            || keccak256(abi.encodePacked(characterClass)) == keccak256(abi.encodePacked("Mage"))
            || keccak256(abi.encodePacked(characterClass)) == keccak256(abi.encodePacked("Rogue")),
        "Invalid class"
    );

    characters[msg.sender] = GameCharacter({
        owner: msg.sender,
        class: characterClass,
        level: 1,
        experience: 0
    });

    emit CharacterCreated(msg.sender, characterClass);
}
```

### Leaderboard with Profiles

```solidity
function getLeaderboard(uint256 limit)
    external
    view
    returns (
        address[] memory players,
        string[] memory usernames,
        uint256[] memory levels,
        string[] memory avatars
    )
{
    // In a real implementation, you'd maintain a proper leaderboard
    // This is a simplified version

    players = new address[](limit);
    usernames = new string[](limit);
    levels = new uint256[](limit);
    avatars = new string[](limit);

    // Fetch top players by level
    // For brevity, showing the structure only

    return (players, usernames, levels, avatars);
}
```

## Frontend Integration

### TypeScript/Web3.js Example

```typescript
import { ethers } from "ethers";

interface PlayerProfile {
    address: string;
    username: string;
    avatar: string;
    class: string;
    level: number;
}

class GameIntegration {
    private game: ethers.Contract;
    private soulProfiles: ethers.Contract;
    private provider: ethers.Provider;

    constructor(
        gameAddress: string,
        soulProfileAddress: string,
        rpc: string
    ) {
        this.provider = new ethers.JsonRpcProvider(rpc);
        this.game = new ethers.Contract(gameAddress, GAME_ABI, this.provider);
        this.soulProfiles = new ethers.Contract(
            soulProfileAddress,
            ERC7866_ABI,
            this.provider
        );
    }

    async getPlayerProfile(playerAddress: string): Promise<PlayerProfile> {
        const [info] = await this.game.getPlayerInfo(playerAddress);

        return {
            address: playerAddress,
            username: info.username,
            avatar: info.avatar,
            class: info.characterClass,
            level: Number(info.level)
        };
    }

    async createCharacter(characterClass: string): Promise<void> {
        const signer = this.provider.getSigner();
        const gameWithSigner = this.game.connect(signer);

        const tx = await gameWithSigner.createCharacter(characterClass);
        await tx.wait();
    }

    async getLeaderboard(limit: number = 10): Promise<PlayerProfile[]> {
        const [players, usernames, levels, avatars] = await this.game.getLeaderboard(limit);

        return players.map((player: string, i: number) => ({
            address: player,
            username: usernames[i],
            avatar: avatars[i],
            class: "",
            level: Number(levels[i])
        }));
    }

    async listenToProfileChanges(playerAddress: string): Promise<void> {
        this.soulProfiles.on(
            "DefaultAvatarUpdated",
            (owner: string, avatarURI: string) => {
                if (owner.toLowerCase() === playerAddress.toLowerCase()) {
                    console.log(`Player avatar updated to ${avatarURI}`);
                    // Refresh UI
                }
            }
        );
    }
}

// Usage
const integration = new GameIntegration(
    "0xGameAddress",
    "0xSoulProfileAddress",
    "https://rpc.example.com"
);

const profile = await integration.getPlayerProfile("0xPlayerAddress");
console.log(profile);

await integration.createCharacter("Warrior");

const leaderboard = await integration.getLeaderboard(10);
console.log(leaderboard);
```

### React Component Example

```tsx
import React, { useEffect, useState } from "react";
import { useContractRead } from "wagmi";

interface PlayerCardProps {
    playerAddress: `0x${string}`;
}

export function PlayerCard({ playerAddress }: PlayerCardProps) {
    const [profile, setProfile] = useState<PlayerProfile | null>(null);
    const [loading, setLoading] = useState(true);

    const { data: playerInfo } = useContractRead({
        address: GAME_ADDRESS,
        abi: GAME_ABI,
        functionName: "getPlayerInfo",
        args: [playerAddress],
        watch: true
    });

    useEffect(() => {
        if (playerInfo) {
            setProfile({
                address: playerAddress,
                username: playerInfo[0],
                avatar: playerInfo[2],
                class: playerInfo[3],
                level: Number(playerInfo[4])
            });
            setLoading(false);
        }
    }, [playerInfo]);

    if (loading) return <div>Loading...</div>;
    if (!profile) return <div>Profile not found</div>;

    return (
        <div className="player-card">
            <img
                src={profile.avatar || "/default-avatar.png"}
                alt={profile.username}
                className="player-avatar"
            />
            <h2>{profile.username}</h2>
            <p className="class">Class: {profile.class}</p>
            <p className="level">Level: {profile.level}</p>
            <a href={`/player/${profile.address}`}>View Profile</a>
        </div>
    );
}

export function Leaderboard() {
    const [players, setPlayers] = useState<PlayerProfile[]>([]);

    const { data: leaderboard } = useContractRead({
        address: GAME_ADDRESS,
        abi: GAME_ABI,
        functionName: "getLeaderboard",
        args: [10],
        watch: true
    });

    useEffect(() => {
        if (leaderboard) {
            const [addresses, usernames, levels, avatars] = leaderboard;
            const formatted = addresses.map((addr: string, i: number) => ({
                address: addr,
                username: usernames[i],
                avatar: avatars[i],
                level: Number(levels[i]),
                class: ""
            }));
            setPlayers(formatted);
        }
    }, [leaderboard]);

    return (
        <div className="leaderboard">
            <h1>Top Players</h1>
            <table>
                <thead>
                    <tr>
                        <th>Rank</th>
                        <th>Player</th>
                        <th>Level</th>
                        <th>Avatar</th>
                    </tr>
                </thead>
                <tbody>
                    {players.map((player, idx) => (
                        <tr key={player.address}>
                            <td>{idx + 1}</td>
                            <td>
                                <a href={`/player/${player.address}`}>
                                    {player.username}
                                </a>
                            </td>
                            <td>{player.level}</td>
                            <td>
                                <img src={player.avatar} alt={player.username} />
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
}
```

## Event Listening & Indexing

### Listen to Profile Updates

```typescript
const contract = new ethers.Contract(
    SOUL_PROFILE_ADDRESS,
    ERC7866_ABI,
    provider
);

// Listen for new profiles
contract.on("ProfileCreated", (owner, username) => {
    console.log(`New profile: ${username} by ${owner}`);

    // Update database
    db.profiles.upsert({
        address: owner,
        username: username,
        createdAt: new Date()
    });
});

// Listen for avatar updates
contract.on("DefaultAvatarUpdated", (owner, avatarURI) => {
    console.log(`${owner} updated avatar`);

    // Invalidate cache
    cache.invalidate(`avatar:${owner}`);
});

// Listen for dApp-specific avatars
contract.on(
    "DappAvatarSet",
    (owner, dappName, avatarURI, isPublic) => {
        console.log(
            `${owner} set ${dappName} avatar (public: ${isPublic})`
        );

        // Update game-specific avatar
        db.gameAvatars.upsert({
            owner,
            dappName,
            avatarURI,
            isPublic
        });
    }
);
```

### Build Player Index

```typescript
async function buildPlayerIndex() {
    const profiles = new Map<string, PlayerProfile>();

    const filter = contract.filters.ProfileCreated();
    const events = await contract.queryFilter(filter, 0, "latest");

    for (const event of events) {
        const [owner, username] = event.args;
        profiles.set(username, {
            address: owner,
            username: username,
            avatar: await contract.getDefaultAvatar(owner),
            class: "",
            level: 0
        });
    }

    return profiles;
}
```

## Error Handling

```solidity
function safeGetPlayerProfile(address player)
    external
    view
    returns (
        bool exists,
        string memory username,
        string memory avatar
    )
{
    try soulProfiles.getProfile(player) returns (
        IERC7866.Profile memory profile
    ) {
        return (
            true,
            profile.username,
            profile.defaultAvatarURI
        );
    } catch {
        return (false, "", "");
    }
}
```

## Production Checklist

- [ ] Test profile creation flow
- [ ] Test private avatar access control
- [ ] Verify fallback to default avatar works
- [ ] Test avatar updates don't break game
- [ ] Implement leaderboard caching
- [ ] Set up event indexing
- [ ] Handle non-existent profiles gracefully
- [ ] Validate avatar URIs (no malicious content)
- [ ] Test cross-chain deployments
- [ ] Benchmark gas costs
- [ ] Document for frontend team
