#
# Elementary math functions and constants, such as exp, log and pi.
#
# TODO add sin, cos, etc.
#

#
#
#

module Rucas
  module Symbolic
    const :e, Math::E
    const :pi, Math::PI

    symfun :log
    symfun :exp
  end

  Rewrite.append_rules_to(Simplify::RULES) {
    var :x
    var :y
    nan = Expr.make(0.0/0.0)

    rule( log[1]      => 0    )
    rule( log[0]      => nan  )
    rule( log[e]      => 1    )
    rule( log[exp[x]] => x    )
    rule( exp[log[x]] => x    )

    rule( log[x] + log[y] => log[x * y] )
    rule( log[x] - log[y] => log[x / y] )
  }
end
