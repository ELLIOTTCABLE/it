require_relative '../../speck_helper'

require 'it_specs'

require 'it/core_ext/proc'
It::Battery[It] << Speck.new(Proc) do
  
  Speck.new Proc.instance_method :self do
    proc = Proc.new {self}
    proc.self.check {|rv| rv == proc[] }
  end
  Speck.new Proc.instance_method :self= do
    object = Object.new
    ->{ ->{self}.set_self(object) }
      .check {|p| p[] == object }
  end
  
  Speck.new Proc.instance_method :inject do
    object = Object.new
    ->{ ->{var}.inject(var: object) }.check {|p| p[] == object }
    ->{ ->{[var1, var2, var3].join(' ')}
      .inject(var1: "This", var2: "is", var3: "awesome") }
      .check {|p| p[] == "This is awesome" }
    
    ->{ ->{a + b + c} % {a: 1, b: 2, c: 3} }
      .check {|p| p[] == 6 }
    
    proc = ->{}
    ->{ proc.inject(foo: 'bar') }.check {|rv| rv == proc }
    
    Class.new do 
      def initialize
        ->{ ->{self} }.check {|p| p[] == self }
        
        object = Object.new
        ->{ ->{self}.inject(self: object) }.check {|p| p[] == object }
        self.methods.check {|methods| methods == Object.instance_methods }
      end
    end.new
  end
  
end
