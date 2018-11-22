# Class: certmonger
class certmonger {

  package { 'certmonger':
    ensure => 'present',
  }
  -> service { 'certmonger':
    ensure => 'running',
    enable => true,
  }

}
