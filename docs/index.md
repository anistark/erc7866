---
title: "Overview"
---

# ERC-7866: Decentralised User Profiles

**Gravatar for Web3** — A production-ready standard for decentralized, interoperable user profiles on EVM blockchains.

Like Gravatar, but decentralized and on-chain: claim a soul-bound username, set avatars, and sync your identity across Web3 apps with full control and privacy.

<CardGroup cols={2}>
  <Card
    title="Implementation Guide"
    icon="book"
    href="/implementation/guide"
  >
    Complete guide with code examples and patterns
  </Card>
  <Card
    title="Specification"
    icon="scroll"
    href="/reference/specification"
  >
    Technical details and data structures
  </Card>
  <Card
    title="GitHub Repository"
    icon="github"
    href="https://github.com/anistark/erc7866"
  >
    Source code and contracts
  </Card>
  <Card
    title="EIP-7866"
    icon="file"
    href="https://eips.ethereum.org/EIPS/eip-7866"
  >
    Official Ethereum Improvement Proposal
  </Card>
</CardGroup>

## What is ERC-7866?

ERC-7866 defines a standard for decentralized user profiles implemented as Soul Bound Tokens (SBTs). These are non-transferable, immutable identity containers that enable interoperable user representation across multiple blockchain networks.

Just like you set a Gravatar once and use it everywhere on the web, ERC-7866 lets you:
- Claim a unique username tied to your address
- Set a global avatar used by default
- Create context-specific avatars for different dApps
- Control visibility of your profile data
- Maintain the same identity across chains and applications

## Key Features

- **Unique Identities** — Claim a human-readable username (`alice@eth.soul`) mapped to your address
- **Cross-dApp Avatars** — Set different avatars for different applications
- **Privacy Control** — Mark avatars as public or private with on-chain enforcement
- **Multi-Chain Ready** — Same identity format works across Ethereum, Polygon, Arbitrum, and other EVM chains
- **Off-Chain Efficient** — Metadata stored on IPFS/Arweave with minimal on-chain footprint
- **Event-Driven** — Full event logging for profile discovery and indexing

## Why ERC-7866?

**Problem**: Every Web3 dApp creates separate profiles. You have no unified identity.

**Solution**: ERC-7866 provides a standard profile layer that all dApps can integrate with:
- Users create once, reuse everywhere
- Full control over their identity
- Privacy and customization options
- Decentralized, no central authority

## Use Cases

- **User Identity** — Portable identity across Web3 apps
- **Gaming** — Game-specific character avatars while maintaining core identity
- **Professional Profiles** — Separate work and personal identities
- **Social Discovery** — Search users by username or avatar
- **Account Recovery** — Identity survives wallet loss

<Tip>
Ready to get started? Check out the <a href="/quickstart">Quick Start</a> guide.
</Tip>
