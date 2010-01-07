module Rucas
  #  
  # Translate Ruby expressions into expression trees for symbolic manipulation.
  #
  module Symbolic
    include Utility

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
  end
end
