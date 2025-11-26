// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC7866.sol";

contract SoulProfileResolver {
    IERC7866 public soulProfile;

    struct ResolverConfig {
        address resolver;
        bool enabled;
    }

    mapping(string => ResolverConfig) private dappResolvers;

    event DappResolverRegistered(string indexed dappName, address indexed resolver);
    event DappResolverDisabled(string indexed dappName);

    constructor(address _soulProfileAddress) {
        require(_soulProfileAddress != address(0), "Invalid soul profile address");
        soulProfile = IERC7866(_soulProfileAddress);
    }

    function registerDappResolver(string memory dappName, address resolver) external {
        require(resolver != address(0), "Invalid resolver address");
        require(bytes(dappName).length > 0, "Invalid dapp name");

        dappResolvers[dappName] = ResolverConfig({resolver: resolver, enabled: true});
        emit DappResolverRegistered(dappName, resolver);
    }

    function disableDappResolver(string memory dappName) external {
        dappResolvers[dappName].enabled = false;
        emit DappResolverDisabled(dappName);
    }

    function resolveDappAvatar(address owner, string memory dappName)
        external
        view
        returns (string memory)
    {
        IERC7866.DappAvatar memory avatar = soulProfile.getDappAvatar(owner, dappName);

        if (!avatar.isPublic && msg.sender != owner) {
            return "";
        }

        return avatar.avatarURI;
    }

    function resolveDappAvatarPublic(address owner, string memory dappName)
        external
        view
        returns (string memory)
    {
        IERC7866.DappAvatar memory avatar = soulProfile.getDappAvatar(owner, dappName);

        if (!avatar.isPublic) {
            return "";
        }

        return avatar.avatarURI;
    }

    function resolveUsername(address owner) external view returns (string memory) {
        if (!soulProfile.hasProfile(owner)) {
            return "";
        }

        IERC7866.Profile memory profile = soulProfile.getProfile(owner);
        return profile.username;
    }

    function resolveProfileURI(address owner) external view returns (string memory) {
        if (!soulProfile.hasProfile(owner)) {
            return "";
        }

        IERC7866.Profile memory profile = soulProfile.getProfile(owner);
        return profile.defaultAvatarURI;
    }

    function getDappResolver(string memory dappName)
        external
        view
        returns (address, bool)
    {
        ResolverConfig memory config = dappResolvers[dappName];
        return (config.resolver, config.enabled);
    }
}
