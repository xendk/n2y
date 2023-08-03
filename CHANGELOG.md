# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project loosely adheres to [Semantic
Versioning](http://semver.org/spec/v2.0.0.html) (patch releases are
bug fixes, minor releases new features, major relases significant
changes).

## 1.2.1 - Unreleased
### Added
- CHANGELOG.md file 

## 1.2.0 - 2023-08-02
### Added
- Taskfile.dist.yml for test and build commands.

### Removed
- Remove sqlite dependency.

## 1.1.0 - 2023-08-01
### Added
- Show N2y version in footer.

### Changed
- Store users in yaml files instead of database and migrate existing
  users.
- Store logs in files rather than database.

### Fixed
- Make Habitat check for missing configuration and error out.
- Trim leading/trailing white-space from email, just in case.
- Fix version in shard.yml and make VERSION constant use it.

## 1.0.1 - 2023-07-24
### Fixed
- Catch and log errors in auth rather than failing.

## 1.0.0 - 2023-07-24
### Added
- Initial release.