# Class: uwsgi
#
#
class uwsgi {
  package {
    "build-essential" : ensure => latest;
    "python-dev" : ensure => latest;
  }

  exec { "install_uwsgi":
    command => "/usr/bin/pip install uwsgi",
    refreshonly => true,
    require => package["build-essential","python-dev"];
  }

  file { "/etc/init.d/uwsgi":
    ensure => file,
    mode => 755,
    source => "puppet:///modules/${module_name}/uwsgi.sh";
  }

  file { "/etc/uwsgi":
    ensure => directory;
  }

  service { "uwsgi":
    ensure     => running,
    hasrestart => true,
    enable     => true,
    require    => [File["/etc/init.d/uwsgi"], File["/etc/uwsgi"], Exec["install_uwsgi"]];
  }
}