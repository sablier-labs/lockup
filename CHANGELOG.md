# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Common Changelog](https://common-changelog.org/).

[1.1.0]: https://github.com/sablier-labs/v2-core/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/sablier-labs/v2-core/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/sablier-labs/v2-core/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/sablier-labs/v2-core/releases/tag/v1.0.0

## [1.1.0] - 2023-09-27

### Changed

- Move `isWarm` and `isCold` to `SablierV2Lockup` ([#664](https://github.com/sablier-labs/v2-core/pull/664))
- Remove `@openzeppelin/contracts` from Node.js peer dependencies
  ([#693](https://github.com/sablier-labs/v2-core/pull/693))
- Replace the streamed amount with the deposit amount in the NFT descriptor
  ([#692](https://github.com/sablier-labs/v2-core/pull/692))
- Simplify `renounce` and `withdraw` implementations ([#683](https://github.com/sablier-labs/v2-core/pull/683))
- Upgrade Solidity to `0.8.21` ([#688](https://github.com/sablier-labs/v2-core/pull/688))

### Added

- Add `ERC-4906` metadata update in `transferFrom` ([#686](hhttps://github.com/sablier-labs/v2-core/pull/686))
- Add `transferrable` boolean flag ([#668](https://github.com/sablier-labs/v2-core/pull/668))

## [1.0.2] - 2023-08-14

### Changed

- Update `@prb/math` import paths to contain `src/` ([#648](https://github.com/sablier-labs/v2-core/pull/648))

## [1.0.1] - 2023-07-13

### Changed

- Optimize use of variables in `tokenURI` ([#617](https://github.com/sablier-labs/v2-core/pull/617))

### Fixed

- Fix data URI scheme in `tokenURI` ([#617](https://github.com/sablier-labs/v2-core/pull/617))

## [1.0.0] - 2023-07-07

### Added

- Initial release
