class Debugger::Command::EvalCode < Debugger::Command
  pattern "p", "eval"
  help "++ Run code in the current context"
  ext_help <<-HELP
Run code in the context of the current frame.

The value of the expression is stored into a global variable so it
may be used again easily. The name of the global variable is printed
next to the inspect output of the value.
      HELP

  def run(args)
    @debugger.eval_code(args)
  end
end

