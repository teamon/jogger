require 'rubygems'
require 'rake/gempackagetask'

PLUGIN = "rubber"
GEM_NAME = "rubber"
GEM_VERSION = "0.0.3"
AUTHOR = "Tymon Tobolski"
EMAIL = "i@teamon.eu"
HOMEPAGE = "http://teamon.eu/projekty/"
SUMMARY = "Edytor szablonów Joggera"

spec = Gem::Specification.new do |s|
  s.name = GEM_NAME
  s.version = GEM_VERSION
  s.has_rdoc = false
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE  
  s.require_path = 'lib'
  s.bindir = 'bin'
  s.executables = %w( rubber )
  s.files = %w( LICENSE README.textile Rakefile ) +  Dir.glob("{bin,lib}/**/*")
  s.add_dependency('mechanize', '>= 0.9.0')
  s.add_dependency('thin')
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "Create a gemspec file"
task :gemspec do
  File.open("#{GEM_NAME}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end

# development

desc 'Strip trailing whitespace from source files'
task :strip do
  Dir["#{File.dirname(__FILE__)}/**/*.rb"].each do |path|
    content = File.open(path, 'r') do |f|
      f.map { |line| line.gsub(/\G\s/, ' ').rstrip + "\n" }.join.rstrip
    end + "\n"
    
    if File.read(path) != content
      puts "Stripping whitepsace from #{path}"
      File.open(path, 'w') {|f| f.write content}
    end
  end
end


