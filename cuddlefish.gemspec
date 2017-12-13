# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cuddlefish/version'

Gem::Specification.new do |spec|
  spec.name          = "cuddlefish"
  spec.version       = Cuddlefish::VERSION
  spec.authors       = ["Dennis Taylor"]
  spec.email         = ["dennis.taylor@clio.com"]

  spec.summary       = "Shard Rails apps by using multiple database connections"
  spec.description   = "A library for sharding Rails apps. You specify a list of databases and some tags for each, then pick the database you want at runtime by specifying which tags a particular piece of code should match."
  spec.homepage      = "https://github.com/fimmtiu/cuddlefish"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rerun"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "mysql2", "~> 0.4"
  spec.add_development_dependency "database_cleaner"

  spec.add_runtime_dependency "rails", "~> 4.0"
end
