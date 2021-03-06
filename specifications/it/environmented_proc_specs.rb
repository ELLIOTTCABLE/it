require_relative '../speck_helper'

require 'it_specs'

require 'it/environmented_proc'
It::Battery[It] << Speck.new(EnvironmentedProc) do
  Speck.new EnvironmentedProc.instance_method :self do
    ->{ EnvironmentedProc.new {self} }
      .check {|eproc| eproc.call == eproc.self }
  end
  Speck.new EnvironmentedProc.instance_method :self= do
    object = Object.new
    ->{ EnvironmentedProc.new {self} .tap {|eproc| eproc.self = object } }
      .check {|eproc| eproc.call == object }
  end
  
  Speck.new EnvironmentedProc.instance_method :initialize do
    ->{ EnvironmentedProc.new {} }.check {|eproc| eproc.is_a? Proc }
  end
  
  Speck.new EnvironmentedProc.instance_method :inject do
    Class.new do 
      def initialize
        eigenclass = class<<self;self;end
        
        prior_methods = self.methods
        prior_instance_variables = self.instance_variables
        prior_class_variables = self.class.instance_variables
        prior_constants = self.class.constants
        
        eigen_methods = eigenclass.methods
        eigen_instance_variables = eigenclass.instance_variables
        eigen_constants = eigenclass.constants
        
        object = Object.new
        ->{ EnvironmentedProc.new {var} .inject(var: object) }
          .check {|eproc| eproc.call == object }
        
        another_object = Object.new
        ->{ EnvironmentedProc.new {|var| var } .inject(var: object) }
          .check {|eproc| eproc.call(another_object) == another_object }
        
        ->{ EnvironmentedProc.new {@var} .inject(:@var => object) }
          .check {|eproc| eproc.call == object }
        
        not ->{ EnvironmentedProc.new {@@var} .inject(:@@var => object).call }
          .check_exception
        ->{ EnvironmentedProc.new {@@var} .inject(:@@var => object) }
          .check {|eproc| eproc.call == object }
        
        not ->{ EnvironmentedProc.new {Cons} .inject(Cons: object).call }
          .check_exception
        ->{ EnvironmentedProc.new {Cons} .inject(Cons: object) }
          .check {|eproc| eproc.call == object }
        
        ->{ EnvironmentedProc.new {[var1, var2, var3].join(' ')}
          .inject(var1: "This", var2: "is", var3: "awesome!") }
          .check {|eproc| eproc.call == "This is awesome!" }
        
        ->{ EnvironmentedProc.new {a + b + c} % {a: 1, b: 2, c: 3} }
          .check {|eproc| eproc.call == 6 }
        
        eproc = EnvironmentedProc.new {}
        ->{ eproc.inject(foo: 'bar') }.check {|rv| rv == eproc }
        
        ->{ EnvironmentedProc.new {self} }
          .check {|eproc| eproc.call == self }
        
        ->{ EnvironmentedProc.new {self} }.inject(self: object)
          .check {|eproc| eproc.call == object }
        
        ->{ self.methods }.check {|methods| methods == prior_methods }
        ->{ self.instance_variables }.check {|ivars| ivars == prior_instance_variables }
        ->{ self.class.instance_variables }.check {|cvars| cvars == prior_class_variables }
        ->{ self.class.constants }.check {|cons| cons == prior_constants }
        
        ->{ eigenclass.methods }.check {|methods| methods == eigen_methods }
        ->{ eigenclass.instance_variables }.check {|ivars| ivars == eigen_instance_variables }
        ->{ eigenclass.constants }.check {|cons| cons == eigen_constants }
      end
    end.new
  end
  
  Speck.new EnvironmentedProc.instance_method :call do
    object = Object.new
    array = Array.new
    ->{ EnvironmentedProc.new {array << object}.call }.check { array.include? object }
    
    ->{ EnvironmentedProc.new {object}.call }.check {|rv| rv == object }
  end
  
end
