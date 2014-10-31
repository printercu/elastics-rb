# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elastics/version'

Gem::Specification.new do |spec|
  spec.name          = 'elastics'
  spec.version       = Elastics::VERSION
  spec.authors       = ['Max Melentiev']
  spec.email         = ['melentievm@gmail.com']
  spec.summary       = 'ElasticSearch client with ActiveRecord integration'
  spec.description   = 'Lightweight and extensible elasticsearch client'
  spec.homepage      = 'http://github.com/printercu/elastics-rb'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'httpclient', '~> 2.4.0'

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.1.0'
  spec.add_development_dependency 'thread_safe', '~> 0.3.4'
  spec.add_development_dependency 'activesupport', '~> 4.1.6'
end
