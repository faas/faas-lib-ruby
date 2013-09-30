$:.push File.expand_path('../lib', __FILE__)
require 'faas/version'

Gem::Specification.new do |spec|
  spec.name = 'faas'
  spec.version = Faas::VERSION.dup
  spec.summary = 'Simplified integration with cloud services'
  spec.description = 'Simplified integration with cloud services'
  spec.email = 'devops@faas.io'
  spec.authors = ['Steven Bull']
  spec.homepage = 'http://github.com/faas/faas-lib-ruby'

  spec.files = `git ls-files`.split("\n")

  spec.add_runtime_dependency('faraday', '~> 0.8')
  spec.add_runtime_dependency('multi_json', '~> 1.0')
end
