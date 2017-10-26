require 'spec_helper_acceptance'
 
describe 'certmonger' do
  let(:manifest) {
    <<-EOS
include certmonger
EOS
  }
  it 'should apply without errors' do
    apply_manifest(manifest, :catch_failures => true)
  end
 
  it 'should apply a second time without changes' do
    @result = apply_manifest(manifest)
    expect(@result.exit_code).to be_zero
  end
  describe service('certmonger') do
    it { should be_enabled }
    it { should be_running }
  end
  describe package('certmonger') do
    it { is_expected.to be_installed }
  end
end

describe 'certmonger::request_ipa_cert' do
  let(:manifest){
    <<-EOS
certmonger::request_ipa_cert { request:
  certfile => "/tmp/server.crt",
  keyfile  => "/tmp/server.key",
}
EOS
  }
  it 'should apply without errors' do
    apply_manifest(manifest, :catch_failures => true)
  end
  it 'should apply a second time without changes' do
    @result = apply_manifest(manifest)
    expect(@result.exit_code).to be_zero
  end
end
  
#describe 'verify script' do
#    it 'runs verify script without errors' do
#      shell("/tmp/verify_certmonger_request.sh", :acceptable_exit_codes => [0])
#    end
#end
