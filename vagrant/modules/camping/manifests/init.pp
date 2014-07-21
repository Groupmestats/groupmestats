class camping {

    file {'/etc/default/camping-server':
	source => '/vagrant/modules/camping/files/camping-server.default',
	mode => 755,
    }

    file {'/etc/init.d/camping-server':
        source => '/vagrant/modules/camping/files/camping-server.init',
        mode => 755,
    }

    package { 'camping':
        ensure => present,
    }

    service { 'camping-server':
	ensure => running,
	enable => true,
	require => [ File['/etc/default/camping-server'],
		     File['/etc/init.d/camping-server'],
		     Package['camping'] ],
    }
}
