# encoding: UTF-8

require 'spec_helper'

describe 'etckeeper_git::enable' do
  describe file('/etc/etckeeper/etckeeper.conf') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 644 }
    its(:content) { should match(/VCS="git"/) }
    author = Regexp.escape('Etckeeper <root@etckeeper.example.com>')
    its(:content)  do
      should match(/^GIT_COMMIT_OPTIONS="--author '#{author}'"$/)
    end
  end

  describe file('/etc/cron.daily/etckeeper') do
    it { should be_file }
    its(:sha256sum) do
      should eq(
        '25009cd49c35a8a35996b53a7ae16012f89308088f19e4718efc6dfad94dbae2'
      )
    end
  end

  describe file('/etc/.git') do
    it { should be_directory }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 700 }
  end

  describe file('/etc/.git/config') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    it { should be_mode 644 }
  end
end
