# Class: backup_system
#
#
class backup::backup_system inherits backup{
  file { "${backup_dir}/backup_syst.sh" :
    mode => 755,
    source => "puppet:///modules/${module_name}/backup_syst.sh",
    replace => false,
    require => File["$backup_dir"];
  }

  cron { "backup_system" :
    command => "${backup_dir}/backup_syst.sh",
    require => File["${backup_dir}/backup_syst.sh"],
    user => 'root',
    hour => 3,
    minute => 1,
    weekday => Sunday;
  }
}
