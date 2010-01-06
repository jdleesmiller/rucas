# -*- ruby -*-

require 'rubygems'
require 'hoe'
require 'erb'

Hoe.spec 'rucas' do |spec|
  developer('John Lees-Miller', 'jdleesmiller@gmail.com')
  spec.description = 'The beginnings of a computer algebra system in ruby.'
  spec.remote_rdoc_dir = '' # release to root
  extra_deps << ['facets']
end

desc "docs with yard"
task :yard do
  system "yardoc -o yard --main README.txt"
end

desc "run bin/rucas"
task :run do
  system "/usr/bin/ruby1.8 -w -Ilib:ext:bin:test -rubygems bin/rucas"
end

desc "patch manifest"
task :patch_manifest do
  system "rake check_manifest | grep -v \"^(in \" | patch"
end

file "README.txt" => "README.txt.erb" do |t|
  for d in %w(lib bin)
    $: << File.join(File.expand_path(File.dirname(__FILE__)), d)
  end
  File.open(t.name, 'w') do |f|
    f.puts(ERB.new(File.read(t.prerequisites.first)).result)
  end
end 
task :docs => "README.txt"

# vim: syntax=ruby
