module Rucas
  #
  # Private utility methods.
  #
  module Utility
    #
    # Define method in this object's singleton class.
    #
    def meta_def name, &block
      (class << self; self; end).instance_eval { define_method(name,&block) }
    end
  end
end
