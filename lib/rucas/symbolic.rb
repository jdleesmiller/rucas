module Rucas
  #  
  # Helper methods for symbolic computation.
  # You can include this in any class, and instances of that class will be
  # able to create variables and symbolic functions.
  # This module provides the functionality for {Scope}, which in turn powers the
  # {#with_rucas} method and the interactive rucas shell.
  #
  module Symbolic
    include Utility
    extend Utility

    #
    # Define variable in current scope and return it.
    #
    def var name
      var = VarExpr.new(name)
      meta_def var.name do
        var
      end
      var
    end

    #
    # Define function symbol in current scope and return it.
    #
    def symfun name
      fs = SymbolicFunction.new(name)
      meta_def fs.name do
        fs
      end
      fs
    end

    #
    # Analogue of {Symbolic#var}, but for use in defining packages.
    #
    def self.var name
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
    def self.const name, value
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
