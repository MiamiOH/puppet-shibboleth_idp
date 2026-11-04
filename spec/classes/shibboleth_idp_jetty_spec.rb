require 'spec_helper'

describe 'shibboleth_idp::jetty', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(root_home: '/root', service_provider: 'systemd')
      end

      let :pre_condition do
        'class{"shibboleth_idp":
            idp_server_name => "shibvm-idp.example.com",
            idp_entity_id => "https://shibvm-idp.miamioh.edu:21443/idp/shibboleth",
         }'
      end

      # jetty_version is intentionally site-configured by this module; supply
      # a known Jetty 9.4 version for catalogue compilation tests.
      let(:params) do
        { jetty_version: '9.4.28' }
      end

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
