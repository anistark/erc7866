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

    event ProfileCreated(address indexed owner, string username);
    event DefaultAvatarUpdated(address indexed owner, string avatarURI);
    event DappAvatarSet(address indexed owner, string dappName, string avatarURI, bool isPublic);
    event DappAvatarRemoved(address indexed owner, string dappName);

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
