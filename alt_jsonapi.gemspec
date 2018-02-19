# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'alt_jsonapi/version'

Gem::Specification.new do |spec|
  spec.name          = "alt_jsonapi"
  spec.version       = AltJsonapi::VERSION
  spec.authors       = ["Ivan Youroff"]
  spec.email         = ["ivan.youroff@gmail.com"]

  spec.summary       = %q{Alternative JSONApi serializer}
  spec.description   = %q{Alternative JSONApi serializer inspired by Netflix's fast_jsonapi serializer}
  spec.homepage      = "TODO: N/A"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activesupport", ">= 4.2"
  spec.add_development_dependency "oj", "~> 3.3"
  spec.add_development_dependency "multi_json", "~> 1.0"
  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "ffaker", "~> 2.8.1"
  spec.add_development_dependency "fast_jsonapi", "~> 1.0"
end
