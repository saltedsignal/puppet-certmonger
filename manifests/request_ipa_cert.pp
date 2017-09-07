# == Define: certmonger::request_ipa_cert
#
# Request a new certificate from IPA (via certmonger) using a puppet define
#
# === Parameters
#
# $certfile::     Full path of certificate to be managed by certmonger. e.g. `/path/to/certificate.crt`
# $keyfile::      Full path to private key file to be manaegd by certmonger. e.g. `/path/to/key.pem`
# $keysize::      Generate keys with a specific keysize in bits. e.g. `4096`
# $hostname::     Hostname to use (appears in subject field of cert). e.g. `webserver.example.com`
# $principal::    IPA service principal certmonger should use when requesting cert.
#                 e.g. `HTTP/webserver.example.com`.
# $dns::          DNS subjectAltNames to be present in the certificate request.
#                 Can be a string (use commas or spaces to separate values) or an array.
#                 e.g. `ssl.example.com webserver01.example.com`
#                 e.g. `ssl.example.com, webserver01.example.com`
#                 e.g. `["ssl.example.com","webserver01.example.com"]`
# $eku::          Extended Key Usage attributes to be present in the certificate request.
#                 Can be a string (use commas or spaces to separate values) or an array.
#                 e.g. `id-kp-clientAuth id-kp-serverAuth`
#                 e.g. `id-kp-clientAuth, id-kp-serverAuth`
#                 e.g. `["id-kp-clientAuth","id-kp-serverAuth"]`
# $usage::        Key Usage attributes to be present in the certificate request.
#                 Can be a string (use commas or spaces to separate values) or an array.
#                 e.g. `digitalSignature nonRepudiation keyEncipherment`
#                 e.g. `digitalSignature, nonRepudiation, keyEncipherment`
#                 e.g. `["digitalSignature", "nonRepudiation", "keyEncipherment"]`
# $presavecmd::   Command certmonger should run before saving the certificate
# $postsavecmd::  Command certmonger should run after saving the certificate
# $cacertfile::   Ask certmonger to save the CA's certificate to this path. eg. `/path/to/ca.crt`
# $profile::      Ask the CA to process request using the named profile. e.g. `caIPAserviceCert`
# $issuer::       Ask the CA to process the request using the named issuer. e.g. `ca-puppet`
# $issuerdn::     If a specific issuer is needed, provide the issuer DN. e.g. `CN=Puppet CA`
#
define certmonger::request_ipa_cert (
  Stdlib::Absolutepath                  $certfile,
  Stdlib::Absolutepath                  $keyfile,
  Variant[Integer[2048], String, Undef] $keysize     = undef,
  Optional[String]                      $hostname    = undef,
  Optional[String]                      $principal   = undef,
  Variant[Array[String], String, Undef] $dns         = undef,
  Variant[Array[String], String, Undef] $eku         = undef,
  Variant[Array[String], String, Undef] $usage       = undef,
  Optional[String]                      $presavecmd  = undef,
  Optional[String]                      $postsavecmd = undef,
  Optional[String]                      $profile     = undef,
  Optional[Stdlib::Absolutepath]        $cacertfile  = undef,
  Optional[String]                      $issuer      = undef,
  Optional[String]                      $issuerdn    = undef,
) {
  include ::certmonger
  include ::certmonger::scripts

  $options = "-f ${certfile} -k ${keyfile}"
  $options_certfile = "-f ${certfile}"

  if $keysize {
    $options_keysize = "-g ${keysize}"
  } else {
    $options_keysize = ''
  }

  if $hostname {
    $subject = "CN=${hostname}"
    $options_subject = "-N ${subject}"
  } else {
    $subject = ''
    $options_subject =  ''
  }

  if $principal {
    $options_principal = "-K ${principal}"
  } elsif $hostname {
    $options_principal = "-K host/${hostname}"
  } else {
    $options_principal = ''
  }

  if $dns {
    if $dns =~ String {
      $dns_array = split(regsubst(strip($dns),'[ ,]+', ',', 'G'), ',')
    } else {
      $dns_array = $dns
    }
    $options_dns_joined = join($dns_array, ' -D ')
    $dns_csv = join($dns_array, ',')

    $options_dns = regsubst($options_dns_joined, '^', '-D ')
    $options_dns_csv = "-D ${dns_csv}"
  } else {
    $options_dns = ''
    $options_dns_csv = ''
  }

  if $usage {
    if $usage =~ String {
      $usage_array = split(regsubst(strip($usage),'[ ,]+', ',', 'G'), ',')
    } else {
      $usage_array = $usage
    }

    $options_usage_joined = join($usage_array, ' -u ')
    $usage_csv = join($usage_array, ',')

    $options_usage = regsubst($options_usage_joined, '^', '-u ')
    $options_usage_csv = "-u ${usage_csv}"
  } else {
    $options_usage = ''
    $options_usage_csv = ''
  }

  if $eku {
    if $eku =~ String {
      $eku_array = split(regsubst(strip($eku),'[ ,]+', ',', 'G'), ',')
    } else {
      $eku_array = $eku
    }

    $options_eku_joined = join($eku_array, ' -U ')
    $eku_csv = join($eku_array, ',')

    $options_eku = regsubst($options_eku_joined, '^', '-U ')
    $options_eku_csv = "-U ${eku_csv}"
  } else {
    $options_eku = ''
    $options_eku_csv = ''
  }

  if $presavecmd { $options_presavecmd = "-B '${presavecmd}'" } else { $options_presavecmd = '' }
  if $postsavecmd { $options_postsavecmd = "-C '${postsavecmd}'" } else { $options_postsavecmd = '' }
  if $profile { $options_profile = "-T '${profile}'" } else { $options_profile = '' }
  if $cacertfile { $options_cacertfile = "-F '${cacertfile}'" } else { $options_cacertfile = '' }
  if $issuer {
    $options_issuer = "-X '${issuer}'"
    if $issuerdn {
      $options_issuerdn = "-X '${issuerdn}'"
    } else {
      fail('certmonger::request_ipa_cert: issuerdn is required if issuer is specified.')
    }
  } else {
    $options_issuer = ''
    $options_issuerdn = ''
  }

  $resubmit_attrib_options = "${options_subject} ${options_principal} ${options_dns} ${options_cacertfile} \
    ${options_usage} ${options_eku} ${options_issuer} ${options_profile} ${options_presavecmd} ${options_postsavecmd}"
  $request_attrib_options = "${options_keysize} ${resubmit_attrib_options}"
  $verify_attrib_options = "${options_subject} ${options_principal} ${options_dns_csv} \
    ${options_usage_csv} ${options_eku_csv} ${options_issuerdn} ${options_presavecmd} ${options_postsavecmd}"

  exec { "ipa-getcert-${certfile}-trigger":
    path    => '/usr/bin:/bin',
    command => '/bin/true',
    unless  => "${::certmonger::scripts::verifyscript} ${options} ${verify_attrib_options}",
    onlyif  => '/usr/bin/test -s /etc/ipa/default.conf',
    require => [Service['certmonger'], File[$::certmonger::scripts::verifyscript]],
    notify  => [Exec["ipa-getcert-request-${certfile}"],Exec["ipa-getcert-resubmit-${certfile}"]],
  }

  exec { "ipa-getcert-request-${certfile}":
    refreshonly => true,
    path        => '/usr/bin:/bin',
    provider    => 'shell',
    command     => "rm -rf ${keyfile} ${certfile} ; mkdir -p `dirname ${keyfile}` `dirname ${certfile}` ;
                    ipa-getcert stop-tracking ${options_certfile} ;
                    ipa-getcert request ${options} ${request_attrib_options}",
    unless      => "${::certmonger::scripts::verifyscript} ${options}",
    notify      => Exec["ipa-getcert-${certfile}-verify"],
    require     => [Service['certmonger'],File[$::certmonger::scripts::verifyscript]],
  }

  exec { "ipa-getcert-resubmit-${certfile}":
    refreshonly => true,
    path        => '/usr/bin:/bin',
    provider    => 'shell',
    command     => "ipa-getcert resubmit ${options_certfile} ${resubmit_attrib_options}",
    unless      => "${::certmonger::scripts::verifyscript} ${options_certfile} ${verify_attrib_options}",
    onlyif      => ["${::certmonger::scripts::verifyscript} ${options}","openssl x509 -in ${certfile} -noout"],
    notify      => Exec["ipa-getcert-${certfile}-verify"],
    require     => [Service['certmonger'], File[$::certmonger::scripts::verifyscript]],
  }

  exec {"ipa-getcert-${certfile}-verify":
    refreshonly => true,
    path        => '/usr/bin:/bin',
    command     => "${::certmonger::scripts::verifyscript} -w 8 ${options} ${verify_attrib_options}",
    require     => [Service['certmonger'],File[$::certmonger::scripts::verifyscript]],
  }

}
