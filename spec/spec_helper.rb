# encoding: UTF-8

require 'chefspec'
require 'chefspec/server'
require 'chefspec/berkshelf'
require 'chefspec/cacher'
require 'coveralls'

RSpec.configure do |config|
  config.platform = 'ubuntu'
  config.version = '14.04'
  config.log_level = :error
end

at_exit do
  ChefSpec::Coverage.report!
  Coveralls.wear!
end
