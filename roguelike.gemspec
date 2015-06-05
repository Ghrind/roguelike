# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'roguelike/version'

Gem::Specification.new do |spec|
  spec.name          = "roguelike"
  spec.version       = Roguelike::VERSION
  spec.authors       = ["Benoît Dinocourt"]
  spec.email         = ["ghrind@gmail.com"]

  spec.summary       = %q{Another attempt to a rogulike game.}
  spec.description   = %q{This project is not supposed to be a full-fledged game, instead I will test here some algorithms like a-star, procedural generation and AI.}
  spec.homepage      = "https://github.com/ghrind/roguelike"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'websocket-eventmachine-client'

  spec.add_runtime_dependency 'faye-websocket'
  spec.add_runtime_dependency 'thin'
  spec.add_runtime_dependency 'ruby_protobuf'
end
