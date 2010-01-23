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
    # Raise an ArgumentError unless the name is non-empty and does NOT begin
    # with an uppercase letter.
    #
    # The convention in Ruby is that identifiers that start with an uppercase
    # letter are constants, which can cause (unpleasant) surprises.
    #
    def self.check_name name
      name = name.to_s
      raise ArgumentError, "empty name is not allowed" if name.length < 1
      name0 = name[0..0]
      raise ArgumentError, "names cannot start with an uppercase letter" \
        if name0 == name0.upcase
    end

    #
    # Define variable in current scope and return it.
    #
    def var name
      Symbolic.check_name name
      var = VarExpr.new(name)
      meta_def name do
        var
      end
      var
    end

    #
    # Define a named constant in current scope and return it.
    #
    def const name, value
      Symbolic.check_name name
      const = ConstExpr.new(name, value)
      meta_def name do
        const
      end
      const
    end

    #
    # Define function symbol in current scope and return it.
    #
    def symfun name
      Symbolic.check_name name
      fs = SymbolicFunction.new(name)
      meta_def name do
        fs
      end
      fs
    end

    #
    # Analogue of {Symbolic#var}, but for use in defining packages.
    #
    def self.var name
      check_name name
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
      check_name name
      const = ConstExpr.new(name, value)
      meta_def name do
        const
      end
      module_eval do
        define_method(name) do
          const
        end
      end
      const
    end

    #
    # Define function symbol in current scope and return it.
    #
    def self.symfun name
      check_name name
      fs = SymbolicFunction.new(name)
      meta_def name do
        fs
      end
      module_eval do
        define_method(name) do
          fs
        end
      end
      fs
    end
  end
end
