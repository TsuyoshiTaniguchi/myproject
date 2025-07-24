# -*- encoding: utf-8 -*-
# stub: google_maps_service_ruby 0.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "google_maps_service_ruby".freeze
  s.version = "0.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/langsharpe/google-maps-services-ruby/issues", "changelog_uri" => "https://raw.githubusercontent.com/langsharpe/google-maps-services-ruby/master/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/google_maps_service_ruby", "homepage_uri" => "https://github.com/langsharpe/google-maps-services-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Lang Sharpe".freeze]
  s.date = "2025-02-23"
  s.description = "Google Maps API Client, including the Routes API, Directions API, Distance Matrix API, Geocoding API and Places API. google_maps_service_ruby is a fork of google_maps_service, which is a fork of google-maps-services-python.".freeze
  s.email = ["langer8191@gmail.com".freeze]
  s.homepage = "https://github.com/langsharpe/google-maps-services-ruby".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Google Maps API Client".freeze

  s.installed_by_version = "3.3.7" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.15"])
    s.add_runtime_dependency(%q<retriable>.freeze, ["~> 3.1"])
    s.add_runtime_dependency(%q<base64>.freeze, [">= 0"])
    s.add_development_dependency(%q<coveralls_reborn>.freeze, ["~> 0.25.0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<redcarpet>.freeze, ["~> 3.5.1"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.11"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.21"])
    s.add_development_dependency(%q<standard>.freeze, ["~> 1.16"])
    s.add_development_dependency(%q<webmock>.freeze, ["~> 3.18.1"])
    s.add_development_dependency(%q<yard>.freeze, ["~> 0.9.28"])
    s.add_development_dependency(%q<irb>.freeze, [">= 0"])
    s.add_development_dependency(%q<rdoc>.freeze, [">= 0"])
  else
    s.add_dependency(%q<multi_json>.freeze, ["~> 1.15"])
    s.add_dependency(%q<retriable>.freeze, ["~> 3.1"])
    s.add_dependency(%q<base64>.freeze, [">= 0"])
    s.add_dependency(%q<coveralls_reborn>.freeze, ["~> 0.25.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<redcarpet>.freeze, ["~> 3.5.1"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.11"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.21"])
    s.add_dependency(%q<standard>.freeze, ["~> 1.16"])
    s.add_dependency(%q<webmock>.freeze, ["~> 3.18.1"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9.28"])
    s.add_dependency(%q<irb>.freeze, [">= 0"])
    s.add_dependency(%q<rdoc>.freeze, [">= 0"])
  end
end
