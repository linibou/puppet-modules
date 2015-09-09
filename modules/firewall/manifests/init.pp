class firewall {

  $fw_dir = "${scripts_dir}/firewall"

  package { 'iptables': ensure => latest }

  File { ensure => file, owner => 'root', group => 'root', mode => 644 }

  file{ [$fw_dir, "${fw_dir}/rules"]:
      ensure => directory,
      force => true,
      recurse => true,
      purge => true,
      mode => 700;
    "${fw_dir}/firewall.sh":
      mode => 755,
      source => "puppet:///modules/${module_name}/firewall.sh",
      replace => false;
    "/etc/init.d/firewall":
      ensure => 'link',
      target => "${fw_dir}/firewall.sh";
  }

  # Service
  service { 'firewall':
    ensure     => running,
    hasstatus  => false,
    enable     => true,
    require    => [File["${fw_dir}/firewall.sh"], File[$fw_dir], File["${fw_dir}/rules"], File['/etc/init.d/firewall']]
  }

  define addrule() {
    $rule = $title
    $rulehash = md5($rule)

    file { "${firewall::fw_dir}/rules/${rulehash}":
      mode => 600,
      content => "$rule\n",
      notify => Service["firewall"]
    }
  }
}

