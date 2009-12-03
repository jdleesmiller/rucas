require 'rucas/utility'
require 'rucas/symbolic'
require 'rucas/extensions'

module Rucas
  VERSION = '0.0.1'

  #
  # Open classes to make constants work.
  #
  Extensions.apply

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

  #
  # Interpret code in the block as Rucas code and return the result of the
  # block. 
  #
  def with_rucas scope=Scope.new, &block
    scope.rucas(&block)
  end
end

require 'rucas/rewrite'
require 'rucas/simplify'

