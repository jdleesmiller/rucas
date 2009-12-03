require 'rucas/symbolic'
require 'facets/dictionary'

module Rucas
  #
  # Tools for recursively rewriting expressions based on rules.
  #
  module Rewrite
    #
    # Construct an ordered hash of rewrite rules.
    #
    # Example:
    #  my_rules = make_rules {
    #    var :x
    #    rule x + 0 => x
    #    rule 0 + x => x
    #  }
    #
    def self.make_rules &block
      s = Scope.new
      class <<s
        def dict
          @dict ||= Dictionary[]
        end
        def rule rule
          raise unless rule.size == 1
          dict[rule.keys.first] = Symbolic::Expr.make(rule.values.first)
        end
      end
      s.rucas(&block)
      s.dict
    end
  end

  module Symbolic
    module Expr
      #
      # If this expression matches +pattern+, return +output+ (with appropriate
      # bindings of variables in pattern applied to output); otherwise, return
      # self (or an object == to self).
      #
      def rewrite pattern, output
        bindings = pattern.match(self)
        return output.with(bindings) if bindings
        self
      end

      #
      # Non-recursive matching. Here, self is a pattern and +expr+ is the input
      # to be matched against this pattern. Returns bindings for the free
      # variables in self that make the match succeed, or nil if there is no
      # such match.
      #
      def match expr, bindings = {}
        nil # see subclasses
      end

      #
      # If this expression involves only constants, evaluate it and return the
      # result; if it is not, return nil.
      #
      def value
        nil # see subclasses
      end
    end

    module OpExpr
      def rewrite pattern, output
        # Rewrite children first. 
        new_children = self.children.map{|c| c.rewrite(pattern, output)}
        new_self = self.class.new(*new_children)
        # See if it's a constant.
        v = new_self.value 
        if v
          Symbolic::Expr.make(v)
        else
          # It's not a constant; try to rewrite using the rule.
          bindings = pattern.match(new_self)
          return output.with(bindings) if bindings
          new_self
        end
      end

      def with bindings
        self.class.new(*self.children.map{|c| c.with(bindings)})
      end
    end
    
    class ConstExpr
      def match expr, bindings = {}
        return bindings if self == expr
        return nil
      end

      def with bindings
        self
      end
    end

    class VarExpr
      def match expr, bindings = {}
        binding = bindings[self]
        return bindings.merge(self => expr) if !binding
        return bindings                     if binding == expr
        return nil
      end

      def with bindings
        bindings[self] || self
      end
    end

    class UnaryOpExpr
      def match expr, bindings = {}
        return nil unless expr.is_a?(UnaryOpExpr)
        return nil unless self.op == expr.op
        rhs.match(expr.rhs, bindings)
      end

      def value
        v = rhs.value
        eval "(#{v}).#{self.op}" if v
      end
    end

    class BinaryOpExpr
      def match expr, bindings = {}
        if expr.is_a?(BinaryOpExpr) && self.op == expr.op
          lb = self.lhs.match(expr.lhs, bindings)
          rb = self.rhs.match(expr.rhs, lb) if lb
          return rb if rb
        end
        nil
      end

      def value
        lv = lhs.value
        rv = rhs.value
        eval "(#{lv})#{self.op}(#{rv})" if lv && rv
      end
    end
  end
end

#    module Expr
    #  def simplify bindings={}, rules=DEFAULT_SIMPLIFY_RULES
    #    for rule in rules
    #      new_bindings = self.match(rule.lhs, bindings)
    #      return rule.rhs.with(new_bindings).simplify(bindings,rules) if
    #        new_bindings
    #    end
    #  end

      # rule: pair of expressions, which may refer to matchers
      # matcher: name, predicate block
      # bindings: map from matcher to expression
      # the result of matching an expression with another expression should be
      # false if the match fails, or it should return bindings for the matchers
      # that make the match succeed.
      # note: match is not commutative; it's probably easiest if we return
      # bindings for the lhs (self), since most of the tricky stuff then goes
      # into VarExpr. This isn't maximally rubyish: "foo" =~ /foo/ -- the
      # pattern comes last -- but /foo/.match("foo") is also valid.
      # note: a convention is also required for handling things like
      # (x + y).match(a - b) -- this could succeed with x => a, y => -b, but it
      # requires more checks -- can't just check op of root. 
    #  def match expr
#
#      end
#    end
    #
    # Simplification isn't really recursive (in the tree structure) -- we have
    # to apply a list of rules, and we restart when the current rule matches
    # any part of the expression tree.
    # The simplification process for one rewrite rule could be recursive: do a
    # post-order traversal, rewriting children; at the top level, we just
    # compare the whole resulting expression with the original to see if
    # anything's changed.
    # The match is then non-recursive.
    #

