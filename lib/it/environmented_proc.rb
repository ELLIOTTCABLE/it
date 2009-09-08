##
# An `EnvironmentedProc` is a `Proc` extended to provide an alterable
# environment. Specifically, you can preform the following operations on an
# `EnvironmentedProc` in addition to those of a normal `Proc`:
# 
# - Inject local variables into the execution scope of the `EnvironmentedProc`
# - Change the value of `self` for the duration of execution
# 
# Downsides
# ---------
# It’s important to note that the method by which we preform these operations
# is rather fragile and hacky (and possibly, though I haven’t benchmarked
# `EnvironmentedProc` versus `Proc` yet, very slow). While these tools are
# very convenient, it would be prudent to avoid overusing them.
# 
# Various things to be aware of:
# 
# - Local variables wrapped into the scope of the block may override variables
#   we inject into it (as true local variables override instance methods,
#   which is what we are actually injecting into the scope of the block)
# - If the block depends on some minutiæ of the creation environment, there’s
#   a chance it will break (as we override the creation environment to set
#   `self`)
# - At the moment, `EnvironmentedProc`s may not be created from `Proc`s that
#   take arguments in the normal fashion. This isn’t such a big deal, becasue
#   in most of the cases where `EnvironmentedProc`s would be desirable,
#   injecting local variables is preferrable to passing arguments (DSLs,
#   syntax hacks, and of course the library `EnvironmentedProc` was created
#   for: it)
class EnvironmentedProc < Proc
  
  # The value of `self` for the duration of execution
  attr_accessor :self
  def self; @self ||= binding.eval("self"); end
  
  # A `Hash` of variables to be injected into the scope for the duration of
  # execution.
  attr_reader :variables
  def variables; @variables ||= Hash.new; end
  
  ##
  # `EnvironmentedProc`s are initialized with a block, an existing `Proc`
  # object. When initialized, `self` is primed to the value of `self` in the
  # scope of the existing `Proc`.
  def initialize &block
    raise ArgumentError, 'EnvironmentedProcs may not have arguments' unless block.arity.zero?
    super
    self.self
  end
  
  ##
  # Injects objects into the scope of the `EnvironmentedProc` with the given
  # variable name. Accepts a `Hash` of the form `{:variable_name => object}`.
  # 
  # Variables may be, in fact, not only true variables, but also `Constants`,
  # `@instance_variables`, and `@@class_variables`. All will be made available
  # as their proper form.
  # 
  # Example:
  # 
  #     eproc = ->{ p Foo, bar } % {Foo: 123, bar: 456}
  #     eproc.call
  def inject variables
    self.self = variables.delete(:self) if variables[:self]
    self.variables.merge! variables
    return self
  end
  alias_method :%, :inject
  
  ##
  # Executes an `EnvironmentedProc` against the object stored in `self`.
  # `variables` are stored in instance methods on the object stored in `self`
  # before execution (any instance methods that would be overwritten are
  # sequestered away and restored after execution, to avoid damaging the
  # object in `self`).
  def call
    # Okay, if you’re reading this, you probably want to know how all this
    # works. Uh… that’s gonna be fun /-:
    # The problem is that variable/constant lookups seem to be handled in a
    # different way for every single of the types of variables we’re trying
    # to inject. I’ll describe how we set each, and why we’re setting it on
    # the place we’re setting it on, below.
    scope = Class.new
    eigenclass = class<<self.self;self;end
    
    reimplementables = variables.map do |name, object|
      case name.to_s
      when /^@@/
        # Class variables are easily the weirdest of the bunch. Instead of
        # being looked up in the scope of the closure (i.e. where the block is
        # defined, which makes sense)… or in the scope of the object we’re
        # evaluating the block on (`#self`, which makes a little less sense)…
        # it’s looked up in the scope of *this function*, that is,
        # `EnvironmentedProc#inject`. It boils down to looking in whatever
        # scope the `#instance_eval` method is called in (not the object it’s
        # called on, nor the scope of the block!) To circumvent this, we make
        # the actual `#instance_eval` call inside an anonymous class, and we
        # set our class variables on that class.
        # 
        # This may change in the future, I very much expect this is a bug - as
        # of this writing, I’m on:
        # ruby 1.9.1p129 (2009-05-12 revision 23412) [i386-darwin10.0.0b1]
        scope.class_variable_set(name, object)
        [:class, name, nil]
      when /^@/
        # Instance variables are easier. Instance variable lookups happen in
        # the same place as method lookups—the object (`#self`) on which we
        # `#instance_eval` the block. We simply set the instance variable on
        # that object for the duration of execution.
        prior = self.self.instance_variable_get name
        self.self.instance_variable_set name, object
        [:instance, name, prior]
      when /^[A-Z]/
        # Constants are looked up in the inheritance tree of our `#self`; the
        # most immediate place to temporarily define them is the singleton
        # eigenclass.
        prior = eigenclass.const_defined?(name) ?
          eigenclass.const_get(name) : nil
        eigenclass.const_set(name, object)
        [:constant, name, prior]
      else
        # Finally, local variables are looked up in the definition scope of
        # the block; however, it is difficult, messy, and evil to inject
        # there. Since method calls use the same sentax as local variables,
        # it’s much simpler to define a temporary instance method on `#self`,
        # so this is exactly what we do.
        umethod = eigenclass.method_defined?(name) ?
          eigenclass.instance_method(name) : nil
        eigenclass.send(:define_method, name) {object}
        [:local, name, umethod]
      end
    end
    
    proc = self
    object = @self
    rv = scope.module_eval { object.instance_eval &proc }
    
    reimplementables.each do |type, name, object|
      # Now that we’ve evaluated the block, we’re going to teardown all the
      # setup we preformed, resetting as much environment to its pre–execution
      # state as possible.
      case type
      when :class
        # We don’t re–set anything for class variables, because we set those
        # on a throw–away anonymous `Class`, which will be destroyed at the
        # closing of this method anyway.
      when :instance
        object ?
          self.self.instance_variable_set(name, object) :
          self.self.send(:remove_instance_variable, name)
      when :constant
        eigenclass.send(:remove_const, name)
        eigenclass.const_set(name, object) if object
      when :local
        object ?
          eigenclass.send(:define_method, name, &object) :
          eigenclass.send(:remove_method, name)
      end
    end
    
    return rv
  end
  
  alias_method :[], :call
end
