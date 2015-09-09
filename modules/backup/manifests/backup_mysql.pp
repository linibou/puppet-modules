# Class: backup_mysql
#
#
class backup::backup_mysql inherits backup{
  file { "${backup_dir}/backup_mysql.sh" :
    mode => 755,
    source => "puppet:///modules/${module_name}/backup_mysql.sh",
    replace => false,
    require => File["$backup_dir"];
  }

  cron { "backup_mysql" :
    command => "${backup_dir}/backup_mysql.sh all >/dev/null",
    require => File["${backup_dir}/backup_mysql.sh"],
    user => 'root',
    hour => 4,
    minute => 1,
  }
}
