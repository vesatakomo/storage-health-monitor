## v0.9 (development)

### Added
- Disk inventory logic
- Disk inventory switch --inventory

## v0.8 (development)

### Added
- Provider selection
- Exclusion of provider with "no"

## v0.7 (development)

### Added
- Notifications. Apprise & Telegram support
  
## v0.6 (development)

### Added
- StateDB + change engine
  
## v0.5 (development)

### Added
- SAS disk S.M.A.R.T reading
  
## v0.4 (development)

### Added
- SATA S.M.A.R.T reading
- Visual presentation of values
- --full switch functionality
  
## v0.3 (development)

### Added
- Modular project layout
- Shared results API
- Report engine
- Framework for SATA SMART

### Changed
- Replaced global status variables with a unified results model.

## Refactor findings engine

- Preserve finding insertion order
- Add grouped findings display
- Introduce print_group() helper
- Introduce print_finding() helper
- Separate collection from presentation
