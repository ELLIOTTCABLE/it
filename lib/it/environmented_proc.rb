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
  Speck.new EnvironmentedProc.method :new do
    ->{ EnvironmentedProc.new {|arg| } }.check_exception ArgumentError
    
    eproc = EnvironmentedProc.new {}
    EnvironmentedProc.new {} .check {|eproc| eproc.is_a? Proc }
  end
  
  def inject variables
    self.variables.merge! variables
    return self
  end
  Speck.new EnvironmentedProc.instance_method :inject do
    object = Object.new
    EnvironmentedProc.new {var} .inject(var: object)
      .check {|eproc| eproc[] == object }
    EnvironmentedProc.new {[var1, var2, var3].join(' ')}
      .inject(var1: "This", var2: "is", var3: "awesome")
      .check {|eproc| eproc[] == "This is awesome" }
    
    eproc = EnvironmentedProc.new {}
    eproc.inject(foo: 'bar').check {|rv| rv == eproc }
    
    Class.new do 
      def initialize
        EnvironmentedProc.new {self} .check {|eproc| eproc[] == self }
        
        object = Object.new
        EnvironmentedProc.new {self} .inject(self: object)
          .check {|eproc| eproc[] == object }
        self.methods.check {|methods| methods == Object.instance_methods }
      end
    end.new
  end
  
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
  Speck.new EnvironmentedProc.instance_method :call do
    object = Object.new
    
    # Ensure block executed properly
    array = Array.new
    EnvironmentedProc.new {array << object}.call.check { array.include? object }
    
    EnvironmentedProc.new {object}.call.check {|rv| rv == object }
  end
  
  alias_method :[], :call
end
