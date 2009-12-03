require 'rucas/rewrite'

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
      z = Symbolic::Expr.make(0)
      nan = Symbolic::Expr.make(0.0/0.0)

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

  module Symbolic
    module Expr
      #
      # Return expression after algebraic simplification. Note that this isn't a
      # very smart simplifier.
      # 
      def simplify
        new_self = self
        changed = false
        for pattern, output in Simplify::RULES
          new_self = new_self.rewrite(pattern, output)
          #puts "#{pattern}\t#{new_self.to_s_paren}"
          changed = (new_self != self)
          break if changed
        end
        if changed then new_self.simplify else self end
      end
    end
  end
end

