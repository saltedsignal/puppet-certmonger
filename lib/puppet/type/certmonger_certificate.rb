Puppet::Type.newtype(:certmonger_certificate) do
  @doc = "Creates a new certificate using certmonger.
    The CA that is used to create the certificate depends
    on the provider.

    Examples
    --------

    This will stop tracking the certificate with the given nickname 'mycert':

      certmonger_certificate {'mycert':
        ensure => absent,
      }


    This will create a certificate request with the given hostname (which will
    be used in the subject as the CN) and the given principal. It will use the
    key specified by 'keyfile'. And if it succeeds it will track the
    certificate where 'certfile' specifies the resource to do so.

      certmonger_certificate { 'my-cert':
        ensure    => 'present',
        ca        => 'local'
        certfile  => '/path/to/certs/my-cert.pem',
        keyfile   => '/path/to/certs/my-key.pem',
        hostname  => 'hostname.example.com'
        principal => 'HTTP/hostname.example.com',
      }

    If you already had a valid certificate and key. You can track them with
    certmonger by just specifying the 'certfile' and 'keyfile'.

      certmonger_certificate { 'my-cert':
        ensure   => 'present',
        ca       => 'local'
        certfile => '/path/to/certs/my-cert.pem',
        keyfile  => '/path/to/certs/my-key.pem',
      }

    You can also specify another CA to use by setting the 'ca' attribute.
    For instance, for requesting a certificate from FreeIPA, you could do the
    following:

      certmonger_certificate { 'my-cert':
        ensure    => 'present',
        ca        => 'IPA'      # Note that 'IPA' is set here.
        certfile  => '/path/to/certs/my-cert.pem',
        keyfile   => '/path/to/certs/my-key.pem',
        hostname  => 'hostname.example.com'
        principal => 'HTTP/hostname.example.com',
      }

    If, for some reason, the CA rejects your request, you can still see the
    certificate resource, and the status will reflect the rejection. So, when
    viewing the resource, you'll see the following:

      certmonger_certificate { 'my-cert':
        ensure      => 'present',
        ca          => 'local'
        certbackend => 'FILE',
        certfile    => '/path/to/certs/my-cert.pem',
        keybackend  => 'FILE',
        keyfile     => '/path/to/certs/my-key.pem',
        status      => 'CA_REJECTED',
      }

    NOTE: for this resource, the certmonger's certificate nickname is
    mandatory, as it's used as the namevar attribute for the Puppet Type.
  "

  ensurable
  newparam(:name) do
    desc 'The nickname of the certificate request.'
    isnamevar
    validate do |value|
      raise ArgumentError, 'Empty values are not allowed' if value == ''
    end
  end

  newproperty(:certfile) do
    desc 'The file in which the certificate is being tracked on.'

    # TODO(jaosorior): This is temporary while openssl is the only supported
    # backend.
    isrequired
    validate do |value|
      raise ArgumentError, 'Empty values are not allowed' if value == ''
    end
  end

  newproperty(:keyfile) do
    desc "The file containing the certificate's key."

    # TODO(jaosorior): This is temporary while openssl is the only supported
    # backend.
    isrequired
    validate do |value|
      raise ArgumentError, 'Empty values are not allowed' if value == ''
    end
  end

  newproperty(:ca) do
    desc 'The CA from which the certificate was requested.'
    defaultto 'local'
    validate do |value|
      raise ArgumentError, 'Empty values are not allowed' if value == ''
    end
  end

  newproperty(:hostname) do
    desc 'The hostname used in the CN for the certificate.'
  end

  newproperty(:principal) do
    desc 'The requested principal name in the certificate.'
  end

  newproperty(:dnsname, array_matching: :all) do
    desc 'The DNS name used in the subjectAltNames for the certificate.'
  end

  newproperty(:eku, array_matching: :all) do
    desc 'The Extended Key Usage OID\'s names used for the certificate.'
  end

  newproperty(:status) do
    desc "The certificate request's status."
  end

  newproperty(:keybackend) do
    desc 'The backend being used for storing the key.'
  end

  newproperty(:certbackend) do
    desc 'The backend being used for storing the certificate.'
  end

  newproperty(:presave_cmd) do
    desc 'A command that will be issued before storing the certificate.'
  end

  newproperty(:postsave_cmd) do
    desc 'A command that will be issued after storing the certificate.'
  end

  newproperty(:ca_error) do
    desc 'The error info provided in case the CA reported an error with ' \
          'the request.'
  end

  newparam(:profile) do
    desc 'ask the CA to process the request using the named profile.'
  end

  newparam(:cacertfile) do
    desc 'Persist the CA certificate in a file in the given path.'
  end

  newparam(:force_resubmit) do
    desc 'If the request is found, force a resubmit operation. (currently ' \
         'not used)'
    defaultto false
    newvalues(true, false)
  end

  newparam(:wait) do
    desc 'Try to wait for the certificate to be isued.'
    defaultto true
    newvalues(true, false)
  end

  newparam(:ignore_ca_errors) do
    desc 'Ignore errors related to the CA.'
    defaultto false
    newvalues(true, false)
  end

  newparam(:cleanup_on_error) do
    desc 'Stop tracking if an error is reported by the CA.'
    defaultto false
    newvalues(true, false)
  end
end
