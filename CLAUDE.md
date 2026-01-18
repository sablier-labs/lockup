# Sablier EVM Monorepo

Smart contracts for Sablier token streaming protocols.

## Tech Stack

- **Language**: Solidity 0.8.29
- **Framework**: Foundry
- **Package Manager**: Bun
- **Task Runner**: Just
- **Testing**: Foundry with Bulloak (BTT)
- **Linting**: Solhint, Prettier

## Monorepo Structure

```
├── lockup/     # Fixed-term vesting and airdrops
├── flow/       # Open-ended token streaming
├── airdrops/   # Merkle-based token distribution
└── utils/      # Shared utilities and comptroller
```

Each package has its own `CLAUDE.md` with protocol-specific context.

## Commands

```bash
just setup              # One-time setup (install deps, create .env symlinks)
just build-all          # Build all packages
just test-all           # Run all tests
just full-check-all     # Run all linting and checks
just full-write-all     # Auto-fix linting issues
```

Package-specific commands use `just <command> <package>`:

```bash
just build lockup       # Build lockup package
just test flow          # Test flow package
just coverage airdrops  # Coverage for airdrops
just full-check utils   # Run all checks on utils
```

## Code Standards

- Line length: 120 characters
- Use NatSpec for all public/external functions
- Follow existing patterns in each package
- Tests use Branching Tree Technique (BTT) with `.tree` files

## Development Workflow

1. Base branch for PRs: `staging`
2. Run `just full-check <package>` before committing
3. Generate BTT tests: `bulloak scaffold -wf path/to/file.tree`

## Security

All protocols are audited. See [SECURITY.md](./SECURITY.md) for bug bounty details.
