class apache {
    package { 'apache2':
        ensure => present,
    }

    file { '/etc/ssl/apache2/':
        ensure => "directory",
    }

    file { '/etc/apache2/sites-enabled/000-default':
        source => '/vagrant/modules/apache/files/000-default',
	require => Package['apache2'],
    }

    file { '/etc/ssl/apache2/server.crt':
        source => '/vagrant/modules/apache/files/server.crt',
        require => File['/etc/ssl/apache2/'],
    }

    file { '/etc/ssl/apache2/server.key':
        source => '/vagrant/modules/apache/files/server.key',
        require => File['/etc/ssl/apache2/'],
    }

    exec { 'mod_rewrite':
	command => 'a2enmod rewrite',
	path => [ '/usr/sbin/',"/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/"],
	require => Package['apache2'],
	notify => Service['apache2'],
    }

    exec { 'mod_ssl':
        command => 'a2enmod ssl',
        path => [ '/usr/sbin/',"/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/"],
        require => Package['apache2'],
        notify => Service['apache2'],
    }

    exec { 'mod_proxy':
        command => 'a2enmod proxy',
        path => [ '/usr/sbin/',"/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/"],
        require => Package['apache2'],
        notify => Service['apache2'],
    }

    exec { 'mod_proxy_http':
        command => 'a2enmod proxy_http',
        path => [ '/usr/sbin/',"/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/"],
        require => Package['apache2'],
        notify => Service['apache2'],
    }

    service { 'apache2':
        ensure => running,
        enable => true,
        require => [ File['/etc/ssl/apache2/server.key'],
                     File['/etc/ssl/apache2/server.crt'],
                     File['/etc/apache2/sites-enabled/000-default'],
                     Package['apache2'] ],
    }
}
