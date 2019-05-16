# frozen_string_literal: true

require File.expand_path('lib/resque-serializer/version', __dir__)

Gem::Specification.new do |gem|
  gem.name          = 'resque-serializer'
  gem.version       = Resque::Plugins::Serializer::VERSION
  gem.authors       = ['Ryan Ringler']
  gem.email         = ['rringler@gmail.com']

  gem.summary       = 'Serializes Resque jobs'
  gem.description   = 'Ensures that only one Resque job with unique arguments is running at a time.'
  gem.homepage      = 'https://github.com/rringler/resque-serializer'
  gem.license       = 'MIT'

  gem.files         = `git ls-files -z`.split("\x0").reject do |file|
    file.match(/^(test|spec|features)/)
  end

  gem.bindir        = 'bin'
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency 'activesupport', '~> 4.0'
  gem.add_dependency 'resque', '~> 1.0'

  gem.add_development_dependency 'bump', '~> 0.7'
  gem.add_development_dependency 'bundler', '~> 2.0'
  gem.add_development_dependency 'mock_redis'
  gem.add_development_dependency 'pry-byebug'
  gem.add_development_dependency 'pry-stack_explorer'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'reek'
  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'rubocop'
  gem.add_development_dependency 'rubocop-performance'
end
