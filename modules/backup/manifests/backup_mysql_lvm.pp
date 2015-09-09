# Class: backup_mysql_lvm
#
#
class backup::backup_mysql_lvm inherits backup{

  file { "${backup_dir}/backup_mysql_lvm.sh" :
    mode => 755,
    source => "puppet:///modules/${module_name}/backup_mysql_lvm.sh",
    replace => false,
    require => File["$backup_dir"];
  }

  cron { "backup_mysql_lvm" :
    command => "${backup_dir}/backup_mysql_lvm.sh >/dev/null",
    require => File["${backup_dir}/backup_mysql_lvm.sh"],
    user => 'root',
    hour => 4,
    minute => 1,
  }

}
