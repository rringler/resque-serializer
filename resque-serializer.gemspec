# coding: utf-8
require File.expand_path('../lib/resque-serializer/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'resque-serializer'
  gem.version       = Resque::Plugins::Serializer::VERSION
  gem.authors       = ['Ryan Ringler']
  gem.email         = ['rringler@gmail.com']

  gem.summary       = 'Serializes Resque jobs'
  gem.description   = 'Ensures that only one Resque job with unique arguments is running at a time.'
  gem.homepage      = 'https://github.com/rringler/resque-serializer'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'activesupport'
  gem.add_dependency 'resque'

  gem.add_development_dependency 'bundler', '~> 1.14'
  gem.add_development_dependency 'mock_redis'
  gem.add_development_dependency 'pry-byebug'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'timecop'
end
