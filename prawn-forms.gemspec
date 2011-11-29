PRAWN_FORMS_VERSION = "0.1.1"

Gem::Specification.new do |spec|
  spec.name = "prawn-forms"
  spec.version = PRAWN_FORMS_VERSION
  spec.platform = Gem::Platform::RUBY
  spec.summary = "A fast and nimble PDF generator for Ruby"
  spec.files = Dir.glob("{examples,lib,data}/**/**/*") +
                      ["prawn-forms.gemspec"]
  spec.require_path = "lib"
  spec.required_ruby_version = '>= 1.8.7'
  spec.required_rubygems_version = ">= 1.3.6"

  spec.extra_rdoc_files = %w{CHANGELOG README.markdown MIT-LICENSE}
  spec.add_dependency('prawn', '1.0.0.rc1')
end
