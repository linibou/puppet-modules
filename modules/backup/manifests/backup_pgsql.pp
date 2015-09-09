# Class: backup_pgsql
#
#
class backup::backup_pgsql inherits backup{
  file { "${backup_dir}/backup_pgsql.sh" :
    mode => 755,
    source => "puppet:///modules/${module_name}/backup_pgsql.sh",
    replace => false,
    require => File["$backup_dir"];
  }

  cron { "backup_pgsql" :
    command => "${backup_dir}/backup_pgsql.sh all >/dev/null",
    require => File["${backup_dir}/backup_pgsql.sh"],
    user => 'root',
    hour => 4,
    minute => 1,
  }
}
