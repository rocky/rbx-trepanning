class Trepan
  class VirtualCmdProcessor
    def initialize(interfaces, settings={})
      @interfaces      = interfaces
      @intf            = interfaces[-1]
      @settings        = settings
    end
    def errmsg(msg)
      puts msg
    end
    def msg(msg)
      puts msg
    end
  end
end
