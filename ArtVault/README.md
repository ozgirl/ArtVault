# ArtVault 🎨

**A Decentralized Digital Art Gallery Platform on Stacks**

ArtVault is a blockchain-powered platform that enables digital artists to exhibit their creations, connect with collectors, and monetize their art through direct commissions. Built on the Stacks blockchain using Clarity smart contracts, ArtVault creates a transparent, decentralized ecosystem for the digital art community.

## Features

### 🎯 For Artists
- **Artist Registration**: Create detailed profiles with biography and artistic identity
- **Art Exhibition**: Showcase digital art pieces with rich descriptions
- **Reputation System**: Build reputation through community engagement and commissions
- **Direct Monetization**: Receive commissions directly from collectors
- **Community Building**: Gain collectors and build your artistic network

### 🏛️ For Collectors
- **Art Discovery**: Browse and discover new digital art pieces
- **Artist Subscriptions**: Follow favorite artists to stay updated
- **Art Favorites**: Curate personal collections of favorite pieces
- **Direct Commissioning**: Support artists through direct STX payments
- **Community Engagement**: Build connections within the art community

### 📊 Platform Features
- **Decentralized Governance**: No central authority controls the gallery
- **Transparent Metrics**: All transactions and interactions recorded on-chain
- **Reputation Scoring**: Algorithm-based artist reputation calculation
- **Commission Tracking**: Complete history of artist support and earnings

## Smart Contract Overview

### Core Data Structures

**Artist Profiles**
- Artist name and biography
- Reputation score and verification status
- Portfolio statistics (pieces, collectors, subscriptions)
- Registration timestamp

**Gallery Pieces**
- Creator information and art description
- Community engagement metrics (favorites, views)
- Commission totals and exhibition date
- Featured/highlighted status

**Artist Connections**
- Collector-to-artist subscription relationships
- Subscription timestamps for analytics

**Metrics & Analytics**
- Commission history (received and paid)
- Wallet balance tracking
- Platform membership duration
- Comprehensive artist performance data

### Key Functions

#### Artist Functions
- `register-artist`: Join the ArtVault platform
- `exhibit-piece`: Display new art pieces in the gallery
- `subscribe-to-artist`: Follow other artists for updates

#### Collector Functions
- `favorite-piece`: Mark art pieces as favorites
- `commission-piece`: Send STX payments to support artists

#### Read-Only Functions
- `get-artist-profile`: Retrieve artist information
- `get-piece`: Fetch art piece details
- `get-artist-metrics`: Access artist performance data
- `is-subscribed`: Check subscription status
- `has-favorited-piece`: Verify favorite status

## Getting Started

### Prerequisites
- Stacks wallet (Leather, Xverse, or similar)
- STX tokens for transactions and commissions
- Understanding of Clarity smart contracts

### Artist Registration
1. Call `register-artist` with your artist name and biography
2. Your profile will be created with initial metrics
3. Start exhibiting art pieces to build reputation

### Exhibiting Art
1. Use `exhibit-piece` with detailed art description
2. Your piece gets a unique ID and is added to the gallery
3. Collectors can now favorite and commission your work

### Supporting Artists
1. Browse gallery pieces using `get-piece`
2. Favorite interesting pieces with `favorite-piece`
3. Commission artists directly using `commission-piece`

## Contract Architecture

The smart contract uses several interconnected data maps:

- **artist-profiles**: Core artist information and statistics
- **gallery-pieces**: Individual art piece data and metrics
- **artist-connections**: Subscription relationships
- **piece-favorites**: User favorites tracking
- **piece-commissions**: Commission payment records
- **artist-metrics**: Comprehensive analytics and performance data

## Reputation System

Artist reputation is calculated based on:
- Number of exhibited pieces (×10 points each)
- Collector count (×5 points each)
- Total commissions received (1 point per STX)
- STX wallet balance contribution
- Platform membership duration bonus

## Security & Error Handling

The contract includes comprehensive error handling:
- `err-owner-only`: Owner-restricted functions
- `err-not-found`: Missing data validation
- `err-unauthorized`: Permission checks
- `err-invalid-input`: Input validation
- `err-already-exists`: Duplicate prevention
