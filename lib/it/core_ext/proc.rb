class Proc
  
  attr_accessor :self
  def self; binding.eval("self"); end
  def self= object
    return EnvironmentedProc.new(&self)
      .tap {|eproc| eproc.self = object }
  end
  alias_method :set_self, :self=
  
  def inject variables
    return EnvironmentedProc.new(&self).inject variables 
  end
  alias_method :%, :inject
  
end
