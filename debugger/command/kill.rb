class Debugger::Command::Kill < Debugger::Command
  pattern "kill"
  help "Send this process a POSIX signal 'KILL', i.e.'kill -9'"
  ext_help "
Kill execution of program being debugged.

Equivalent of Process.kill('KILL', Process.pid). This is an
unmaskable signal. When all else fails, e.g. in thread code, use this."
  def run(args)
    sig='KILL'
    begin
      Process.kill(sig, Process.pid)
    rescue Errno::ESRCH
      error "Unable to send kill #{sig} to process #{Process.pid}"
    end
  end
end

