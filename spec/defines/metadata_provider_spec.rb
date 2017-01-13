require 'spec_helper'

describe 'shibboleth_idp::metadata::provider', :type => :define do
  let(:title) { 'TestSP' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(:environment => 'test', :root_home => '/root', :service_provider => 'systemd')
      end

      describe 'file resource with defaults' do
        let :pre_condition do
          'class{"shibboleth_idp":
              shib_install_base => "/junk/path"
           }'
        end

        it { is_expected.to compile.with_all_deps }

        context 'with defaults' do

          it do
            should contain_file('/junk/path/metadata/TestSP-metadata.xml').with(
              :source => '/TestSP-metadata.xml'
            )
          end

        end

        context 'with source_path => /file/source' do
          let(:params) { { :source_path => '/file/source' } }

          it do
            should contain_file('/junk/path/metadata/TestSP-metadata.xml').with(
              :source => '/file/source/TestSP-metadata.xml'
            )
          end
        end
      end
    end
  end
end