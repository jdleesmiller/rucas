require 'rucas/utility'
require 'rucas/expr'
require 'rucas/symbolic'
require 'rucas/scope'
require 'rucas/extensions'

require 'facets/enumerable/sum'

#
# Open classes to make constants work.
#
Rucas::Extensions.apply

module Rucas
  VERSION = '0.0.3'

  #
  # Interpret code in the block as Rucas code and return the result of the
  # block. 
  #
  # @example
  #   require 'rucas'
  #
  #   Rucas.code {
  #     var :x
  #     var :y
  #     x + y
  #   }
  #
  def self.code &block
    Scope.new.rucas(&block)
  end
end

# Load core features.
require 'rucas/rewrite'
require 'rucas/simplify'

# Load default packages.
require 'rucas/elementary'

