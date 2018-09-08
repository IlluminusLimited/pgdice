# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pgdice/version'

Gem::Specification.new do |spec|
  spec.name          = 'pgdice'
  spec.version       = PgDice::VERSION
  spec.authors       = ['Andrew Newell']
  spec.email         = ['andrew@andrewcn.com illuminuslimited@gmail.com']

  spec.summary       = 'Postgres partitioning with a Ruby API!'
  spec.description   = 'Postgres partitioning with a Ruby API built on top of https://github.com/ankane/pgslice'
  spec.homepage      = 'https://github.com/IlluminusLimited/pgdice'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Locked because we depend on internal behavior for table commenting
  spec.add_runtime_dependency 'pg', '>= 0.12.2'
  spec.add_runtime_dependency 'pgslice', '0.4.4'

  spec.add_development_dependency 'activesupport', '~> 5.0.0'
  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-minitest'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'guard-shell'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'minitest-ci'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '~> 0.58'
  spec.add_development_dependency 'simplecov'
end
