`it`
====
What? `it`! It what? `it` it! I’m so confused. Did `it` confuse you? Did what
confuse me? `it`! It what? … ugh, whatever.

`it` extends some commonly used `Enumerable` methods with a convenience: if
you pass them a block with no arguments (an `arity` of zero), and they expect
a block with a single argument, then your block will be injected with the
value that would normally be passed as that variable, as the variable named
“it”:

    [1, 2, 3].each { puts it }

EnvironmentedProc
-----------------
I achieve the magic of the `it` variable with some (ridiculously hacky) magic
that I wrapped into the `EnvironmentedProc` class. Unlike most of my projects,
this project is licensed as liberally as possible (see below), so you can use
`EnvironmentedProc` whenever and wherever you want. I hope somebody other than
myself finds it exciting!

`EnvironmentedProc` injects variables into the scope of a block. Incidentally,
it can also change the value of `self` for the duration of block execution.

See the documentation on `EnvironmentedProc` for more data.

### Examples

    @thingie = Proc.new {p [who, what, when, where]}
    # … somewhere else …
    @thingie.inject who: "why", what: "oh", when: "why", where: "!"

Man, I really need to change my self /-:

    @thingie = Proc.new {self * 2}
    # … somewhere else …
    @thingie.set_self(2).call # => 4

Installing
----------
You can install `it` as a pre–built gem, or you can build it directly from the
source.

The easiest way to install `it` is to use [RubyGems][] to acquire the latest
‘release’ version from [GitHub][], using the `gem` command line tool:

    # If you’ve ever done this before, you don’t need to do it now
    # (see http://gems.github.com)
    gem sources -a http://gems.github.com
    
    gem install elliottcable-it

Alternatively, you can build a gem from the latest source yourself. You need
[git][], as well as [Rake][]:

    git clone git://github.com/elliottcable/it.git
    cd it
    rake package:package
    gem install pkg/it-*.gem

  [RubyGems]: <http://rubyforge.org/projects/rubygems/> "RubyGems - Ruby package manager"
  [RubyForge]: <http://rubyforge.org/projects/it/> "`it` on RubyForge"
  [GitHub]: <http://github.com/elliottcable/it> "`it` on GitHub"
  [git]: <http://git-scm.com/> "git - Fast Version Control System"
  [Rake]: <http://rake.rubyforge.org/> "Rake - Ruby Make"

Contributing
------------
You can contribute bug fixes or new features to `it` by forking the project on
[GitHub][] (you’ll need to register for an account first), and sending me a pull
request once you’ve committed and pushed your changes.

If you find bugs, you can report them on the issue tracker at GitHub:
<http://github.com/elliottcable/it/issues>

If you’re looking for something to do, check out the open issues on that
tracker, and maybe fix some bugs d-:

License
-------
`it` is copyright ©2008 by elliottcable.

`it` is released under the [GNU Affero General Public License v3][agpl3],
which allows you to freely utilize, modify, and distribute all `it`’s source
code (subject to the terms of the aforementioned license).

The sourcecode to the `EnvironmentedProc` class (in the file
`lib/it/environmented_proc.rb`) is additionally released under a liberal
MIT license (the “[XFree86 License v1.1][mit]”). You may choose to use the
source code in that file under the terms of either of those two licenses,
according to your needs.

  [agpl3]: <http://www.gnu.org/licenses/agpl-3.0.txt> "The GNU Affero General Public License v3"
  [mit]: <http://www.xfree86.org/current/LICENSE4.html> "The XFree86 License v1.1"
