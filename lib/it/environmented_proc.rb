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
  # Example:
  # 
  #     eproc = ->{ p foo, bar } % {foo: 123, bar: 456}
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
