##
# We extend `Proc` with several useful methods for creating
# `EnvironmentedProc`s.
# 
# It’s extremely important to note that these methods *return*
# `EnvironmentedProc`s initialized as requested; we obviously can’t modify the
# receiver. Also see the note on `#self=` regarding return values.
# 
# @see `#self=`
class Proc
  
  ##
  # Returns an `EnvironmentedProc`, with the value of `self` initialized as
  # requested.
  # 
  # It’s important to note that Ruby’s setter methods *always* return the set
  # value, regardless of what the function `return`s, when accessed with the
  # setter syntactic sugar (`something.accessor = value`). Since we can’t
  # return an `EnvironmentedProc` from `#self=`, and we can’t modify the
  # receiver, `self=` is a completely useless method when utilized in this
  # manner. We provide `#set_self` as an alias to `#self=` for exactly this
  # reason.
  attr_accessor :self
  def self; binding.eval("self"); end
  def self= object
    return EnvironmentedProc.new(&self)
      .tap {|eproc| eproc.self = object }
  end
  alias_method :set_self, :self=
  
  ##
  # Returns an `EnvironmentedProc`, initialized with the variables requested.
  def inject variables
    return EnvironmentedProc.new(&self).inject variables 
  end
  alias_method :%, :inject
  
end
