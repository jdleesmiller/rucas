module Rucas
  #
  # Private utility methods.
  #
  module Utility
    def meta_def name, &block
      (class << self; self; end).instance_eval { define_method(name,&block) }
    end
    private :meta_def
  end
end
