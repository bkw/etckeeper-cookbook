# encoding: UTF-8

require 'spec_helper'

describe 'etckeeper_git::default' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new.converge(described_recipe)
  end

  it 'includes the git recipe' do
    expect(chef_run).to include_recipe('git')
  end

  it 'installs etckeeper' do
    expect(chef_run).to install_package('etckeeper')
  end

  it 'deletes an existing bzr directory' do
    expect(chef_run).to delete_directory('/etc/.bzr')
  end
end
