require 'spec_helper'

describe 'shibboleth_idp::simplesp', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(environment: 'test', root_home: '/root', service_provider: 'systemd')
      end

      context 'with defaults' do
        let(:params) do
          {
            ss_sp_host:          'shibvm-sp.example.com',
            idp_signing_cert:    'abc123',
            idp_encryption_cert: 'xyz987',
            idp_server_url:      'https://example.com:12345',
          }
        end

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
