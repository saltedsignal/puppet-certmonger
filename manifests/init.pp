# == Class: certmonger
#
# == Parameters
# [*local_ca_validity_period*]
# String.
# This is the validity period given to the locally-signed CA's certificate
# when it is generated. The value is specified as a combination of years (y),
# months (M), weeks (w),  days  (d),  hours(h),  minutes  (m), and/or
# seconds (s).  If no unit of time is specified, seconds are assumed. the
# default value is 1y.
#
class certmonger (
  Optional[String] $local_ca_validity_period = undef,
){

  package { 'certmonger':
    ensure => 'present',
  }

  if $local_ca_validity_period == '' or $local_ca_validity_period == undef {
    $local_ca_validity_period_present = 'absent'
  } else {
    $local_ca_validity_period_present = 'present'
  }
  ini_setting { 'local CA validity_period':
    ensure  => $local_ca_validity_period_present,
    path    => '/etc/certmonger/certmonger.conf',
    section => 'local',
    setting => 'validity_period',
    value   => $local_ca_validity_period,
    require => Package['certmonger']
  }
  Ini_setting['local CA validity_period'] ~> Service['certmonger']
  service { 'certmonger':
    ensure => 'running',
    enable => true,
  }

}
