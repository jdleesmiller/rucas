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
          dict[rule.keys.first] = Expr.make(rule.values.first)
        end
      end
      s.rucas(&block)
      s.dict
    end
  end

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
  end

  module OpExpr
    def rewrite pattern, output
      # Rewrite children first; then create new op expression; then try to match
      # the pattern here.
      new_children = self.children.map{|c| c.rewrite(pattern, output)}
      new_self = self.class.new(*new_children)
      bindings = pattern.match(new_self)
      return output.with(bindings) if bindings
      new_self
    end

    def with bindings
      self.class.new(*self.children.map{|c| c.with(bindings)})
    end
  end
  
  class LiteralExpr
    def match expr, bindings = {}
      return bindings if self == expr
      return nil
    end

    def with bindings
      self
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
  end

  class FunctionExpr
    def rewrite pattern, output
      # Rewrite arguments.
      new_arguments = self.arguments.map{|a| a.rewrite(pattern, output)}
      new_self = self.class.new(self.function, new_arguments)
      bindings = pattern.match(new_self)
      return output.with(bindings) if bindings
      new_self
    end

    def with bindings
      self.class.new(self.function, self.arguments.map{|a| c.with(bindings)})
    end
  end
end

