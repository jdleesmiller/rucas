require 'test/unit'
require 'erb'
require 'rucas'

ROOT = File.expand_path(File.join(File.dirname(__FILE__),".."))

# stolen from http://stackoverflow.com/questions/1536602
# works only on Linux
RUBY = `ls -al /proc/#{$$}/exe`.split(" ")[-1]

#
# Tests for the development environment. This file should not be in the Manifest
# for the gem.
#
class TestDevEnv < Test::Unit::TestCase
  #
  # Just run the README ERB template to make sure we didn't introduce any
  # obvious errors.
  #
  def test_readme_erb
    # This doesn't work on 1.8.6, and it doesn't really have to.
    if RUBY_VERSION != '1.8.6'
      ERB.new(File.read(File.join(ROOT, "make_readme.erb"))).result
    end
  end

  #
  # Make sure the interactive shell is working.
  #
  def test_interactive_rucas
    cmd = "#{RUBY} -w -Ilib:ext:bin:test -rubygems bin/rucas"
    output = IO.popen(cmd, 'r+') {|p|
      p.puts "rucas_help"
      p.close_write
      p.read
    }
    expected = <<EXPECTED
-- interactive rucas --
To exit, type exit or quit.
For help, type rucas_help.
rucas:001:0> rucas_help
Interactive rucas is based on the standard Interactive Ruby (irb).
Declare symbolic variables using var.
Then you can manipulate them using standard Ruby code.

Examples:
> var :x
   #=> #<struct Rucas::VarExpr name=:x>
> var :y
   #=> #<struct Rucas::VarExpr name=:y>
> var :z
   #=> #<struct Rucas::VarExpr name=:z>
> (x + 1 - x).simplify.to_s
   #=> "1"
> [x, y, z].sum.to_s
   #=> "x + y + z"

You can use underscore (_) to get the result of the last command.
nil
rucas:002:0> 
EXPECTED
    assert_equal expected.strip, output.strip
  end
end
