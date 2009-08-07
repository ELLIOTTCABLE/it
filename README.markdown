it
==
What? it! it what? it it! I’m so confused.

    [1, 2, 3].each { puts it }

EnvironmentedProc
-----------------
Just a little fun ride–along, no need to pay it any mind…

    @thingie = Proc.new {p [who, what, when, where]}
    # … somewhere else …
    @thingie.inject who: "why", what: "oh", when: "why", where: "!"
