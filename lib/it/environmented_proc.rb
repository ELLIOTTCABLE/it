class EnvironmentedProc < Proc
  
  attr_accessor :self
  def self; @self ||= binding.eval("self"); end
  
  attr_accessor :variables
  def variables; @variables ||= Hash.new; end
  
  def initialize &block
    raise ArgumentError, 'EnvironmentedProcs may not have arguments' unless block.arity.zero?
    super
    self.self
  end
  
  def inject variables
    self.self = variables.delete(:self) if variables[:self]
    self.variables.merge! variables
    return self
  end
  alias_method :%, :inject
  
  def call
    eigenclass = class<<@self;self;end
    reimplementables = variables.map do |variable, object|
      umethod = begin eigenclass.instance_method variable; rescue NameError; nil; end
      eigenclass.send(:define_method, variable) {object}
      [variable, umethod]
    end
    
    rv = @self.instance_eval &self
    
    reimplementables.each do |variable, umethod|
      umethod ? eigenclass.send(:define_method, variable, &umethod) :
        eigenclass.send(:remove_method, variable)
    end
    
    return rv
  end
  
  alias_method :[], :call
end
