class EnvironmentedProc < Proc
  attr_accessor :environment
  
  def initialize &block
    raise ArgumentError, 'EnvironmentedProcs may not have arguments' unless block.arity.zero?
    @environment = Object.new
    super
  end
  Speck.new EnvironmentedProc.method :new do
    ->{ EnvironmentedProc.new {|arg| } }.check_exception ArgumentError
    
    eproc = EnvironmentedProc.new {}
    EnvironmentedProc.new {} .check {|eproc| eproc.environment.is_a? Object }
    EnvironmentedProc.new {} .check {|eproc| eproc.is_a? Proc }
  end
  
  def inject variables
    variables.map do |variable, object|
      (class<<@environment;self;end).send(:define_method, variable) {object}
    end
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
  end
  
  def call
    environment.instance_eval &self
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
