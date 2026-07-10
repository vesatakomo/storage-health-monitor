# Storage health monitor
Storage Health Monitor is a lightweight monitoring utility for Linux storage servers.

Designed for:

- HP Smart Array
- SATA SMART
- SnapRAID
- MergerFS

Features

✓ Detects SMART changes
✓ Detects RAID degradation
✓ Detects added/removed/replaced disks
✓ State-based notifications
✓ Zero dependencies except smartctl and ssacli

Storage Health Monitor does not try to replace Zabbix, Prometheus or Grafana.
Its only purpose is to detect changes in storage health and notify the administrator when attention is required.

Originally developed while migrating a home backup server from OpenMediaVault to Debian.
The project evolved from two small monitoring scripts into a modular storage health monitor through iterative design and testing on real hardware.

# Philosophy
✓ Lightweight
✓ Human-readable
✓ State-based monitoring
✓ No unnecessary dependencies
✓ Modular hardware backends
✓ Quiet by default
✓ Easy to extend
