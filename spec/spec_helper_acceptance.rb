require 'beaker-rspec'
require 'beaker/puppet_install_helper'
 
run_puppet_install_helper
 
RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
 
  c.formatter = :documentation
 
  c.before :suite do
    hosts.each do |host|
      copy_module_to(host, :source => proj_root, :module_name => 'certmonger')
      on host, puppet('module install puppetlabs-stdlib'),
        {:acceptable_exit_codes => [0]}
      on(host, "sudo yum -y install ipa-server > /tmp/ipa-install-out")
      scp_to(host, "#{proj_root}/files/verify_certmonger_request.sh", "/tmp/")
      #on(host, "ipa-server-install -n example.local -r EXAMPLE.LOCAL -p vinodh87 -a vinodh87 --no-host-dns --no-ntp --unattended")
    end
  end
end
