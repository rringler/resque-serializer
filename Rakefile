# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'reek/rake/task'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

Reek::Rake::Task.new { |reek| reek.fail_on_error = true }
RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

task default: %i[rubocop reek spec]
