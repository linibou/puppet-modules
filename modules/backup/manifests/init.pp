# Class: backup
#
#
class backup {
  $backup_dir = "${scripts_dir}/backup"
  File { ensure => file, owner => 'root', group => 'root', mode => 644 }
  file { "$backup_dir" : ensure => directory; }
}
