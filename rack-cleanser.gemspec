# (c) Copyright 2017 Ribose Inc.
#

# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rack/cleanser/version"

Gem::Specification.new do |spec|
  spec.name          = "rack-cleanser"
  spec.version       = Rack::Cleanser::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "Cleanse your racks"
  spec.description   = "Cleanse your racks"
  spec.homepage      = "https://github.com/riboseinc/rack-cleanser"
  spec.license       = "MIT"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rack"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rubocop", "~> 0.49.1"
  spec.add_development_dependency "simplecov"
end
