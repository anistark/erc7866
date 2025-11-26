// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC7866.sol";

contract SoulProfile is IERC7866 {
    mapping(address => Profile) private profiles;
    mapping(address => mapping(string => DappAvatar)) private dappAvatars;
    mapping(string => address) private usernameToAddress;
    mapping(address => bool) private _hasProfile;

    modifier onlyProfileOwner(address account) {
        require(_hasProfile[account], "Profile does not exist");
        require(msg.sender == account, "Only profile owner can perform this action");
        _;
    }

    modifier validUsername(string memory username) {
        bytes memory usernameBytes = bytes(username);
        require(usernameBytes.length > 0 && usernameBytes.length <= 32, "Invalid username length");
        _;
    }

    function createProfile(string memory username, string memory defaultAvatarURI)
        external
        validUsername(username)
    {
        require(!_hasProfile[msg.sender], "Profile already exists");
        require(usernameToAddress[username] == address(0), "Username already taken");

        profiles[msg.sender] = Profile({
            username: username,
            defaultAvatarURI: defaultAvatarURI,
            bio: "",
            website: ""
        });

        usernameToAddress[username] = msg.sender;
        _hasProfile[msg.sender] = true;

        emit ProfileCreated(msg.sender, username);
    }

    function setDefaultAvatar(string memory avatarURI)
        external
        onlyProfileOwner(msg.sender)
    {
        profiles[msg.sender].defaultAvatarURI = avatarURI;
        emit DefaultAvatarUpdated(msg.sender, avatarURI);
    }

    function setDappAvatar(string memory dappName, string memory avatarURI, bool isPublic)
        external
        onlyProfileOwner(msg.sender)
    {
        require(bytes(dappName).length > 0, "Invalid dapp name");
        dappAvatars[msg.sender][dappName] = DappAvatar({
            dappName: dappName,
            avatarURI: avatarURI,
            isPublic: isPublic
        });
        emit DappAvatarSet(msg.sender, dappName, avatarURI, isPublic);
    }

    function removeDappAvatar(string memory dappName)
        external
        onlyProfileOwner(msg.sender)
    {
        delete dappAvatars[msg.sender][dappName];
        emit DappAvatarRemoved(msg.sender, dappName);
    }

    function getProfile(address owner) external view returns (Profile memory) {
        require(_hasProfile[owner], "Profile does not exist");
        return profiles[owner];
    }

    function getDefaultAvatar(address owner) external view returns (string memory) {
        require(_hasProfile[owner], "Profile does not exist");
        return profiles[owner].defaultAvatarURI;
    }

    function getDappAvatar(address owner, string memory dappName)
        external
        view
        returns (DappAvatar memory)
    {
        require(_hasProfile[owner], "Profile does not exist");
        DappAvatar memory avatar = dappAvatars[owner][dappName];

        if (!avatar.isPublic && msg.sender != owner) {
            return DappAvatar({dappName: dappName, avatarURI: "", isPublic: false});
        }

        return avatar;
    }

    function getProfileByUsername(string memory username) external view returns (address) {
        return usernameToAddress[username];
    }

    function hasProfile(address owner) external view returns (bool) {
        return _hasProfile[owner];
    }
}
