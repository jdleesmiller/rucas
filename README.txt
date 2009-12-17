
= rucas

http://rucas.rubyforge.org

== DESCRIPTION

The beginnings of a Computer Algebra System in ruby.
Supports basic simplification of symbolic expressions over the real numbers.
Expressions can be entered and manipulated using standard ruby.

This is at a very early stage; many things may change.

== SYNOPSIS

  require 'rubygems'
  require 'rucas'

  include Rucas

  # basic algebraic simplification
  with_rucas {
    var :x
    var :y
    ((x + 1 - x)**y).simplify
  }.to_s                  #=> "1"

  # manipulate symbols using standard ruby code
  with_rucas {
    var :x
    var :y
    var :z
    foo = [x,y,z].inject {|s,e| s + e}
    foo ** 2
  }.to_s                  #=> "(x + y + z)**2"

  # build symbolics into ruby objects
  class Foo
    include Rucas::Symbolic
    def initialize
      var :p
      var :q
    end

    def bar
      (p + 1) / (q - p)
    end
  end
  Foo.new.bar.to_s        #=> "(p + 1) / (q - p)"

  # build expression trees
  with_rucas {
    var :p
    1 + p
  }                       #=> #<struct Rucas::Symbolic::AddExpr op=:+,
                              lhs=#<struct Rucas::Symbolic::ConstExpr value=1>,
                              rhs=#<struct Rucas::Symbolic::VarExpr name=:p>>

== NOTES

* Run an interactive session with the +rucas+ command; the interactive rucas is built on irb.
* The implementation is based on the source code for Norvig's Paradigms of AI Programming (PAIP), but rucas is not yet as complete as the macsyma in Norvig's book.

== PROBLEMS

* Simplification is quite dumb, because it doesn't understand much about commutativity and associativity.
* Doesn't do differentiation or integration (but could in the future).
* Doesn't support special functions (but could in the future).
* Doesn't integrate with other CAS systems (e.g. maxima) (but could in the future).
* Doesn't do anything with logical conditions on variables (e.g. x > 0).

== RELATED PROJECTS

* Sage: http://www.sagemath.org
  * immeasurably better than rucas in (almost) every way, at present.
* ruby symbolic: http://github.com/brainopia/symbolic
  * pretty much the same idea, but it started a few weeks before rucas, and it's being developed much more rapidly!
* Mathematics on Ruby: http://blade.nagaokaut.ac.jp/~sinara/ruby/math
  * one- and multi-variate polynomials, rationals, finite sets and maps.

== INSTALL

On *nix systems,

  sudo gem install rucas

should do it.

To run the interactive rucas, you should just be able to type +rucas+. If it doesn't work, you may need to change your PATH settings. The procedure for this is currently to run
  gem env
and look at the EXECUTABLE DIRECTORY; then run
  echo $PATH
and make sure that the executable directory is on your path. If it's not, you will have to add it (search for "add directory to path").

== LICENSE

Copyright (c) 2009 John Lees-Miller

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

