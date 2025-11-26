import { defineConfig } from 'vitepress'
import { fileURLToPath } from 'node:url'

export default defineConfig({
  title: 'ERC-7866',
  description: 'Gravatar for Web3 - ERC-7866 Standard for Decentralised User Profiles',
  lang: 'en-US',

  head: [
    ['link', { rel: 'icon', href: '/favicon.svg' }],
    ['meta', { name: 'theme-color', content: '#6366f1' }],
  ],

  themeConfig: {
    logo: '/favicon.svg',
    siteTitle: 'ERC-7866',

    nav: [
      { text: 'Home', link: '/' },
      { text: 'Docs', link: '/quickstart' },
      { text: 'GitHub', link: 'https://github.com/anistark/erc7866' },
      { text: 'EIP-7866', link: 'https://eips.ethereum.org/EIPS/eip-7866' },
    ],

    sidebar: [
      {
        text: 'Getting Started',
        items: [
          { text: 'Overview', link: '/' },
          { text: 'Quick Start', link: '/quickstart' },
          { text: 'Features', link: '/features' },
        ],
      },
      {
        text: 'Core Concepts',
        items: [
          { text: 'Profiles', link: '/concepts/profiles' },
          { text: 'Privacy', link: '/concepts/privacy' },
          { text: 'Multi-Chain', link: '/concepts/multi-chain' },
        ],
      },
      {
        text: 'Implementation',
        items: [
          { text: 'Implementation Guide', link: '/implementation/guide' },
          { text: 'Integration', link: '/implementation/integration' },
          { text: 'Gas Costs', link: '/implementation/gas' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'Specification', link: '/reference/specification' },
          { text: 'Contracts', link: '/reference/contracts' },
          { text: 'Security', link: '/reference/security' },
        ],
      },
    ],

    socialLinks: [
      { icon: 'github', link: 'https://github.com/anistark/erc7866' },
    ],

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025 Kumar Anirudha',
    },

    editLink: {
      pattern: 'https://github.com/anistark/erc7866/edit/main/docs/:path',
      text: 'Edit this page on GitHub',
    },
  },
})
