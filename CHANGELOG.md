# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Intended Effort Versioning](https://jacobtomlinson.dev/effver/).

## 1.7.1 - Unreleased

### Fixed
- Assume HTTPS in production. We're running a reverse proxy that
  ensures HTTPS.

## 1.7.0 - 2026-01-04

### Changed
- Update readme and privacy-policy to reflect that we switched to
  Honeybadger.
- Ignore deleted YNAB accounts.

### Fixed
- In the background task runner, sleep for five minutes per run,
  rather after spawning each user process. Avoids busy-loop if there's
  no users.

## 1.6.3 - 2025-07-30

### Fixed
- Specs, a bit embarrassing that they must have been broken since
  1.6.0.
- Handle bots hitting /auth/callback without the code argument, so
  they don't end up in Honeybadger.

## 1.6.2 - 2025-03-29
### Chonged
- Use the logging system when capturing messages for manual runs
  rather than have the worker duplicate the messages.

### Fixed
- Handling EUA expired and rate limit errors so they don't show up in
  Honeybadger.

## 1.6.1 - 2025-01-24
### Fixed
- Don't retry every five minutes when hitting rate limit, but postpone
  to next scheduled run.
- Use BigDecimal for amount calculation. Floating point errors is
  possible even in the simple "multiply decimal amount from bank with
  1000" calculation we do.

## 1.6.0 - 2024-08-20
### Changed
- Limit sync interval to minimum 6 hours. Nordigen will be rate
  limiting to 4 request per account every 24 hours soon.

### Added
- Log user being affected in Honeybadger errors.

## 1.5.2 - 2024-08-09
### Changed
- Also log message body on YNAB token refresh errors.
- Send exceptions to Honeybadger instead of Sentry.

## 1.5.1 - 2024-03-23
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
