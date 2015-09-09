# Class: base_config::auto_upgrade
#
#
class base_config::auto_upgrade {
  package { "cron-apt": ensure => latest ; }

  $file_content = "autoclean -y
dist-upgrade -y -o APT::Get::Show-Upgraded=true"

  file {"/etc/cron-apt/action.d/3-download":
    require => Package['cron-apt'],
    content => $file_content,
  }

}