class Trepan
  class VirtualCmdProcessor
    def initialize(interfaces, settings={})
      @interfaces      = interfaces
      @intf            = interfaces[-1]
      @settings        = settings
    end
  end
end
