require "test/unit"
require "rucas"

class TestRucas < Test::Unit::TestCase
  include Rucas
  include Rucas::Symbolic

  def setup
    # Some variables to play with.
    @s = Scope.new
    @s.rucas {
      var :x
      var :y
      var :z
      var :a
      var :b
    }
  end

  # Shorthand for "assert expression equal to string;" block is evaluated in the
  # scope +@s+.
  def axes string, &block
    assert_equal string, @s.rucas(&block).to_s
  end

  # Shorthand for "assert expression equal to string when simplified;" block is
  # evaluated in the scope +@s+.
  def axes_simplify string, &block
    assert_equal string, @s.rucas(&block).simplify.to_s
  end

  # Variables in subscope don't appear in parent scope.
  def test_scopes
    s0 = Scope.new
    s0.rucas {
      var :a
      var :b
    }
    s1 = s0.subscope
    s1.rucas {
      var :c
    }
    assert  s0.respond_to?(:a)
    assert  s0.respond_to?(:b)
    assert !s0.respond_to?(:c)
    assert  s1.respond_to?(:a)
    assert  s1.respond_to?(:b)
    assert  s1.respond_to?(:c)
  end

  # Basic operations; human-readable string conversions.
  def test_arithmetic
    s = Scope.new; s.rucas { var :p; var :q }
    assert_equal "p + q", s.rucas{ p + q }.to_s
    assert_equal "p - q", s.rucas{ p - q }.to_s
    assert_equal "(p + q)*(p - q)", s.rucas{ (p + q)*(p - q) }.to_s
    assert_equal "(p + q) / (p - q)", s.rucas{ (p + q)/(p - q) }.to_s
    assert_equal "(p + q)**2", s.rucas{ (p + q)**2 }.to_s
    assert_equal "(p + q)**(q + 1)", s.rucas{ (p + q)**(q + 1) }.to_s
  end

  def test_unary_operators
    axes("-x + 1")  { -x + 1 }
    axes("1 + -x")  { 1 + -x }
    axes("1 - -x")  { 1 - -x }
    axes("x + 1")   { +x + 1 }
    axes("1 + x")   { 1 + +x }
  end

  # Simplification identities.
  def test_simplify_add
    axes_simplify("x")         {x}
    axes_simplify("x + y")     {x + y}
    axes_simplify("x + y + z") {x + y + z}
    axes_simplify("x")         {x + 0}
    axes_simplify("x")         {0 + x}
    axes_simplify("1 + x")     {1 + x + 0}
    axes_simplify("x + 1")     {0 + x + 1}
    axes_simplify("1 + x + y") {1 + x + 0 + y}
    axes_simplify("y + x + 1") {y + 0 + x + 1}
  end

  # Simplification identities.
  def test_simplify_sub
    axes_simplify("x - y")     {x - y}
    axes_simplify("-x")        {0 - x}
    axes_simplify("x")         {x - 0}
    axes_simplify("1")         {x + 1 - x}
    axes_simplify("-1")        {x - 1 - x}
  end

  # Simplification identities.
  def test_simplify_mul
    axes_simplify("x*y")     {x*y}
    axes_simplify("x")       {x*1}
    axes_simplify("x")       {1*x}
    axes_simplify("0")       {x*0}
    axes_simplify("0")       {0*x}
  end

  # Simplification identities.
  def test_simplify_div
    axes_simplify("x / y")     {x/y}
    axes_simplify("x")         {x/1}
    axes_simplify("1")         {y/y}
    axes_simplify("NaN")       {x/0}
  end

  # Simplification identities.
  def test_simplify_exp
    axes_simplify("x**y")     {x**y}
    axes_simplify("1")        {x**0}
    axes_simplify("1")        {Expr.make(0)**0} # at least according to Ruby
    axes_simplify("1")        {0**Expr.make(0)} # at least according to Ruby
    axes_simplify("1 / x")    {x**-1}
  end

  # Some other tests.
  def test_simplify_misc
    axes_simplify("a")              {x + a*1 - x}
    axes_simplify("0")              {x + a/1 - x - a}
    axes_simplify("x**2 + 2*x + 1") {x*x + x + x + 1}
    axes_simplify("1 + 2*x + x**2") {1 + x + x + x*x}
    axes_simplify("1")              {2 ** (x - y - x + y)}
    axes_simplify("y*x**2")         {y*x*x}
  end

  def test_constants
    assert_equal nil, @s.rucas {(x + 1).value}
    assert_equal 3, @s.rucas {(x + 1).with(x => 2).value}
    axes_simplify("x + 2")          {(x + 1) + 1}
    axes_simplify("x + 3")          {(x + 1) + 2}
  end

  # The tests from Norvig's Paradigms of AI Programming.
  def test_paip
    # 8.2: Simplification Rules
    axes_simplify("4")              {2 + 2}
    axes_simplify("137")            {5 * 20 + 30 + 7}
    axes_simplify("0")              {5 * x - (4 + 1) * x}
    axes_simplify("0")              {y / z * (5 * x - (4 + 1) * x)}
    axes_simplify("x")              {(4 - 3) * x + (y / y - 1) * z}
    # ((simp '(1 * f(x) + 0)) => (F X) )
    
    # 8.3 Associativity and Commutativity
    # NB: the rest of these PAIP tests fail -- see "things that don't simplify"
    axes_simplify("6*x")            {3 * 2 * x}
    
    # There are some more when we support logs, trig and differentiation
  end

  def test_unpatch
    # Patches are initially applied; unapply and then reapply.
    Rucas::Extensions.unapply
    assert_raise(TypeError) { with_rucas { var :x; 1 + x } }
    Rucas::Extensions.apply
    assert_equal "1 + x",     with_rucas { var :x; 1 + x }.to_s
    # Do it again to make sure it's really reversible.
    Rucas::Extensions.unapply
    assert_raise(TypeError) { with_rucas { var :x; 1 + x } }
    Rucas::Extensions.apply
    assert_equal "1 + x",     with_rucas { var :x; 1 + x }.to_s
  end

  def test_match
    s = Scope.new;
    s.rucas {
      var :x
      var :y
      var :a
      var :b
    }

    # Single match.
    binding = s.rucas{ x.match(1) }
    assert_equal 1, binding[s.x]
    binding = s.rucas{ x.match(a) }
    assert_equal s.a, binding[s.x]
    binding = s.rucas{ x.match(-a) }
    assert_equal(-s.a, binding[s.x])
    binding = s.rucas{ x.match(b) }
    assert_equal s.b, binding[s.x]
    binding = s.rucas{ x.match(a + b) }
    assert_equal s.a + s.b, binding[s.x]

    # Expression matches with distinct variables.
    binding = s.rucas {(x + y).match(a + 1)}
    assert_equal s.a, binding[s.x]
    assert_equal "1", binding[s.y].to_s
    binding = s.rucas {(x + y).match(a + 1)}
    assert_equal "1", binding[s.y].to_s

    # Matching is left-associative. 
    binding = s.rucas {(x + y).match(a + b + 1)}
    assert_equal "a + b", binding[s.x].to_s
    assert_equal "1", binding[s.y].to_s

    # Expression matches with repeated variable.
    binding = s.rucas {(x + x).match(a + a)}
    assert_equal s.a, binding[s.x]
    binding = s.rucas {(x + x).match(a + b)}
    assert !binding
    binding = s.rucas {(x + x).match(1 + 1)}
    assert !binding # minor gotcha

    # Expression matches with constants.
    binding = s.rucas {(x + 0).match(a + 0)}
    assert_equal s.a, binding[s.x]
    binding = s.rucas {(0 + x).match(a + 0)}
    assert !binding
    binding = s.rucas {(0 + x).match(0 + a + 1)}
    assert !binding # matching is not currently recursive
    binding = s.rucas {(0 + x).match(0 + (a + 1))}
    assert_equal s.a + 1, binding[s.x]
  end
end
