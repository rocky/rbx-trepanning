class Trepan
  module Display
    def info(str)
      str.split("\n").each do |s|
        puts "| #{s}"
      end
    end

    def display(str)
      puts "=> #{str}"
    end

    def crit(str)
      puts "[CRITICAL] #{str}"
    end

    def error(str, prefix='** ')
      if str.is_a?(Array)
        str.each{|s| error(s)}
      else
        str.split("\n").each do |s|
          puts "%s%s" % [prefix, s]
        end
      end
    end

    def section(str)
      puts "==== #{str} ===="
    end

    def ask(str)
      Readline.readline("| #{str}")
    end
  end
end
