# Storage Health Monitor
# When everything is healthy, SHM has nothing to say.

Lightweight storage health monitoring for Linux servers using HP Smart Array, SAS, and SATA disks.

Storage Health Monitor (SHM) continuously checks storage subsystems and reports only changes that require administrator attention.

It doesn't monitor everything.
It monitors the things that matter.

Vendor tools tell you everything.
SHM tells you what matters.

**Non-goals**

Not a monitoring system
Not a dashboard
Not a SMART replacement
Not a RAID management tool

Its only purpose is to detect changes in storage health and notify the administrator when action is needed.

**Designed for:**

- HP Smart Array
- SATA SMART

**Features**

✓ Detects SMART changes
✓ Detects RAID degradation
✓ Detects added/removed/replaced disks
✓ State-based notifications
✓ Minimal dependencies except smartctl and ssacli

Originally developed while migrating a home backup server from OpenMediaVault to Debian.
The project evolved from two small monitoring scripts into a modular storage health monitor through iterative design and testing on real hardware.

### Requirements

- Linux
- Bash
- smartctl (only required when SMART_ENABLED=yes)
- ssacli (only required when HP_RAID_ENABLED=yes)

## Installation

Clone the repository:

    git clone https://github.com/vesatakomo/storage-health-monitor.git
    cd storage_health

Run directly from the repository, or place `storage_health` somewhere in your PATH.

## Configuration
(Beginning of storage_health)
| Name                 | Type    | Default      | Description                                                                                            |
| -------------------- | ------- | ------------ | ------------------------------------------------------------------------------------------------------ |
| HP_RAID_ENABLED      | yes/no  | yes          | yes = uses ssacli to get data from HP Raid array disks. no = skip HP Raid array, no ssacli needed      |
| SMART_ENABLED        | yes/no  | yes          | yes = uses smartctl to get data from SATA disks. no = skip SMART data from SATA disks, no smartctl needed |
| NOTIFY_METHOD        | value   | none         | none = no external notifications, apprise = send through apprise, telegram = send directly through Telegram Bot API|
| APPRISE_URL          | url     |              | URL for you apprise|
| TELEGRAM_BOT_TOKEN   | value   |              | Your token for Telegram Bot|
| TELEGRAM_CHAT_ID     | value   |              | ID for chat you wish to receive notifications|

## Usage
|Run|Description|
| --- | ----------|
|`storage_health`|Normal output. Reports only Healthy when there are no changes or problems. Details when something has changed|
|`storage_health --full`|Shows detailed health information and important attributes.|
|`storage_health --inventory`|Lists all the disks in system with Model, Size, Type and Serial|
|`storage_health --help`|Self explanatory|
|`storage_health --version`|Version info|

**Example notification**
```_
Storage Health Monitor

! SAS BAY 2
Write corrected: 87971 -> 87972
```

= SHM reports the change; other healthy disks remain silent.

# Philosophy

- Silence is good.
- Report changes, not statistics.
- Every finding should be actionable.
- Never guess.
- Reliability over features.
- Simple is maintainable.
