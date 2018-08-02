require 'ipaddr'

Puppet::Type.type(:certmonger_certificate).provide :certmonger_certificate do
  desc 'Provider for certmonger certificates.'

  confine exists: '/usr/sbin/certmonger'
  commands getcert: '/usr/bin/getcert'

  mk_resource_methods

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def create
    @property_flush[:ensure] = :present
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def self.list_of_certs
    output = getcert('list')
    parse_cert_list(output)
  end

  def self.parse_cert_list(list_output)
    output_array = list_output.split("\n")
    cert_list = []
    current_cert = {}
    output_array.each do |line|
      case line
      when %r{^Number of certificates and requests}
        # skip preamble
        next
      when %r{^Request ID.*}
        # New certificate info. Append previous one.
        if current_cert[:name]
          current_cert[:ensure] = :present
          cert_list << current_cert
          current_cert = {}
        end
        current_cert[:name] = line.match(%r{Request ID '(.+)':})[1]
      else
        unless current_cert[:name]
          raise Puppet::Error, "Invalid data coming from 'getcert list'."
        end

        case line
        when %r{^\s+status: .*}
          current_cert[:status] = line.match(%r{status: (.+)})[1]
        when %r{^\s+key pair storage: .*}
          key_match = line.match(%r{type=([A-Z]+),.*location='(.+?)'})
          current_cert[:keybackend] = key_match[1]
          current_cert[:keyfile] = key_match[2]
        when %r{^\s+certificate: .*}
          cert_match = line.match(%r{type=([A-Z]+),.*location='(.+?)'})
          current_cert[:certbackend] = cert_match[1]
          current_cert[:certfile] = cert_match[2]
        when %r{^\s+CA: .*}
          current_cert[:ca] = line.match(%r{CA: (.*)})[1]
        when %r{^\s+subject: .*}
          # FIXME(jaosorior): This is hacky! Use an actual library to parse
          # the subject.
          subj_match = line.match(%r{subject: (.*)})
          if subj_match[1].empty?
            current_cert[:hostname] = ''
          else
            cn_match = line.match(%r{subject: .*CN=(.*?)(?:,.*|$)})
            current_cert[:hostname] = cn_match[1]
          end
        when %r{^\s+dns: .*}
          dns_raw = line.match(%r{dns: (.*)})[1]
          current_cert[:dnsname] = dns_raw.split(',')
        when %r{^\s+eku: .*}
          eku_raw = line.match(%r{eku: (.*)})[1]
          current_cert[:eku] = eku_raw.split(',')
        when %r{^\s+ca-error: .*}
          current_cert[:ca_error] = line.match(%r{ca-error: (.*)})[1]
        when %r{^\s+pre-save command: .*}
          current_cert[:presave_cmd] = line.match(%r{pre-save command: (.*)})[1]
        when %r{^\s+post-save command: .*}
          current_cert[:postsave_cmd] = line.match(
            %r{post-save command: (.*)}
          )[1]
        end
      end
    end
    if current_cert[:name]
      current_cert[:ensure] = :present
      cert_list << current_cert
    end
    cert_list
  end

  def self.instances
    list_of_certs.map do |cert|
      new(cert)
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov
      end
    end
  end

  def flush
    if @property_flush[:ensure] == :absent
      getcert(['stop-tracking', '-i', resource[:name]])
    else
      if !@property_hash.empty?
        request_args = ['resubmit', '-i', resource[:name]]
        request_args.concat get_base_args(resource)
        getcert request_args
      else
        request_args = ['request', '-I', resource[:name]]
        request_args.concat get_base_args(resource)
        request_args.concat get_request_args(resource)

        begin
          Puppet.debug("Issuing getcert command with args: #{request_args}")
          getcert request_args
        rescue Puppet::ExecutionFailure => msg
          Puppet.warning("Could not get certificate: #{msg}")
        end

      end

      refresh resource
      cleanup resource
    end
  end

  def get_base_args(resource)
    request_args = []
    raise ArgumentError, 'An empty value for the certfile is not allowed' unless resource[:certfile]
    request_args << '-f'
    request_args << resource[:certfile]

    raise ArgumentError, 'You need to specify a CA' unless resource[:ca]
    request_args << '-c'
    request_args << resource[:ca]

    if resource[:hostname]
      request_args << '-N'
      request_args << "CN=#{resource[:hostname]}"
    end
    if resource[:principal]
      request_args << '-K'
      request_args << resource[:principal]
    end
    if resource[:dnsname]
      dnsarray = if resource[:dnsname].is_a? String
                   [resource[:dnsname]]
                 else
                   resource[:dnsname]
                 end
      dnsarray.each do |dnsname|
        begin
          # We just call this to see if it's a valid IP
          IPAddr.new(dnsname)
          request_args << '-A'
          request_args << dnsname
        rescue ArgumentError
          request_args << '-D'
          request_args << dnsname
        end
      end
    end
    if resource[:eku]
      ekuarray = if resource[:eku].is_a? String
                   [resource[:eku]]
                 else
                   resource[:eku]
                 end
      ekuarray.each do |eku|
        request_args << '-U'
        request_args << eku
      end
    end
    if resource[:presave_cmd]
      request_args << '-B'
      request_args << "\"#{resource[:presave_cmd]}\""
    end
    if resource[:postsave_cmd]
      request_args << '-C'
      request_args << "\"#{resource[:postsave_cmd]}\""
    end

    request_args << '-w' if resource[:wait]
    request_args
  end

  def get_request_args(resource)
    request_args = []
    raise ArgumentError, 'An empty value for the keyfile is not allowed' unless resource[:keyfile]
    request_args << '-k'
    request_args << resource[:keyfile]

    if resource[:profile]
      request_args << '-T'
      request_args << resource[:profile]
    end
    if resource[:cacertfile]
      request_args << '-F'
      request_args << resource[:cacertfile]
    end
    request_args
  end

  def refresh(resource)
    output = getcert(['list', '-i', resource[:name]])
    @property_hash = self.class.parse_cert_list(output)[0]
  rescue
    raise Puppet::Error, ("The certificate '#{resource[:name]}' wasn't " \
                          'found in the list.')
  end

  def cleanup(resource)
    return unless @property_hash[:ca_error]
    if resource[:cleanup_on_error]
      getcert(['stop-tracking', '-i', resource[:name]])
    end
    raise Puppet::Error, "Could not get certificate: #{@property_hash[:ca_error]}" unless resource[:ignore_ca_errors]
  end
end
