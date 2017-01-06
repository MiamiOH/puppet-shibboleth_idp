require 'spec_helper'

describe 'shibidp::simplesp', :type => :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:environment => 'test', :root_home => '/root', :service_provider => 'systemd')
      end

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
