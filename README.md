# rkhunter_maths

Rootkit Hunter (rkhunter) installation and configuration.

## Usage

    class { 'rkhunter_maths':
      db_update_email      => true,
      allowed_hidden_dirs  => ['/etc/.java'],
      allowed_hidden_files => ['/etc/.updated'],
    }

## Behaviour worth knowing

- `allowed_hidden_dirs`/`allowed_hidden_files` are written to a
  Puppet-owned drop-in file, `/etc/rkhunter.d/maths-allowlist.conf`,
  rather than appended line-by-line into the shared `/etc/rkhunter.conf`.
  This means removing an entry from either array actually removes its
  effect on the next run — the drop-in file's content always matches
  the arrays exactly, rather than accumulating stale entries.
- The integrity baseline (`rkhunter --propupdate`) is only ever run
  once, to establish the initial baseline — it is deliberately **not**
  re-triggered by ordinary configuration changes (e.g. changing
  `db_update_email`). Accepting a new baseline after that point is a
  separate, deliberate action outside this module's scope, not
  something a config tweak should do as a side effect.

## Requirements

Assumes a working local mail delivery setup (`/etc/aliases` resolving
`root` to a real recipient) already exists on the target node — this
module does not install or configure a mail transfer agent.

## Worth reviewing for your environment

`/etc/default/rkhunter` sets `APT_AUTOGEN="true"`, which triggers
rkhunter's own baseline regeneration automatically after `apt`
package changes (a Debian/Ubuntu-specific mechanism, separate from
the `rkhunter_propupdate` exec above). Worth a deliberate decision on
whether that matches your intended detection policy — automatic
baseline updates after every package change reduce false positives
from routine upgrades, but also mean a compromise timed to coincide
with a package update could get baselined in.
