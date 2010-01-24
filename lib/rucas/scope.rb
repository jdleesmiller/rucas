module Rucas
  #
  # Scope storing currently declared variables.
  #
  # Note: You can do this using any class; just include the Symbolic module.
  #
  class Scope
    include Symbolic

    #
    # Create a subscope; this is just a clone of the current scope, so it
    # includes all of the symbols of this scope.
    #
    def subscope
      self.clone
    end

    #
    # Evaluate given block in this scope.
    #
    def rucas &block
      self.instance_eval(&block)
    end
  end
end

