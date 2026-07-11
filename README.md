# Storage Health Monitor
# When everything is healthy, SHM has nothing to say.

Lightweight storage monitoring for Debian servers using HP Smart Array, SnapRAID and MergerFS.

It doesn't monitor everything.
It monitors the things that matter.

Storage Health Monitor (SHM) continuously checks storage subsystems and reports only changes that require administrator attention.
SHM is not a replacement for smartctl, ssacli, or vendor tools. It uses them to collect health information and transforms it into concise, actionable findings.
No dashboards. No dozens of SMART attributes. No information overload. Just storage health.

Storage Health Monitor (SHM) is a quiet storage monitoring utility for Linux. It continuously evaluates storage health and reports only meaningful changes that require administrator attention. If nothing has changed, SHM stays silent.

**Non-goals**

Not a monitoring system
Not a dashboard
Not a SMART replacement
Not a RAID management tool

Its only purpose is to detect changes in storage health and notify the administrator when action is needed.

**Designed for:**

- HP Smart Array
- SATA SMART
- SnapRAID
- MergerFS

**Features**

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
