[![Build Status](https://travis-ci.org/rocky/rbx-trepanning.png)](https://travis-ci.org/rocky/rbx-trepanning)

##  Summary trepanx

The trepanning debugger gdb-like debugger. As such, it is both a high-level and low-level debugger. It is a also a rewrite of *ruby-debug*.

## Installing

```console
   gem install rbx-trepanning
```

If you want to run from git:

```console
   $ git clone https://github.com/rocky/rbx-trepanning.git
   $ cd rbx-trepanning
   $ bundle install      # load dependent packages
   $ rake test           # test it
   $ rake install        # install it
```

should get you going.



## Running

To run initially:

```console
  $ trepanx my-ruby-program.rb
```

Or to call from inside your code:

```console
  require 'trepanning'
  debugger # Don't stop here...
  work # but stop here.
```

If you want an immediate stop:

```console
  debugger(:immediate=>true)
```

Finally, if you put in your _.trepanx_

```ruby
    Rubinius::Loader.debugger = proc {
      require 'trepanning';
      Trepan.start(:skip_loader => :Xdebug)
    }
```

Then you can use the _-Xdebug_ option the Ruby, e.g.

```
  rbx -Xdebug my-ruby-program.rb
```

## See Also

* There is extensive on-line help. Run `help` inside the debugger.
* There is a [google group mailing list](http://groups.google.com/group/ruby-debugger for Ruby debuggers.)
* The [Wiki](https://github.com/rocky/rbx-trepanning/wiki).

## Author

Rocky Bernstein
