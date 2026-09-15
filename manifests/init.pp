# manifests/init.pp
class rkhunter_maths (
  Boolean       $db_update_email      = true,
  Array[String] $allowed_hidden_dirs  = ['/etc/.java'],
  Array[String] $allowed_hidden_files = ['/etc/.updated'],
) {
  package { 'rkhunter':
    ensure => installed,
  }

  file { '/etc/default/rkhunter':
    ensure  => file,
    content => "CRON_DAILY_RUN=\"true\"\nCRON_DB_UPDATE=\"true\"\nAPT_AUTOGEN=\"true\"\nDB_UPDATE_EMAIL=\"${db_update_email}\"\n",
    require => Package['rkhunter'],
    # Deliberately does NOT notify rkhunter_propupdate — accepting the
    # current file-property baseline is a distinct, deliberate action from
    # tweaking an unrelated setting like the alert email, and coupling the
    # two would let an ordinary config change silently rebuild the
    # integrity baseline over anything suspicious that changed since the
    # last real baseline update.
  }

  # Runs once, to establish the very first baseline on initial install.
  # Guarded on the properties database existing at all, not on config
  # file changes — see note above.
  exec { 'rkhunter_propupdate':
    command => '/usr/bin/rkhunter --propupdate',
    creates => '/var/lib/rkhunter/db/rkhunter.dat',
    require => Package['rkhunter'],
  }

  file_line { 'rkhunter_web_cmd':
    path    => '/etc/rkhunter.conf',
    line    => 'WEB_CMD=""',
    match   => '^#?WEB_CMD=',
    require => Package['rkhunter'],
  }

  file_line { 'rkhunter_update_mirrors':
    path    => '/etc/rkhunter.conf',
    line    => 'UPDATE_MIRRORS=1',
    match   => '^#?UPDATE_MIRRORS=',
    require => Package['rkhunter'],
  }

  file_line { 'rkhunter_mirrors_mode':
    path    => '/etc/rkhunter.conf',
    line    => 'MIRRORS_MODE=0',
    match   => '^#?MIRRORS_MODE=',
    require => Package['rkhunter'],
  }

  # ALLOWHIDDENDIR/ALLOWHIDDENFILE are repeatable directives, so managing
  # them as one file_line per array entry against the shared main config
  # meant removing an entry from the array never removed its effect —
  # the line just stopped being *managed*, it didn't get deleted. rkhunter
  # supports a drop-in directory (rkhunter.d/, alongside rkhunter.conf) for
  # exactly this kind of local addition, so this file is instead fully
  # owned by Puppet: whatever the arrays say right now is the file's
  # entire content, every run — true convergence, including on removal.
  file { '/etc/rkhunter.d':
    ensure  => directory,
    require => Package['rkhunter'],
  }

  file { '/etc/rkhunter.d/maths-allowlist.conf':
    ensure  => file,
    require => File['/etc/rkhunter.d'],
    content => epp('rkhunter_maths/allowlist.conf.epp', {
      'allowed_hidden_dirs'  => $allowed_hidden_dirs,
      'allowed_hidden_files' => $allowed_hidden_files,
    }),
  }
}
