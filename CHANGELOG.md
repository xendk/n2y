# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project loosely adheres to [Semantic
Versioning](http://semver.org/spec/v2.0.0.html) (patch releases are
bug fixes, minor releases new features, major releases significant
changes).

## 1.5.1 - Unreleased
### Changed
- Try to identify EUA expired errors, so we can handle them
  specifically at some point.
  
### Fixed
- Skip unknown accounts, but carry on syncing.
- Catch 409 when fetching accounts. Seems that deleted accounts can
  still show up on the requisition, but return error when fetched.
- Catch EUA expired errors and disable automatic sync.

## 1.5.0 - 2023-10-02
### Added
- Periodical, hands-free syncing of transactions.

## 1.4.0 - 2023-09-20
### Added
- Caching accounts information.
- Handle bank connection errors.

### Changed
- Use `Bank` and `Budget` abstractions to simplify main app logic.

## 1.3.0 - 2023-08-09
### Added
- CHANGELOG.md file.
- `build` and `release` targets to taskfile.

### Changed
- Let the session live longer, but require login at least once a week.
  Closes #4.
- Make release building even more automated.

### Removed
- Old test code and shard targets.

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
  users. Closes #3.
- Store logs in files rather than database. Closes #3.

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
