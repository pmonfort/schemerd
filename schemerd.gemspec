# frozen_string_literal: true

require_relative "lib/schemerd/version"

Gem::Specification.new do |spec|
  spec.name          = "schemerd"
  spec.version       = Schemerd::VERSION
  spec.authors       = ["Pablo Monfort"]
  spec.summary       = "Generate Mermaid ER diagrams from ActiveRecord models"
  spec.description   = "Auto-generate Mermaid ERD markdown files from your ActiveRecord schema. " \
                        "Hooks into db:migrate to keep diagrams in sync."
  spec.homepage      = "https://github.com/pablo/schemerd"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.files         = Dir["lib/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.0"
  spec.add_dependency "railties", ">= 6.0"
end
