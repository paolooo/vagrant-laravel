# Default path
include apt::update
Exec {
  path => ['/usr/bin', '/bin', '/usr/sbin', '/sbin', '/usr/local/bin', '/usr/local/sbin', '/opt/local/bin'],
  logoutput => true
}
Exec['apt_update'] -> Package <| |>

exec { 'apt-get update':
  command => '/usr/bin/apt-get update --fix-missing'
}


# Configuration
if $db_name == '' { $db_name = 'development' }
if $db_location == '' { $db_location  = '/vagrant/db/development.sqlite' }
if $username == '' { $username = 'root' }
if $password == '' { $password = '123' }
if $host == '' { $host = 'localhost' }

# Other Packages
package { ['vim','curl','phpunit','php5-cli','php5-sqlite','unzip']:
  ensure  => 'installed'
}


# Packages
include apache
include php
include mysql
include postgresql
include sqlite
include laravel
include composer

# Setup
## Apache
class {'apache::mod::php': }

apache::vhost { $fqdn:
  priority  => '20',
  port => '80',
  docroot => $docroot,
  configure_firewall  => false,
}

a2mod { 'rewrite': ensure => present }


## PHP
class { 'php':
  version => '5.4.11'
}

php::module { ['xdebug', 'mysql', 'curl', 'gd']:
  notify  => [ Service['httpd'], ],
}

#php::conf { ['pdo','pdo_sqlite']:
#  require => Package['sqlite'],
#  notify  => Service['httpd'],
#}

## MySQL Server
class { 'mysql::server':
  config_hash => { 'root_password' => "${password}" }
}

mysql::db { "${db_name}":
  user  => "${username}",
  password  => "${password}",
  host  =>  "${host}",
  grant => ['all'],
  charset => 'utf8',
}

## PostgreSQL Server
class { 'postgresql::server': }

postgresql::db { "${db_name}":
  user => "${db_name}",
  password  => "${password}",
}

## SQLite Config
define sqlite::db(
    $location   = '',
    $owner      = 'root',
    $group      = 0,
    $mode       = '755',
    $ensure     = present,
    $sqlite_cmd = 'sqlite3'
  ) {

      file { $safe_location:
        ensure  => $ensure,
        owner   => $owner,
        group   => $group,
        notify  => Exec['create_development_db']
      }

      exec { 'create_development_db':
        command     => "${sqlite_cmd} $db_location",
        path        => '/usr/bin:/usr/local/bin',
        refreshonly => true,
      }
  }
