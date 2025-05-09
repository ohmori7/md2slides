
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "md2slides/version"

Gem::Specification.new do |spec|
  spec.name          = "md2slides"
  spec.version       = Md2slides::VERSION
  spec.authors       = ["Motoyuki OHMORI"]
  spec.email         = ["ohmori@tottori-u.ac.jp"]

  spec.summary       = %q{Markdown to presentation slides in ruby.}
  spec.description   = %q{Generate Google slides and its video file from a markdown file.}
  spec.homepage      = "https://github.com/ohmori7/md2slides"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
#   spec.metadata["allowed_push_host"] = spec.homepage

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
    spec.metadata["changelog_uri"] = spec.homepage
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "googleauth"
# spec.add_dependency "google-apis-people_v1"
  spec.add_dependency "google-apis-slides_v1"
  spec.add_dependency "google-apis-drive_v3"
  spec.add_dependency "google-cloud-text_to_speech", "~>0.7.0"
  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.license	= "MIT"
end
