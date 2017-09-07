require 'spec_helper'

describe 'certmonger::request_ipa_cert' do
  let :title do
    'apache'
  end

  let :params do
    {
      :certfile => '/tmp/server.crt',
      :keyfile  => '/tmp/server.key',
    }.merge(extra_params)
  end

  context 'with minimal parameters' do
    let :extra_params do
      {}
    end

    command = "rm -rf /tmp/server.key /tmp/server.crt ; mkdir -p `dirname /tmp/server.key` `dirname /tmp/server.crt` ;
                    ipa-getcert stop-tracking -f /tmp/server.crt ;
                    ipa-getcert request -f /tmp/server.crt -k /tmp/server.key               "

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_exec('ipa-getcert-request-/tmp/server.crt').with_command(command) }
  end

  context 'with strings' do
    let :extra_params do
      {
        :keysize     => '4096',
        :hostname    => 'myhost.example.com',
        :principal   => 'HTTP/myhost.example.com',
        :dns         => 'www.example.com,myhost.example.com',
        :eku         => 'id-kp-clientAuth, id-kp-serverAuth',
        :usage       => 'digitalSignature nonRepudiation keyEncipherment',
        :presavecmd  => '/bin/systemctl stop httpd',
        :postsavecmd => '/bin/systemctl start httpd',
        :cacertfile  => '/path/to/ca.crt',
        :profile     => 'caIPAserviceCert',
        :issuer      => 'ca-puppet',
        :issuerdn    => 'CA=Puppet CA',
      }
    end

    command = "rm -rf /tmp/server.key /tmp/server.crt ; mkdir -p `dirname /tmp/server.key` `dirname /tmp/server.crt` ;
                    ipa-getcert stop-tracking -f /tmp/server.crt ;
                    ipa-getcert request -f /tmp/server.crt -k /tmp/server.key -g 4096 -N CN=myhost.example.com -K HTTP/myhost.example.com -D www.example.com -D myhost.example.com -F '/path/to/ca.crt'     -u digitalSignature -u nonRepudiation -u keyEncipherment -U id-kp-clientAuth -U id-kp-serverAuth -X 'ca-puppet' -T 'caIPAserviceCert' -B '/bin/systemctl stop httpd' -C '/bin/systemctl start httpd'"

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_exec('ipa-getcert-request-/tmp/server.crt').with_command(command) }
  end

  context 'with arrays' do
    let :extra_params do
      {
        :keysize     => 4096,
        :hostname    => 'myhost.example.com',
        :principal   => 'HTTP/myhost.example.com',
        :dns         => ['www.example.com', 'myhost.example.com'],
        :eku         => ['id-kp-clientAuth', 'id-kp-serverAuth'],
        :usage       => ['digitalSignature', 'nonRepudiation', 'keyEncipherment'],
        :presavecmd  => '/bin/systemctl stop httpd',
        :postsavecmd => '/bin/systemctl start httpd',
        :cacertfile  => '/path/to/ca.crt',
        :profile     => 'caIPAserviceCert',
        :issuer      => 'ca-puppet',
        :issuerdn    => 'CA=Puppet CA',
      }
    end

    command = "rm -rf /tmp/server.key /tmp/server.crt ; mkdir -p `dirname /tmp/server.key` `dirname /tmp/server.crt` ;
                    ipa-getcert stop-tracking -f /tmp/server.crt ;
                    ipa-getcert request -f /tmp/server.crt -k /tmp/server.key -g 4096 -N CN=myhost.example.com -K HTTP/myhost.example.com -D www.example.com -D myhost.example.com -F '/path/to/ca.crt'     -u digitalSignature -u nonRepudiation -u keyEncipherment -U id-kp-clientAuth -U id-kp-serverAuth -X 'ca-puppet' -T 'caIPAserviceCert' -B '/bin/systemctl stop httpd' -C '/bin/systemctl start httpd'"

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_exec('ipa-getcert-request-/tmp/server.crt').with_command(command) }
  end
end
