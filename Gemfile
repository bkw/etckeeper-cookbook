source 'https://rubygems.org'

gem 'berkshelf', '~> 3.1.5'

group :integration do
  gem 'test-kitchen', '~> 1.0'
  gem 'kitchen-vagrant'
  gem 'serverspec', '~> 2.1.0'
end

group :test do
  gem 'rake'
  gem 'chefspec',   '~> 4.1.1'
  gem 'rubocop',    '~> 0.26.1'
  gem 'foodcritic', '~> 4.0'
  gem 'coveralls',  require: false
end

group :openstack do
  gem 'kitchen-openstack'
end
