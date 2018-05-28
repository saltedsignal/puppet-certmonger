# Class: certmonger
class certmonger {
  # DBus package update from 7.4 to 7.5 breaks
  # The certmonger service, so dbus must get a
  # restart prior to start certmonger.
  # The official solution for dbus is either
  # restart the service, or reboot the machine
  service { 'dbus':
    ensure => running,
    enable => true,
    restart => '',
  }

  package { 'certmonger':
    ensure => 'present',
  } ->
  service { 'certmonger':
    ensure => 'running',
    enable => true,
  }

}
