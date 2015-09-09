# Class: base_config::auto_update
#
#
class base_config::auto_update {
  package { "cron-apt": ensure => latest ; }

  $file_content = "$cron_mailto
MAILON='upgrade'"

  file {"/etc/cron-apt/config":
    require => Package['cron-apt'],
    content => $file_content,
  }

}