module Rucas
  #
  # Helper for defining packages.
  # @example
  #   module MyPackage
  #     extend Rucas::Package
  #     const :E, Math::E
  #   end
  #
  module Package
    include Utility

    #
    # Hook to register the extending package's methods with the {Symbolic}
    # module, so they're available in the usual way.
    #
    def self.extended mod
      super
      p mod
      Symbolic.instance_eval do
        include mod 
      end
    end

    #
    # Analogue of {Symbolic#var}, but for use in defining packages.
    #
    def var name
      var = VarExpr.new(name)
      meta_def name do
        var
      end
      module_eval do
        define_method(name) do
          var
        end
      end
      var
    end

    #
    # Analogue of {Symbolic#const}, but for use in defining packages.
    #
    def const name, value
      const = ConstExpr.new(name, value)
      meta_def name do
        const
      end
      module_eval do
        define_method(name) do
          const
        end
      end
      p const
      const
    end
  end
end

