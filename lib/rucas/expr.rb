module Rucas
  #
  # Symbolic expression; subclasses represent various kinds of expressions.
  # These are used to construct trees from ruby expressions.
  #
  module Expr
    # Children in the expression tree, if any. For example, an AddExpr returns
    # its left and right operands (x and y in x + y).
    def children; [] end

    # Operator precedence; this reflects Ruby's built-in order-of-operations
    # rules. You should not rely on the particular values; only the ordering
    # they define is guaranteed. 
    def precedence; 0 end

    # String representation including all parentheses; by default, +to_s+
    # omits parentheses when operator precedence rules allow.
    def to_s_paren; to_s end

    # Make expressions like "1 + x" work -- there is no suitable + method on
    # Fixnum, but Ruby calls <tt>x.coerce(1)</tt> so we can intervene.
    def coerce lhs
      [Expr.make(lhs), self]
    end

    # If this expression involves only constants, evaluate it and return the
    # result; if it is not, return nil.
    def value
      nil # see subclasses
    end

    # Construct expression to wrap +e+, if necessary.
    def self.make e
      return e                  if e.is_a?(Expr)
      return LiteralExpr.new(e) if e.is_a?(Numeric)
      raise "#{e} is not a numeric constant or a symbolic expression"
    end
  end

  # Anonymous numeric constant (e.g. 1 or 4.2).
  LiteralExpr = Struct.new(:value)
  class LiteralExpr
    include Expr

    def to_s; value.to_s end
  end

  # Named numeric constant (e.g. E or PI).
  ConstExpr = Struct.new(:name, :value)
  class ConstExpr 
    include Expr

    def to_s; name.to_s end
  end

  # Variable (literal).
  VarExpr = Struct.new(:name)
  class VarExpr
    include Expr

    def to_s; name.to_s end
  end

  #
  # Expression with an operator and operand(s).
  #
  module OpExpr
    include Expr

    #
    # The operators on the same line have the same precedence; the list is
    # from highest precedence to lowest precedence. This list is from the
    # Pickaxe book ("The Ruby Language").
    #
    op_precedence_table =
      [%w(**),
       %w(~@ +@ -@),
       %w(* / %),
       %w(+ -),
       %w(&),
       %w(^ |),
       %w(<= < > >=),
       %w(=~)]

    #
    # Operator precedence; you shouldn't rely on the numbers, but (barring
    # changes to Ruby), the order shouldn't change. 
    #
    OP_PRECEDENCE = Hash[*op_precedence_table.
      zip((1..op_precedence_table.size).to_a).
      map{|ops,prec| ops.map{|op| [op.to_sym, -prec]}}.flatten]

    #
    # Precedence (in Ruby) of this operator; this affects how expressions are
    # parenthesized.
    #
    def precedence
      OP_PRECEDENCE[self.op]
    end
  end

  #
  # Unary operations.
  #
  UnaryOpExpr = Struct.new(:op, :rhs)
  class UnaryOpExpr
    include OpExpr

    def children; [rhs] end
    
    def to_s_paren
      "#{self.op}(#{self.rhs.to_s_paren})"
    end
  end

  class PosExpr < UnaryOpExpr
    def to_s; rhs.to_s end
  end

  class NegExpr < UnaryOpExpr
    def to_s; rhs.precedence < self.precedence ? "-(#{rhs})" : "-#{rhs}" end
  end

  UNARY_OPS = {
    :+@  => :PosExpr,
    :-@  => :NegExpr,
    :~@  => :NotExpr,
  }

  for op, op_class in UNARY_OPS
    class_eval %Q{
      class #{op_class}
        def initialize(rhs)
          self.op, self.rhs = :#{op}, rhs
        end
      end
    }
  end

  module Expr
    for op, op_class in UNARY_OPS
      class_eval %Q{
        def #{op} ; #{op_class}.new(self) end
      }
    end
  end

  #
  # Binary operations.
  #
  BinaryOpExpr = Struct.new(:op, :lhs, :rhs)
  class BinaryOpExpr 
    include OpExpr

    def children; [lhs, rhs] end

    def to_s_paren
      op_string = " #{self.op} "
      "(#{self.children.map{|c| c.to_s_paren}.join(op_string)})"
    end

    def to_s
      inner = self.children.map{|c|
        c.precedence < self.precedence ? "(#{c})" : c.to_s}
      "#{inner.join(self.op_string)}"
    end

    protected
    # Allow for control of spacing between operands.
    def op_string; " #{self.op} " end
  end

  # Arithmetic
  class ArithmeticOpExpr < BinaryOpExpr ; end
  class AddExpr < ArithmeticOpExpr; end
  class SubExpr < ArithmeticOpExpr; end
  class MulExpr < ArithmeticOpExpr; end
  class DivExpr < ArithmeticOpExpr; end
  class PowExpr < ArithmeticOpExpr; end

  ARITHMETIC_OPS = {
    :+  => :AddExpr,
    :-  => :SubExpr,
    :*  => :MulExpr,
    :/  => :DivExpr,
    :** => :PowExpr
  }

  # Comparison
  class CompareOpExpr < BinaryOpExpr ; end
  class EqExpr   < CompareOpExpr ; end
  class LTExpr   < CompareOpExpr ; end
  class LTEqExpr < CompareOpExpr ; end
  class GTExpr   < CompareOpExpr ; end
  class GTEqExpr < CompareOpExpr ; end

  COMPARE_OPS = {
    :=~ => :EqExpr,   # =, == and === are all taken!
    :<  => :LTExpr,
    :<= => :LTEqExpr,
    :>  => :GTExpr,
    :>= => :GTEqExpr
  }

  # Logic -- see comments below
  class BooleanOpExpr < BinaryOpExpr ; end
  class AndExpr < BooleanOpExpr ; end
  class OrExpr  < BooleanOpExpr ; end

  BOOLEAN_OPS = {
    :&  => :AndExpr,
    :|  => :OrExpr
  }

  BINARY_OPS = ARITHMETIC_OPS.merge(COMPARE_OPS).merge(BOOLEAN_OPS)

  for op, op_class in BINARY_OPS
    class_eval %Q{
      class #{op_class}
        def initialize(lhs, rhs)
          self.lhs, self.op, self.rhs = lhs, :#{op}, rhs
        end
      end
    }
  end

  module Expr
    for op, op_class in BINARY_OPS
      class_eval %Q{
        def #{op} rhs ; #{op_class}.new(self, Expr.make(rhs)) end
      }
    end
  end

  class MulExpr
    # Reduce spacing between factors.
    def op_string; self.op.to_s end
  end

  class PowExpr
    # Reduce spacing between base and exponent.
    def op_string; self.op.to_s end
  end

  #
  # The name of a function, like "log".
  # Function names are not expressions, but, when arguments are supplied, the 
  # result is a function expression. 
  # This means that you can't write "log * 2", but you can write "log[x] * 2";
  # note that square brackets are required where one would normally use
  # parentheses ("log(x)" must be written "log[x]").
  #
  SymbolicFunction = Struct.new(:name)
  class SymbolicFunction
    def [] *arguments
      raise "function must have at least one argument" if arguments.empty?
      FunctionExpr.new(self, arguments)
    end
    def to_s; name.to_s; end
  end

  #
  # The application of {function} to {arguments}, like "log[x]".
  #
  FunctionExpr = Struct.new(:function, :arguments)
  class FunctionExpr
    include Expr

    def name
      "#{function}[#{arguments.join(', ')}]"
    end

    def children; arguments end
    def to_s; name.to_s end
  end
end
