# Default path
Exec { path => ['/usr/bin', '/bin', '/usr/sbin', '/sbin', '/usr/local/bin', '/usr/local/sbin', '/opt/local/bin'] }
exec { 'apt-get update':
  command => '/usr/bin/apt-get update --fix-missing',
  require => Exec['add php54 apt-repo']
}

# Configuration
if $db_name == '' { $db_name = 'development' }
if $db_location == '' { $db_location  = '/vagrant/db/development.sqlite' }
if $username == '' { $username = 'root' }
if $password == '' { $password = '123' }
if $host == '' { $host = 'localhost' }

# Setup

## PHP
include php54
class { 'php': version => latest, }

## APACHE2
include apache
class {'apache::mod::php': }

## PACKAGES
## 'vim','curl','unzip','git','php5-mysql','php5-sqlite','php5-mcrypt','php5-memcache',
## 'php5-suhosin','php5-xsl','php5-tidy','php5-dev','php5-pgsql','php5-odbc', 'php5-ldap','php5-xmlrpc','php5-intl','php5-fpm'
package { ['vim','curl','unzip','git','php5-mcrypt','php5-memcached']:
  ensure  => installed,
  require => Exec['apt-get update'],
}

package { ['php5-mysql','php5-sqlite']:
  ensure  => installed,
  require => Exec['apt-get update'],
}


include pear
include mysql
##include postgresql
include sqlite
include composer

### MySQL Server
class { 'mysql::server':
  config_hash => { 'root_password' => "${password}" }
}

## Apache
apache::vhost { $fqdn:
  priority  => '20',
  port => '80',
  docroot => "${docroot}/src/public",
  logroot => "${docroot}/src", # access_log and error_log
  configure_firewall  => false,
}
a2mod { 'rewrite': ensure => present }

## LARAVEL
class { "laravel":
  root  => "${docroot}/src"
}

## Ruby
class { "ruby": 
  gems_version => "latest"
}

## Nodejs
class { "nodejs": }
php::module { ['curl', 'gd']:
  notify  => [ Service['httpd'], ],
}

## PEAR
pear::package { "PEAR": }
pear::package { "PHPUnit": 
  version     => "latest",
  repository  => "pear.phpunit.de",
  require     => Pear::Package["PEAR"],
}

## DB
mysql::db { "${db_name}":
  user  => "${username}",
  password  => "${password}",
  host  =>  "${host}",
  grant => ['all'],
  charset => 'utf8',
}

### PostgreSQL Server
##class { 'postgresql::server': }
##
##postgresql::db { "${db_name}":
##  user => "${db_name}",
##  password  => "${password}",
##}
#
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

