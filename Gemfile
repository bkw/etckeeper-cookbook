source 'https://rubygems.org'

gem 'berkshelf', '~> 3.2.2'

group :integration do
  gem 'test-kitchen', '~> 1.2.1'
  gem 'kitchen-vagrant'
  gem 'serverspec', '~> 2.7.1'
end

group :test do
  gem 'rake'
  gem 'chefspec',   '~> 4.2.0'
  gem 'rubocop',    '~> 0.28.0'
  gem 'foodcritic', '~> 4.0'
  gem 'coveralls',  require: false
end

group :openstack do
  gem 'kitchen-openstack'
end
