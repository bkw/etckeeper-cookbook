# encoding: UTF-8

require 'spec_helper'

describe 'etckeeper_git::enable' do

  cached(:chef_run) do
    ChefSpec::SoloRunner.new.converge(described_recipe)
  end

  it 'creates the etckeeper config directory' do
    expect(chef_run).to create_directory('/etc/etckeeper')
      .with(owner: 'root')
      .with(group: 'root')
      .with(recursive: true)
      .with(mode: '0755')
  end

  it 'creates the etckeeper config file' do
    expect(chef_run).to render_file('/etc/etckeeper/etckeeper.conf')
  end

  it 'creates the etckeeper cron job by default' do
    expect(chef_run).to create_template('/etc/cron.daily/etckeeper')
      .with(owner: 'root')
      .with(mode: '0755')
    expect(chef_run).to render_file('/etc/cron.daily/etckeeper')
      .with_content(/etckeeper commit "daily autocommit"/)
  end

  it 'does not create a etckeeper_git_remote resource by default' do
    expect(chef_run).not_to create_etckeeper_git_remote(//)
  end

  context 'with attribute avoid_daily_auto_commits set to true' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.set['etckeeper_git']['avoid_daily_auto_commits'] = true
      end.converge(described_recipe)
    end

    it 'does not install the etckeeper cron job' do
      expect(chef_run).not_to render_file('/etc/cron.daily/etckeeper')
    end
  end

  context 'without existing git repository' do
    before do
      allow(File).to receive(:exist?)
        .and_call_original
      allow(File).to receive(:exist?)
        .with('/etc/.git/config')
        .and_return(false)
    end

    cached(:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }

    it 'runs "etckeeper init"' do
      expect(chef_run).to run_execute('etckeeper init')
    end
  end

  context 'with existing git repository' do
    before do
      allow(File).to receive(:exist?)
        .and_call_original
      allow(File).to receive(:exist?)
        .with('/etc/.git/config')
        .and_return(true)
    end

    cached(:chef_run) do
      ChefSpec::SoloRunner.new.converge(described_recipe)
    end

    it 'does not run "etckeeper init" again' do
      expect(chef_run).not_to run_execute('etckeeper init')
    end
  end
end
