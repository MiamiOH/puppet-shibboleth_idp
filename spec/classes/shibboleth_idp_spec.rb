require 'spec_helper'

describe 'shibboleth_idp', :type => :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:environment => 'test', :root_home => '/root', :service_provider => 'systemd')
      end

      context 'with defaults' do
        let(:params) do
          {
            :idp_server_name => 'shibvm-idp.example.com',
            :idp_entity_id => 'https://shibvm-idp.miamioh.edu:21443/idp/shibboleth'
          }
        end
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('shibboleth_idp::install') }
        it { is_expected.to contain_class('shibboleth_idp::relying_party') }
        it { is_expected.to contain_class('shibboleth_idp::metadata') }
        it { is_expected.to contain_class('shibboleth_idp::attribute_resolver') }
        it { is_expected.to contain_class('shibboleth_idp::attribute_filter') }
      end
    end
  end
end
