module Rucas
  #
  # Simplification; this is still fairly primitive.
  #
  # things that don't simplify:
  # Examples from PAIP 8.3: commutativity and associativity
  #  {3*(2*x)}
  #  {2 * x * x * 3}
  #  {2 * x * 3 * y * 4 * z * 5 * 6}
  #  {3 + x + 4 + x}
  #  {2 * x * 3 * x * 4 * (1 / x) * 5 * 6}
  # 
  module Simplify
    #
    # Ordered hash of simplification rules.
    #
    # The order of the rules is very important for avoiding unsoundness due to
    # division by zero, for example.
    #
    # Note that division by zero always results in a NaN. If it were possible to
    # prove that x was strictly positive (negative), x / 0 should arguably
    # evaluate to +Inf (-Inf), but this is substantially beyond what we can do
    # at this point.
    # 
    RULES = Rewrite.make_rules {
      var :w
      var :x
      var :y
      z = Expr.make(0)
      nan = Expr.make(0.0/0.0)

      # These rules are taken from Norvig's Paradigms of AI Programming
      # (chapter 8). The source for that book is freely available.
      rule( x + 0  => x   )
      rule( 0 + x  => x   )
      rule( x + x  => 2*x )
      rule( x - 0  => x   )
      rule( 0 - x  => -x  )
      rule( x - x  => 0   )
      rule( +x     => x   )
      rule( --x    => x   )
      rule( x * 1  => x   )
      rule( 1 * x  => x   )
      rule( x * 0  => 0   )
      rule( 0 * x  => 0   )
      rule( x * x  => x**2)
      rule( x / 0  => nan )
      rule( 0 / x  => 0   )
      rule( x / 1  => x   )
      rule( x / x  => 1   )
      rule( z ** 0 => 1   ) # note: Ruby says 0 ** 0 is 1; be consistent
      rule( x ** 0 => 1   )
      rule( 0 ** x => 0   )
      rule( 1 ** x => 1   )
      rule( x ** 1 => x   )
      rule( x ** -1     => 1 / x)
      rule( x * (y / x) => y    )
      rule( (y / x) * x => y    )
      rule( (y * x) / x => y    )
      rule( (x * y) / x => y    )
      rule( x + -x      => 0    )
      rule( -x + x      => 0    )
      rule( x + y - x   => y    )
      rule( x - y - x   => -y   )
      rule( (x ** y) * (x ** z) => x ** (y + z) )
      rule( (x ** y) / (x ** z) => x ** (y - z) )

      # These rules are helpful for "rebalancing" long trees, which can make
      # some of the rules above effective. This is because we don't actually
      # handle associativity properly. These rules do slow things down a bit,
      # but hopefully it doesn't break anything too badly.
      #
      # Interestingly, Norvig's "infix->prefix" functions used right-
      # associative grouping, which made things go more smoothly. For example,
      # x^2 + x + x + 1 simplifies to x^2 + 2*x + 1 without the rebalancing
      # rule, if you group from the right (but the reverse doesn't simplify).
      rule( (w + x) + y => w + (x + y) )
      rule( (w * x) * y => w * (x * y) )
    }
  end

  module Expr
    #
    # Return expression after algebraic simplification. Note that this isn't a
    # very smart simplifier.
    # 
    def simplify
      new_self = self
      changed = false
      # Rule-based simplification.
      for pattern, output in Simplify::RULES
        new_self = new_self.rewrite(pattern, output)
        #puts "#{pattern}\t#{new_self.to_s_paren}"
        changed = (new_self != self)
        break if changed
      end
      # Get rid of literals.
      unless changed
        new_self = new_self.eval_literals
        changed = (new_self != self)
      end
      if changed then new_self.simplify else self end
    end

    #
    # Recursively evaluate expressions that consist only of literals to produce
    # a literal answer; for example (x + 1 + 1 + 1).eval_literals returns x + 3.
    # Note that, if the literals are floating point numbers, this is not exact,
    # because floating point arithmetic is used.
    # If the literals are integers, Ruby guarantees that the result is exact
    # (it uses arbitrary precision integers, if necessary).
    # Named constants (e.g. E and PI) are not treated as literals.
    #
    def eval_literals
      raise NotImplementedError # this method is abstract
    end
  end

  class LiteralExpr
    def eval_literals
      self
    end
  end

  class ConstExpr
    def eval_literals
      # A named constant (e.g. e or pi) is NOT treated as a literal.
      self
    end
  end

  class VarExpr
    def eval_literals
      self
    end
  end

  class UnaryOpExpr
    def eval_literals
      new_rhs = rhs.eval_literals
      if new_rhs.is_a?(LiteralExpr)
        Expr.make(eval("(#{new_rhs}).#{self.op}")) 
      elsif new_rhs.equal?(rhs)
        self
      else
        self.class.new(new_rhs)
      end
    end
  end

  class BinaryOpExpr
    def eval_literals
      new_lhs = lhs.eval_literals
      new_rhs = rhs.eval_literals
      if new_lhs.is_a?(LiteralExpr) && new_rhs.is_a?(LiteralExpr)
        Expr.make(eval("(#{new_lhs})#{self.op}(#{new_rhs})")) 
      elsif new_lhs.equal?(lhs) && new_rhs.equal?(rhs)
        self
      else
        self.class.new(new_lhs, new_rhs)
      end
    end
  end

  class FunctionExpr
    def eval_literals
      new_arguments = arguments.map{|a| a.eval_literals}
      if arguments.zip(new_arguments).all? {|a,na| a.equal?(na)}
        self
      else
        self.class.new(function, new_arguments)
      end
    end
  end
end

