require 'spec_helper'

describe 'shibboleth_idp::jetty', :type => :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:environment => 'test', :root_home => '/root', :service_provider => 'systemd')
      end

      let :pre_condition do
        'class{"shibboleth_idp":
            idp_server_name => "shibvm-idp.example.com",
            idp_entity_id => "https://shibvm-idp.miamioh.edu:21443/idp/shibboleth",
         }'
      end

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
