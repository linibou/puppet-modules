class base_config {

    # base packages
    package {
        "htop": ensure => latest ;
        "mc": ensure => latest ;
        "emacs23-nox": ensure => latest ;
        "emacs-goodies-el": ensure => latest ;
        "tree": ensure => latest ;
        "fail2ban": ensure => latest ;
        "vim": ensure => latest ;
        "lftp": ensure => latest ;
        "dstat": ensure => latest ;
        "bzip2": ensure => latest ;
        "lvm2": ensure => latest ;
        "python-pip":  ensure => latest ;
        "rsync":  ensure => latest ;
        "openntpd":  ensure => purged ;
        "ntpdate": ensure => latest;
        "git": ensure => latest;
    }

    # base config
    File { ensure => file, owner => 'root', group => 'root', mode => 644 }

    file {
        "$scripts_dir":
            ensure => directory;
        "$root_config_dir":
            ensure => directory;
        "/etc/emacs/site-start.el":
            source => "puppet:///modules/${module_name}/site-start.el",
            require => Package['emacs23-nox'] ;
        "${root_config_dir}/htop":
            ensure => directory;
        "/root/.config/htop/htoprc":
            source => "puppet:///modules/${module_name}/htoprc";
        "/root/.ssh":
            ensure => directory,
            mode => 700 ;
        "/root/.ssh/authorized_keys":
            mode => 600 ;
        ["/etc/motd.tail","/var/run/motd", "/etc/motd"]:
            source => "puppet:///modules/${module_name}/motd";
    }

    exec { "colorex_install":
        command => "/usr/bin/pip install colorex",
        require => Package['python-pip'],
        refreshonly => true ;
    }

    cron { "ntpdate" :
        command => "/usr/sbin/ntpdate pool.ntp.org >/dev/null",
        require => Package["ntpdate"],
        user => 'root',
        hour => '*/1',
        minute => '0',
        environment => "$cron_mailto";
    }
}

define passwd ($password) {
        $user = $name

        if $user != 'root' {
            user { $user:
                ensure      => 'present',
                password    => $password,
                shell      => '/bin/bash',
                managehome => true,
            }
            file { "/home/${user}/.bashrc":
                source => "puppet:///modules/${module_name}/bashrc_user";
            }
        }else{
            user { $user:
                ensure      => 'present',
                password    => $password,
                shell      => '/bin/bash',
            }
            file { "/root/.bashrc":
                source => "puppet:///modules/${module_name}/bashrc";
            }
        }

}
#apt-get -y install rsnapshot curlftpfs git libjpeg62-dev mc emacs-goodies-el emacs23-nox htop tree fail2ban vim python-pip lftp dstat bzip2 build-essential python-dev libxml2-dev

