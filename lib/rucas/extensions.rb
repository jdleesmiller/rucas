require 'rucas/symbolic'

class Numeric
  # Rucas uses the =~ operator for equality expressions.
  def =~ rhs
    Expr.new(self) =~ rhs
  end

  # Try to convert to ConstExpr if can't find method (e.g. +simplify+).
  def method_missing_with_rucas method, *args, &block
    method_missing_without_rucas(method *args, &block)
  rescue NoMethodError
    error = $!
    begin
      return Rucas::Symbolic::Expr.make(self).send(method, *args, &block)
    rescue NoMethodError
      nil
    end
    raise error
  end
end

module Rucas
  module Extensions
    # Patch system classes to make constants work with vars (e.g. 0 + x).
    def self.apply
      Numeric.class_eval do
        alias_method :method_missing_without_rucas, :method_missing
        alias_method :method_missing, :method_missing_with_rucas
      end
    end

    # Get rid of patches.
    def self.unapply
      Numeric.module_eval do
        alias_method :method_missing_with_rucas, :method_missing
        alias_method :method_missing, :method_missing_without_rucas
      end
    end
  end
end
