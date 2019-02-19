# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'gerrit-seed'
  s.version     = '1.1.0'
  s.summary     = 'Seed Gerrit with sample data from a YAML file'
  s.description = 'Declarative Gerrit seeding with YAML.'
  s.executables = %w[gerrit-seed gerrit-unseed]
  s.author      = 'Ahmad Amireh'
  s.email       = 'ahmad@amireh.net'
  s.homepage    = 'https://github.com/amireh/gerrit-seed'
  s.files       = Dir['bin/*', 'lib/**/*.rb']
  s.test_files  = Dir['spec/**/*']
  s.license     = 'MIT'

  s.required_ruby_version = '~> 2.5.1'

  s.add_dependency 'json', '~> 2.1'
  s.add_dependency 'pastel', '~> 0.7'

  s.add_development_dependency 'rspec', '~> 3.8'
  s.add_development_dependency 'simplecov', '~> 0.16'
end
