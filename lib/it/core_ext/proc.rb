class Proc
  
  def inject variables
    EnvironmentedProc.new(&self).inject variables 
  end
  alias_method :%, :inject
  Speck.new Proc.instance_method :inject do
    object = Object.new
    ->{var}.inject(var: object).check {|p| p[] == object }
    ->{[var1, var2, var3].join(' ')}
      .inject(var1: "This", var2: "is", var3: "awesome")
      .check {|p| p[] == "This is awesome" }
    
    (->{a + b + c} % {a: 1, b: 2, c: 3})
      .check {|p| p[] == 6 }
    
    proc = ->{}
    proc.inject(foo: 'bar').check {|rv| rv == proc }
    
    Class.new do 
      def initialize
        ->{self} .check {|p| p[] == self }
        
        object = Object.new
        ->{self} .inject(self: object).check {|p| p[] == object }
        self.methods.check {|methods| methods == Object.instance_methods }
      end
    end.new
  end
  
end
