class sqlite {
    file {'/etc/groupme.db':
        ensure => 'present',
        mode => 755,
    }
    package { 'sqlite3':
        ensure => present,
    }
}
