# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rubber}
  s.version = "0.0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tymon Tobolski"]
  s.date = %q{2009-05-29}
  s.default_executable = %q{rubber}
  s.description = %q{Edytor szablonów Joggera}
  s.email = %q{i@teamon.eu}
  s.executables = ["rubber"]
  s.files = ["LICENSE", "README.markdown", "Rakefile", "bin/rubber", "lib/content.yml.sample", "lib/new_entry.html.sample", "lib/rubber.rb", "lib/server.ru"]
  s.homepage = %q{http://blog.teamon.eu/projekty/}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{Edytor szablonów Joggera}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mechanize>, [">= 0.9.0"])
      s.add_runtime_dependency(%q<thin>, [">= 0"])
      s.add_runtime_dependency(%q<ezcrypto>, [">= 0.7.0"])
    else
      s.add_dependency(%q<mechanize>, [">= 0.9.0"])
      s.add_dependency(%q<thin>, [">= 0"])
      s.add_dependency(%q<ezcrypto>, [">= 0.7.0"])
    end
  else
    s.add_dependency(%q<mechanize>, [">= 0.9.0"])
    s.add_dependency(%q<thin>, [">= 0"])
    s.add_dependency(%q<ezcrypto>, [">= 0.7.0"])
  end
end
