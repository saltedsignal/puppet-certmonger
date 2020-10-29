[![Puppet Forge](http://img.shields.io/puppetforge/v/saltedsignal/certmonger.svg)](https://forge.puppetlabs.com/saltedsignal/certmonger)
[![Build Status](https://travis-ci.org/saltedsignal/puppet-certmonger.svg?branch=master)](https://travis-ci.org/saltedsignal/puppet-certmonger)

# Certmonger puppet module

This puppet module allows you to request and manage certificates using certmonger.

## Request a certificate from IPA using the defined type

### Simple usage:

```puppet
certmonger::request_ipa_cert { 'server-crt':
  certfile => '/etc/pki/tls/certs/server.crt',
  keyfile  => '/etc/pki/tls/private/server.key',
}
```

Note: there is no need to use the `certmonger` class, it gets included by the define and has no parameters of its own.

### Parameters:
* `certfile`    (required; String) - Full path of certificate to be managed by certmonger. e.g. `/path/to/certificate.crt`
* `keyfile`     (required; String) - Full path to private key file to be managed by certmonger. e.g. `/path/to/key.pem`
* `keysize`     (optional; String) - Generate keys with a specific keysize in bits. e.g. `4096`
* `hostname`    (optional; String) - Hostname to use (appears in subject field of cert). e.g. `webserver.example.com`
* `principal`   (optional; String) - IPA service principal certmonger should use when requesting cert.
                                     e.g. `HTTP/webserver.example.com`.
* `dns`         (optional; String or Array) - DNS subjectAltNames to be present in the certificate request.
                                     Can be a string (use commas or spaces to separate values) or an array.
                                     e.g. `ssl.example.com webserver01.example.com`
                                     e.g. `ssl.example.com, webserver01.example.com`
                                     e.g. `["ssl.example.com","webserver01.example.com"]`
* `eku`         (optional; String or Array) - Extended Key Usage attributes to be present in the certificate request.
                                     Can be a string (use commas or spaces to separate values) or an array.
                                     e.g. `id-kp-clientAuth id-kp-serverAuth`
                                     e.g. `id-kp-clientAuth, id-kp-serverAuth`
                                     e.g. `["id-kp-clientAuth","id-kp-serverAuth"]`
* `usage`       (optional; String or Array) - Key Usage attributes to be present in the certificate request.
                                     Can be a string (use commas or spaces to separate values) or an array.
                                     e.g. `digitalSignature nonRepudiation keyEncipherment`
                                     e.g. `digitalSignature, nonRepudiation, keyEncipherment`
                                     e.g. `["digitalSignature", "nonRepudiation", "keyEncipherment"]`
* `presavecmd`  (optional; String) - Command certmonger should run before saving the certificate
* `postsavecmd` (optional; String) - Command certmonger should run after saving the certificate
* `cacertfile`  (optional; String) - Ask certmonger to save the CA's certificate to this path. eg. `/path/to/ca.crt`
* `profile`     (optional; String) - Ask the CA to process request using the named profile. e.g. `caIPAserviceCert`
* `issuer`      (optional; String) - Ask the CA to process the request using the named issuer. e.g. `ca-puppet`
* `issuerdn`    (optional; String) - If a specific issuer is needed, provide the issuer DN. e.g. `CN=Puppet CA`

### Actions:
* Submits a certificate request to an IPA server for a new certificate via `ipa-getcert` utility

### **!!! WARNING !!!!**
* Changing the location of a `certfile` or `keyfile` can't be done using `ipa-getcert resubmit`,
  which means this module **will take a more aggressive approach**, i.e. it will stop tracking the existing cert,
  delete the key/certfile and submit a brand new request. If the new request fails, bad luck, the old files are gone.

### Fixing file/folder permissions after certificate issuance
A notable limitation of `ipa-getcert` is that the `postsavecmd` can only take a single command. This means changing file ownership/modes and restarting services requires the use of a separate helper utility. This module includes a creatively named script called `change-perms-restart`, which gets installed by the `certmonger` class as `/usr/local/bin/change-perms-restart`. Usage is as follows:

```
/usr/local/bin/change-perms-restart [-R] [ -r 'service1 service2' ] [ -t 'service3 service4' ] [ -T 'TIMESPEC' ] [ -s facility.severity ] owner:group:modes:/path/to/file [ ... ]

   -R     change ownership/group/modes recursively (e.g. when specifying a folder)
   -r     space separated list of services to reload via systemctl
   -t     space separated list of services to restart via systemctl
   -T     systemd oncalendar timespec. If specified, will delay the restart using a one-time systemd timer via systemd-run.
   -s     log output (if any) to syslog with specified facility/severity
```

For example: `change-perms-restart -R -s daemon.notice  -r 'httpd rsyslog' -t 'postfix postgresql' -T '02:00:00' root:pkiuser:0644:/etc/pki/tls/certs/localhost.crt root:pkiuser:0600:/etc/pki/tls/private/localhost.key`

### Other limitations:
* The current state is determined by calling a custom shell script (supplied). Not ideal, I know.
* Only supports file-based certificates (i.e. no support for NSSDB).
* Does not manage the nickname, IP address, email, etc features.
* Only manages subject, dns (subjectAltNames), key usage, eku, principal, issuer, pre/post save commands.
* Only manages the principal if it appears in the issued certificate - which depends on your CA profile.
* Once a certificate is issued, this module can't manage the profile because it doesn't appear in the issued certificate.
* This module won't re-generate keys if you set or change `keysize` of an existing certificate.
* This module won't resubmit the request if the only thing changed is the `cacertfile` parameter.
* Subject is hardcoded to `CN=$hostname`.
* Only works if being run on a system already joined to an IPA domain, and only works against IPA CAs.
* If you specify a hostname and don't specify a principal, this module will assume you want `host/$hostname`.
  This is needed because `ipa-getcert` requires a principal if being passed a subject.
* If you don't specify an optional parameter (eg, if you dont supply `$dns`), this module will not touch that parameter
  of the existing request, even if the request has a value for that parameter present.
* The `title` or `namevar` of the define doesn't get used - everything revolves around `certfile`.
* This module won't fix SELinux AVC denials: make sure certmonger can read/write to the location of `certfile` and `keyfile`.
* This module won't attempt to add service principals in IPA if they don't exist. You may need to do this manually.
* Certmonger needs to manage `keyfile` and `certfile`, which means you shouldn't create them yourself, but you can change
  their ownership/permissions once they've been created (e.g. via `postsavecmd` or via a file resource in another puppet manifest).
  See example below on how to use the supplied `change-perms-restart` script to achieve this and restart httpd as one command.
* Tested only on CentOS 7.

### More elaborate example:

```puppet
  certmonger::request_ipa_cert {'webserver-certificate':
     hostname    => "${fqdn}",
     principal   => "HTTP/${fqdn}",
     keyfile     => "/etc/pki/tls/private/server.key",
     certfile    => "/etc/pki/tls/certs/server.crt",
     dns         => ['vhost1.example.com','vhost2.example.com'],
     postsavecmd => "/usr/local/bin/change-perms-restart -s daemon.notice -r httpd root:pkiuser:0640:/etc/pki/tls/private/server.key root:pkiuser:0644:/etc/pki/tls/certs/server.crt",
  }
```

## Request a certificate using the native type/provider

This will create a certificate request with the given hostname (which will be
used in the subject as the CN) and the given principal. It will use the key
specified by 'keyfile'. And if it succeeds it will track the certificate where
'certfile' specifies the resource to do so.

```puppet
  certmonger_certificate { 'my-cert':
    ensure    => 'present',
    ca        => 'IPA'
    certfile  => '/path/to/certs/my-cert.pem',
    keyfile   => '/path/to/certs/my-key.pem',
    keysize   => '3076',
    hostname  => 'hostname.example.com'
    principal => 'HTTP/hostname.example.com',
  }
```

If the certificate already exists it will simply take the values and add it to
the resource catalog. However, you can tell the provider to resubmit the
certificate if it already exists. This is done by setting the 'force_resubmit'
flag. Currently the aforementioned flag is needed if the parameters for the
request have changed and you wish to resubmit it.

If, for some reason, the CA rejects your request, you can still see the
certificate resource, and the status will reflect the rejection. So, when
viewing the resource, you'll see the following:

```puppet
  certmonger_certificate { 'my-cert':
    ensure      => 'present',
    ca          => 'local'
    certbackend => 'FILE',
    certfile    => '/path/to/certs/my-cert.pem',
    keysize     => 'KEY_SIZE_VALUE',
    keybackend  => 'FILE',
    keyfile     => '/path/to/certs/my-key.pem',
    status      => 'CA_REJECTED',
  }
```

The default behavior is to throw an error if the CA rejects the request. But
errors can be ignored with the 'ignore_ca_errors' parameter.

One can also automatically stop tracking the certificate request if it's
rejected by the CA. This is done by setting the 'cleanup_on_error' flag.

### Limitations
* The native type/provider isn't as mature as the defined type, which means its parameters/properties are likely change in a non-backward compatible way.
* The defined type is very mature - its parameters are unlikely to change, and if they do, those changes will be backward-compatible.
* If you're using IPA and are having trouble with the native type/provider, try switching to the defined type.

## Contributing
* Fork it
* Create a topic branch
* Make your changes
* Submit a PR

## Acknowledgements

This module is brought to you by [Salted Signal](https://www.saltedsignal.com.au) - a Melbourne-based cloud automation, DevSecOps, security and compliance company.

Honorable mentions go out to:
* Rob Crittenden for his work on https://github.com/rcritten/puppet-certmonger, which was used as inspiration for this module.
* Juan Antonio Osorio for his work on the certmonger type/provider and setting up rpsec tests/travis-ci integration.
* Alex J Fisher for fixing rubocop violations
* Ewoud Kohl van Wijngaarden for implementing Puppet 4 types and contributing tests for the defined type.
