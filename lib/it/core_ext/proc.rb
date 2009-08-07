class Proc
  
  def inject variables
    EnvironmentedProc.new(&self).inject variables 
  end
  Speck.new Proc.instance_method :inject do
    object = Object.new
    ->{var}.inject(var: object).check {|p| p[] == object }
    ->{[var1, var2, var3].join(' ')}
      .inject(var1: "This", var2: "is", var3: "awesome")
      .check {|p| p[] == "This is awesome" }
    
    proc = ->{}
    proc.inject(foo: 'bar').check {|rv| rv == proc }
  end
  
end
