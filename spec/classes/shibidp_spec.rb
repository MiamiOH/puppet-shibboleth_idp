require 'spec_helper'

describe 'shibidp', :type => :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:environment => 'test', :root_home => '/root', :service_provider => 'systemd')
      end

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('shibidp::install') }
        it { is_expected.to contain_class('shibidp::relying_party') }
        it { is_expected.to contain_class('shibidp::metadata') }
        it { is_expected.to contain_class('shibidp::attribute_resolver') }
        it { is_expected.to contain_class('shibidp::attribute_filter') }
        it { is_expected.to contain_class('shibidp::jetty') }
      end
    end
  end
end
