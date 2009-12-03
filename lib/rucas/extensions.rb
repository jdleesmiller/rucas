require 'rucas/symbolic'

module Rucas
  module Extensions
    #
    # Avoid collisions with other patches; this maps operators (+,-, etc.) to 
    # normal method names, so they can be called without the additional overhead
    # of Kernel#send.
    # 
    PATCH_HASH = Hash.new {|h,k| k} # return key by default
    PATCH_HASH[:+]  = :add
    PATCH_HASH[:-]  = :sub
    PATCH_HASH[:*]  = :mul
    PATCH_HASH[:/]  = :div
    PATCH_HASH[:**] = :pow
    PATCH_HASH[:=~] = :eqs
    PATCH_HASH[:<]  = :lt
    PATCH_HASH[:<=] = :lte
    PATCH_HASH[:>]  = :gt
    PATCH_HASH[:>=] = :gte
    PATCH_HASH[:&]  = :and
    PATCH_HASH[:|]  = :or
    raise "PATCH_HASH does not match BINARY_OPS" unless
      Symbolic::BINARY_OPS.keys.all?{|k| PATCH_HASH.member?(k)}

    # See PATCH_HASH.
    def self.without_rucas_name original
      "#{PATCH_HASH[original]}__without_rucas"
    end

    # See PATCH_HASH.
    def self.with_rucas_name original
      "#{PATCH_HASH[original]}__with_rucas"
    end

    # Add rucas methods constant classes, but don't alias_method them yet; that
    # is handled in the apply and unapply methods.
    for c in Symbolic::CONST_CLASSES
      for op in Symbolic::BINARY_OPS.keys
        c.class_eval %Q{
          def #{with_rucas_name(op)} rhs
            if rhs.is_a?(Rucas::Symbolic::Expr)
              Rucas::Symbolic::ConstExpr.new(self) #{op} rhs
            else
              self.#{without_rucas_name(op)}(rhs)
            end
          end
        }
      end

      # Try to convert to ConstExpr if can't find method (e.g. +simplify+).
      c.module_eval do
        def method_missing_with_rucas method, *args, &block
          method_missing_without_rucas(method *args, &block)
        rescue NoMethodError
          error = $!
          begin
            return Symbolic::Expr.make(self).send(method, *args, &block)
          rescue NoMethodError
            nil
          end
          raise error
        end
      end
    end
  
    # Patch system classes to make constants work with vars (e.g. 0 + x).
    def self.apply
      for c in Symbolic::CONST_CLASSES
        for op in Symbolic::BINARY_OPS.keys
          c.class_eval %Q{
            alias_method :#{without_rucas_name(op)}, :#{op}
            alias_method :#{op}, :#{with_rucas_name(op)}
          }
        end
        c.module_eval do
          alias_method :method_missing_without_rucas, :method_missing
          alias_method :method_missing, :method_missing_with_rucas
        end
      end
    end

    # Get rid of patches.
    def self.unapply
      for c in Symbolic::CONST_CLASSES
        for op in Symbolic::BINARY_OPS.keys
          c.class_eval %Q{
            alias_method :#{with_rucas_name(op)}, :#{op}
            alias_method :#{op}, :#{without_rucas_name(op)}
          }
        end
        c.module_eval do
          alias_method :method_missing_with_rucas, :method_missing
          alias_method :method_missing, :method_missing_without_rucas
        end
      end
    end
  end
end
