# encoding: utf-8

require 'spec_helper'

describe 'etckeeper_git' do
  describe package('etckeeper') do
    it { should be_installed }
  end

  describe file('/etc/.bzr') do
    it { should_not be_directory }
    it { should_not be_file }
  end
end
