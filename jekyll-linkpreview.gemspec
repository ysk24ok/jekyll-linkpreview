
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jekyll-linkpreview/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-linkpreview"
  spec.version       = Jekyll::Linkpreview::VERSION
  spec.authors       = ["Yusuke Nishioka"]
  spec.email         = ["yusuke.nishioka.0713@gmail.com"]

  spec.summary       = %q{Jekyll tag plugin to generate link preview}
  spec.homepage      = "https://github.com/ysk24ok/jekyll-linkpreview"
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", "~> 3.5"
  spec.add_dependency "metainspector"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
