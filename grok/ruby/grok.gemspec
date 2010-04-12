Gem::Specification.new do |spec|
  files = ["sample.rb", "INSTALL"]
  dirs = %w{ext test lib}
  dirs.each do |dir|
    files += Dir["#{dir}/**/*"]
  end

  svnrev = %x{svn info}.split("\n").grep(/Revision:/).first.split(" ").last.to_i
  spec.name = "grok"
  spec.version = "0.1.#{svnrev}"

  spec.summary = "grok bindings for ruby"
  spec.description = "Grok ruby bindings - pattern match/extraction tool"
  spec.add_dependency("eventmachine")
  spec.files = files
  spec.require_paths << "ext"
  spec.extensions = ["ext/extconf.rb"]

  spec.author = "Jordan Sissel"
  spec.email = "jls@semicomplete.com"
  spec.homepage = "http://code.google.com/p/semicomplete/wiki/Grok"
end
