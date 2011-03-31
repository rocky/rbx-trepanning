class CmdParse
# STANDALONE START
    def setup_parser(str, debug=false)
      @string = str
      @pos = 0
      @memoizations = Hash.new { |h,k| h[k] = {} }
      @result = nil
      @failing_offset = -1
      @expected_string = []

      enhance_errors! if debug
    end

    # This is distinct from setup_parser so that a standalone parser
    # can redefine #initialize and still have access to the proper
    # parser setup code.
    #
    def initialize(str, debug=false)
      setup_parser(str, debug)
    end

    attr_reader :string
    attr_reader :result, :failing_offset, :expected_string
    attr_accessor :pos

    # STANDALONE START
    def current_column(target=pos)
      offset = 0
      string.each_line do |line|
        len = line.size
        return (target - offset) if offset + len >= target
        offset += len
      end

      -1
    end

    def current_line(target=pos)
      cur_offset = 0
      cur_line = 0

      string.each_line do |line|
        cur_line += 1
        cur_offset += line.size
        return cur_line if cur_offset >= target
      end

      -1
    end

    def lines
      lines = []
      string.each_line { |l| lines << l }
      lines
    end

    def error_expectation
      error_pos = failing_offset()
      line_no = current_line(error_pos)
      col_no = current_column(error_pos)

      expected = expected_string()

      prefix = nil

      case expected
      when String
        prefix = expected.inspect
      when Range
        prefix = "to be between #{expected.begin} and #{expected.end}"
      when Array
        prefix = "to be one of #{expected.inspect}"
      when nil
        prefix = "anything (no more input)"
      else
        prefix = "unknown"
      end

      return "Expected #{prefix} at line #{line_no}, column #{col_no} (offset #{error_pos})"
    end

    def show_error(io=STDOUT)
      error_pos = failing_offset()
      line_no = current_line(error_pos)
      col_no = current_column(error_pos)

      io.puts error_expectation()
      io.puts "Got: #{string[error_pos,1].inspect}"
      line = lines[line_no-1]
      io.puts "=> #{line}"
      io.print(" " * (col_no + 3))
      io.puts "^"
    end

    #

    def get_text(start)
      @string[start..@pos-1]
    end

    def show_pos
      width = 10
      if @pos < width
        "#{@pos} (\"#{@string[0,@pos]}\" @ \"#{@string[@pos,width]}\")"
      else
        "#{@pos} (\"... #{@string[@pos - width, width]}\" @ \"#{@string[@pos,width]}\")"
      end
    end

    def add_failure(obj)
      @expected_string = obj
      @failing_offset = @pos if @pos > @failing_offset
    end

    def match_string(str)
      len = str.size
      if @string[pos,len] == str
        @pos += len
        return str
      end

      add_failure(str)

      return nil
    end

    def fail_range(start,fin)
      @pos -= 1

      add_failure Range.new(start, fin)
    end

    def scan(reg)
      if m = reg.match(@string[@pos..-1])
        width = m.end(0)
        @pos += width
        return true
      end

      add_failure reg

      return nil
    end

    if "".respond_to? :getbyte
      def get_byte
        if @pos >= @string.size
          add_failure nil
          return nil
        end

        s = @string.getbyte @pos
        @pos += 1
        s
      end
    else
      def get_byte
        if @pos >= @string.size
          add_failure nil
          return nil
        end

        s = @string[@pos]
        @pos += 1
        s
      end
    end

    module EnhancedErrors
      def add_failure(obj)
        @expected_string << obj
        @failing_offset = @pos if @pos > @failing_offset
      end

      def match_string(str)
        if ans = super
          @expected_string.clear
        end

        ans
      end

      def scan(reg)
        if ans = super
          @expected_string.clear
        end

        ans
      end

      def get_byte
        if ans = super
          @expected_string.clear
        end

        ans
      end
    end

    def enhance_errors!
      extend EnhancedErrors
    end

    def parse
      _root ? true : false
    end

    class LeftRecursive
      def initialize(detected=false)
        @detected = detected
      end

      attr_accessor :detected
    end

    class MemoEntry
      def initialize(ans, pos)
        @ans = ans
        @pos = pos
        @uses = 1
        @result = nil
      end

      attr_reader :ans, :pos, :uses, :result

      def inc!
        @uses += 1
      end

      def move!(ans, pos, result)
        @ans = ans
        @pos = pos
        @result = result
      end
    end

    def apply(rule)
      if m = @memoizations[rule][@pos]
        m.inc!

        prev = @pos
        @pos = m.pos
        if m.ans.kind_of? LeftRecursive
          m.ans.detected = true
          return nil
        end

        @result = m.result

        return m.ans
      else
        lr = LeftRecursive.new(false)
        m = MemoEntry.new(lr, @pos)
        @memoizations[rule][@pos] = m
        start_pos = @pos

        ans = __send__ rule

        m.move! ans, @pos, @result

        # Don't bother trying to grow the left recursion
        # if it's failing straight away (thus there is no seed)
        if ans and lr.detected
          return grow_lr(rule, start_pos, m)
        else
          return ans
        end

        return ans
      end
    end

    def grow_lr(rule, start_pos, m)
      while true
        @pos = start_pos
        @result = m.result

        ans = __send__ rule
        return nil unless ans

        break if @pos <= m.pos

        m.move! ans, @pos, @result
      end

      @result = m.result
      @pos = m.pos
      return m.ans
    end

    #


##################################################### 
  # Structure to hold composite method names
  SymbolEntry = Struct.new(:type, :name, :chain)


  # Structure to hold position information
  Position = Struct.new(:container_type, :container,
                       :position_type,  :position)

  # Structure to hold breakpoint information
  Breakpoint = Struct.new(:position, :negate, :condition)

  # Structure to hold list information
  List = Struct.new(:position, :num)

  DEFAULT_OPTS = {
    :debug=>false, 
    :file_exists_proc => Proc.new{|filename|
        File.readable?(filename) && !File.directory?(filename)
    }
  }
  def initialize(str, opts={})
    @opts = DEFAULT_OPTS.merge(opts)
    setup_parser(str, opts[:debug])
    @file_exists_proc = @opts[:file_exists_proc]
  end


   


  # upcase_letter = /[A-Z]/
  def _upcase_letter
    _tmp = scan(/\A(?-mix:[A-Z])/)
    return _tmp
  end

  # downcase_letter = /[a-z]/
  def _downcase_letter
    _tmp = scan(/\A(?-mix:[a-z])/)
    return _tmp
  end

  # suffix_letter = /[=!?]/
  def _suffix_letter
    _tmp = scan(/\A(?-mix:[=!?])/)
    return _tmp
  end

  # letter = (upcase_letter | downcase_letter)
  def _letter

    _save = self.pos
    while true # choice
      _tmp = apply(:_upcase_letter)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_downcase_letter)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    return _tmp
  end

  # id_symbol = (letter | "_" | [0-9])
  def _id_symbol

    _save = self.pos
    while true # choice
      _tmp = apply(:_letter)
      break if _tmp
      self.pos = _save
      _tmp = match_string("_")
      break if _tmp
      self.pos = _save
      _tmp = get_byte
      if _tmp
          unless _tmp >= 48 and _tmp <= 57
            fail_range('0', '9')
            _tmp = nil
          end
      end
      break if _tmp
      self.pos = _save
      break
    end # end choice

    return _tmp
  end

  # vm_identifier = < (downcase_letter | "_") id_symbol* suffix_letter? > {        SymbolEntry.new(:variable, text)     }
  def _vm_identifier

    _save = self.pos
    while true # sequence
      _text_start = self.pos
  
    _save1 = self.pos
      while true # sequence
    
    _save2 = self.pos
        while true # choice
          _tmp = apply(:_downcase_letter)
          break if _tmp
          self.pos = _save2
          _tmp = match_string("_")
          break if _tmp
          self.pos = _save2
          break
        end # end choice

        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_id_symbol)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
          break
        end
        _save4 = self.pos
        _tmp = apply(:_suffix_letter)
        unless _tmp
          _tmp = true
          self.pos = _save4
        end
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;    
      SymbolEntry.new(:variable, text)
    ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    return _tmp
  end

  # variable_identifier = < (downcase_letter | "_") id_symbol* > {        SymbolEntry.new(:variable, text)     }
  def _variable_identifier

    _save = self.pos
    while true # sequence
      _text_start = self.pos
  
    _save1 = self.pos
      while true # sequence
    
    _save2 = self.pos
        while true # choice
          _tmp = apply(:_downcase_letter)
          break if _tmp
          self.pos = _save2
          _tmp = match_string("_")
          break if _tmp
          self.pos = _save2
          break
        end # end choice

        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_id_symbol)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;    
      SymbolEntry.new(:variable, text)
    ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    return _tmp
  end

  # constant_identifier = < upcase_letter id_symbol* > {        SymbolEntry.new(:constant, text)     }
  def _constant_identifier

    _save = self.pos
    while true # sequence
      _text_start = self.pos
  
    _save1 = self.pos
      while true # sequence
        _tmp = apply(:_upcase_letter)
        unless _tmp
          self.pos = _save1
          break
        end
        while true
          _tmp = apply(:_id_symbol)
          break unless _tmp
        end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;    
      SymbolEntry.new(:constant, text)
    ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    return _tmp
  end

  # global_identifier = < "$" (constant_identifier | variable_identifier) > {       SymbolEntry.new(:global, text)     }
  def _global_identifier

    _save = self.pos
    while true # sequence
      _text_start = self.pos
  
    _save1 = self.pos
      while true # sequence
        _tmp = match_string("$")
        unless _tmp
          self.pos = _save1
          break
        end
    
    _save2 = self.pos
        while true # choice
          _tmp = apply(:_constant_identifier)
          break if _tmp
          self.pos = _save2
          _tmp = apply(:_variable_identifier)
          break if _tmp
          self.pos = _save2
          break
        end # end choice

        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;   
      SymbolEntry.new(:global, text)
    ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    return _tmp
  end

  # local_internal_identifier = (constant_identifier | variable_identifier)
  def _local_internal_identifier

    _save = self.pos
    while true # choice
      _tmp = apply(:_constant_identifier)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_variable_identifier)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    return _tmp
  end

  # local_identifier = (constant_identifier | vm_identifier)
  def _local_identifier

    _save = self.pos
    while true # choice
      _tmp = apply(:_constant_identifier)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_vm_identifier)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    return _tmp
  end

  # instance_identifier = < "@" local_identifier > {       SymbolEntry.new(:instance, text)     }
  def _instance_identifier

    _save = self.pos
    while true # sequence
      _text_start = self.pos
  
    _save1 = self.pos
      while true # sequence
        _tmp = match_string("@")
        unless _tmp
          self.pos = _save1
          break
        end
        _tmp = apply(:_local_identifier)
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;   
      SymbolEntry.new(:instance, text)
    ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    return _tmp
  end

  # classvar_identifier = "@@" local_identifier:id {      SymbolEntry.new(:classvar, id)     }
  def _classvar_identifier

    _save = self.pos
    while true # sequence
      _tmp = match_string("@@")
      unless _tmp
        self.pos = _save
        break
      end
      _tmp = apply(:_local_identifier)
      id = @result
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;   
     SymbolEntry.new(:classvar, id)
    ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    return _tmp
  end

  # identifier = (global_identifier | instance_identifier | classvar_identifier | local_identifier)
  def _identifier

    _save = self.pos
    while true # choice
      _tmp = apply(:_global_identifier)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_instance_identifier)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_classvar_identifier)
      break if _tmp
      self.pos = _save
      _tmp = apply(:_local_identifier)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    return _tmp
  end

  # id_separator = < ("::" | ".") > { text }
  def _id_separator

    _save = self.pos
    while true # sequence
      _text_start = self.pos
  
    _save1 = self.pos
      while true # choice
        _tmp = match_string("::")
        break if _tmp
        self.pos = _save1
        _tmp = match_string(".")
        break if _tmp
        self.pos = _save1
        break
      end # end choice

      if _tmp
        text = get_text(_text_start)
      end
      unless _tmp
        self.pos = _save
        break
      end
      @result = begin;    text ; end
      _tmp = true
      unless _tmp
        self.pos = _save
      end
      break
    end # end sequence

    return _tmp
  end

  # internal_class_module_chain = (< local_internal_identifier:parent id_separator:sep internal_class_module_chain:child > {          SymbolEntry.new(parent.type, text, [parent, child, sep])       } | local_identifier)
  def _internal_class_module_chain

    _save = self.pos
    while true # choice
  
    _save1 = self.pos
      while true # sequence
        _text_start = self.pos
    
    _save2 = self.pos
        while true # sequence
          _tmp = apply(:_local_internal_identifier)
          parent = @result
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_id_separator)
          sep = @result
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_internal_class_module_chain)
          child = @result
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;     
         SymbolEntry.new(parent.type, text, [parent, child, sep])
      ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      _tmp = apply(:_local_identifier)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    return _tmp
  end

  # class_module_chain = (< identifier:parent id_separator:sep internal_class_module_chain:child > {          SymbolEntry.new(parent.type, text, [parent, child, sep])       } | identifier)
  def _class_module_chain

    _save = self.pos
    while true # choice
  
    _save1 = self.pos
      while true # sequence
        _text_start = self.pos
    
    _save2 = self.pos
        while true # sequence
          _tmp = apply(:_identifier)
          parent = @result
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_id_separator)
          sep = @result
          unless _tmp
            self.pos = _save2
            break
          end
          _tmp = apply(:_internal_class_module_chain)
          child = @result
          unless _tmp
            self.pos = _save2
          end
          break
        end # end sequence

        if _tmp
          text = get_text(_text_start)
        end
        unless _tmp
          self.pos = _save1
          break
        end
        @result = begin;     
         SymbolEntry.new(parent.type, text, [parent, child, sep])
      ; end
        _tmp = true
        unless _tmp
          self.pos = _save1
        end
        break
      end # end sequence

      break if _tmp
      self.pos = _save
      _tmp = apply(:_identifier)
      break if _tmp
      self.pos = _save
      break
    end # end choice

    return _tmp
  end

  # sp = /[ \t]/
  def _sp
    _tmp = scan(/\A(?-mix:[ \t])/)
    return _tmp
  end

  # - = sp+
  def __hyphen_
    _save = self.pos
    _tmp = apply(:_sp)
    if _tmp
        while true
                _tmp = apply(:_sp)
            break unless _tmp
          end
          _tmp = true
        else
          self.pos = _save
        end
    return _tmp
  end

  # dbl_escapes = ("\\\"" { '"' } | "\\n" { "\n" } | "\\t" { "\t" } | "\\\\" { "\\" })
  def _dbl_escapes
    
    _save = self.pos
        while true # choice
      
    _save1 = self.pos
          while true # sequence
            _tmp = match_string("\\\"")
            unless _tmp
              self.pos = _save1
              break
            end
            @result = begin;          '"' ; end
            _tmp = true
            unless _tmp
              self.pos = _save1
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save
      
    _save2 = self.pos
          while true # sequence
            _tmp = match_string("\\n")
            unless _tmp
              self.pos = _save2
              break
            end
            @result = begin;          "\n" ; end
            _tmp = true
            unless _tmp
              self.pos = _save2
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save
      
    _save3 = self.pos
          while true # sequence
            _tmp = match_string("\\t")
            unless _tmp
              self.pos = _save3
              break
            end
            @result = begin;          "\t" ; end
            _tmp = true
            unless _tmp
              self.pos = _save3
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save
      
    _save4 = self.pos
          while true # sequence
            _tmp = match_string("\\\\")
            unless _tmp
              self.pos = _save4
              break
            end
            @result = begin;          "\\" ; end
            _tmp = true
            unless _tmp
              self.pos = _save4
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save
          break
        end # end choice

    return _tmp
  end

  # escapes = ("\\\"" { '"' } | "\\n" { "\n" } | "\\t" { "\t" } | "\\ " { " " } | "\\:" { ":" } | "\\\\" { "\\" })
  def _escapes
    
    _save = self.pos
        while true # choice
      
    _save1 = self.pos
          while true # sequence
            _tmp = match_string("\\\"")
            unless _tmp
              self.pos = _save1
              break
            end
            @result = begin;          '"' ; end
            _tmp = true
            unless _tmp
              self.pos = _save1
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save
      
    _save2 = self.pos
          while true # sequence
            _tmp = match_string("\\n")
            unless _tmp
              self.pos = _save2
              break
            end
            @result = begin;          "\n" ; end
            _tmp = true
            unless _tmp
              self.pos = _save2
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save
      
    _save3 = self.pos
          while true # sequence
            _tmp = match_string("\\t")
            unless _tmp
              self.pos = _save3
              break
            end
            @result = begin;          "\t" ; end
            _tmp = true
            unless _tmp
              self.pos = _save3
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save
      
    _save4 = self.pos
          while true # sequence
            _tmp = match_string("\\ ")
            unless _tmp
              self.pos = _save4
              break
            end
            @result = begin;          " " ; end
            _tmp = true
            unless _tmp
              self.pos = _save4
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save
      
    _save5 = self.pos
          while true # sequence
            _tmp = match_string("\\:")
            unless _tmp
              self.pos = _save5
              break
            end
            @result = begin;          ":" ; end
            _tmp = true
            unless _tmp
              self.pos = _save5
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save
      
    _save6 = self.pos
          while true # sequence
            _tmp = match_string("\\\\")
            unless _tmp
              self.pos = _save6
              break
            end
            @result = begin;          "\\" ; end
            _tmp = true
            unless _tmp
              self.pos = _save6
            end
            break
          end # end sequence

          break if _tmp
          self.pos = _save
          break
        end # end choice

    return _tmp
  end

  # dbl_seq = < /[^\\"]+/ > { text }
  def _dbl_seq
    
    _save = self.pos
        while true # sequence
          _text_start = self.pos
          _tmp = scan(/\A(?-mix:[^\\"]+)/)
          if _tmp
            text = get_text(_text_start)
          end
          unless _tmp
            self.pos = _save
            break
          end
          @result = begin;        text ; end
          _tmp = true
          unless _tmp
            self.pos = _save
          end
          break
        end # end sequence

    return _tmp
  end

  # dbl_not_quote = (dbl_escapes | dbl_seq)+:ary { ary }
  def _dbl_not_quote
    
    _save = self.pos
        while true # sequence
          _save1 = self.pos
          _ary = []
      
    _save2 = self.pos
          while true # choice
            _tmp = apply(:_dbl_escapes)
            break if _tmp
            self.pos = _save2
            _tmp = apply(:_dbl_seq)
            break if _tmp
            self.pos = _save2
            break
          end # end choice

          if _tmp
              _ary << @result
              while true
                        
    _save3 = self.pos
              while true # choice
                _tmp = apply(:_dbl_escapes)
                break if _tmp
                self.pos = _save3
                _tmp = apply(:_dbl_seq)
                break if _tmp
                self.pos = _save3
                break
              end # end choice

                  _ary << @result if _tmp
                  break unless _tmp
                end
                _tmp = true
                @result = _ary
              else
                self.pos = _save1
              end
              ary = @result
              unless _tmp
                self.pos = _save
                break
              end
              @result = begin;            ary ; end
              _tmp = true
              unless _tmp
                self.pos = _save
              end
              break
            end # end sequence

    return _tmp
  end

  # dbl_string = "\"" dbl_not_quote:ary "\"" { ary.join }
  def _dbl_string
        
    _save = self.pos
            while true # sequence
              _tmp = match_string("\"")
              unless _tmp
                self.pos = _save
                break
              end
              _tmp = apply(:_dbl_not_quote)
              ary = @result
              unless _tmp
                self.pos = _save
                break
              end
              _tmp = match_string("\"")
              unless _tmp
                self.pos = _save
                break
              end
              @result = begin;            ary.join ; end
              _tmp = true
              unless _tmp
                self.pos = _save
              end
              break
            end # end sequence

    return _tmp
  end

  # not_space_colon = (escapes | < /[^ \t\n:]/ > { text })
  def _not_space_colon
        
    _save = self.pos
            while true # choice
              _tmp = apply(:_escapes)
              break if _tmp
              self.pos = _save
          
    _save1 = self.pos
              while true # sequence
                _text_start = self.pos
                _tmp = scan(/\A(?-mix:[^ \t\n:])/)
                if _tmp
                  text = get_text(_text_start)
                end
                unless _tmp
                  self.pos = _save1
                  break
                end
                @result = begin;              text ; end
                _tmp = true
                unless _tmp
                  self.pos = _save1
                end
                break
              end # end sequence

              break if _tmp
              self.pos = _save
              break
            end # end choice

    return _tmp
  end

  # not_space_colons = not_space_colon+:ary { ary.join }
  def _not_space_colons
        
    _save = self.pos
            while true # sequence
              _save1 = self.pos
              _ary = []
              _tmp = apply(:_not_space_colon)
              if _tmp
                  _ary << @result
                  while true
                                    _tmp = apply(:_not_space_colon)
                      _ary << @result if _tmp
                      break unless _tmp
                    end
                    _tmp = true
                    @result = _ary
                  else
                    self.pos = _save1
                  end
                  ary = @result
                  unless _tmp
                    self.pos = _save
                    break
                  end
                  @result = begin;                ary.join ; end
                  _tmp = true
                  unless _tmp
                    self.pos = _save
                  end
                  break
                end # end sequence

    return _tmp
  end

  # filename = (dbl_string | not_space_colons)
  def _filename
            
    _save = self.pos
                while true # choice
                  _tmp = apply(:_dbl_string)
                  break if _tmp
                  self.pos = _save
                  _tmp = apply(:_not_space_colons)
                  break if _tmp
                  self.pos = _save
                  break
                end # end choice

    return _tmp
  end

  # file_pos_sep = (sp+ | ":")
  def _file_pos_sep
            
    _save = self.pos
                while true # choice
                  _save1 = self.pos
                  _tmp = apply(:_sp)
                  if _tmp
                      while true
                                            _tmp = apply(:_sp)
                          break unless _tmp
                        end
                        _tmp = true
                      else
                        self.pos = _save1
                      end
                      break if _tmp
                      self.pos = _save
                      _tmp = match_string(":")
                      break if _tmp
                      self.pos = _save
                      break
                    end # end choice

    return _tmp
  end

  # integer = < /[0-9]+/ > { text.to_i }
  def _integer
                
    _save = self.pos
                    while true # sequence
                      _text_start = self.pos
                      _tmp = scan(/\A(?-mix:[0-9]+)/)
                      if _tmp
                        text = get_text(_text_start)
                      end
                      unless _tmp
                        self.pos = _save
                        break
                      end
                      @result = begin;                    text.to_i ; end
                      _tmp = true
                      unless _tmp
                        self.pos = _save
                      end
                      break
                    end # end sequence

    return _tmp
  end

  # line_number = integer
  def _line_number
                    _tmp = apply(:_integer)
    return _tmp
  end

  # vm_offset = "@" integer:int {     Position.new(nil, nil, :offset, int)   }
  def _vm_offset
                
    _save = self.pos
                    while true # sequence
                      _tmp = match_string("@")
                      unless _tmp
                        self.pos = _save
                        break
                      end
                      _tmp = apply(:_integer)
                      int = @result
                      unless _tmp
                        self.pos = _save
                        break
                      end
                      @result = begin;                   
    Position.new(nil, nil, :offset, int)
  ; end
                      _tmp = true
                      unless _tmp
                        self.pos = _save
                      end
                      break
                    end # end sequence

    return _tmp
  end

  # position = (vm_offset | line_number:l {    Position.new(nil, nil, :line, l)  })
  def _position
                
    _save = self.pos
                    while true # choice
                      _tmp = apply(:_vm_offset)
                      break if _tmp
                      self.pos = _save
                  
    _save1 = self.pos
                      while true # sequence
                        _tmp = apply(:_line_number)
                        l = @result
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        @result = begin;                      
  Position.new(nil, nil, :line, l) 
; end
                        _tmp = true
                        unless _tmp
                          self.pos = _save1
                        end
                        break
                      end # end sequence

                      break if _tmp
                      self.pos = _save
                      break
                    end # end choice

    return _tmp
  end

  # file_colon_line = file_no_colon:file &{ File.exist?(file) } ":" position:pos {    Position.new(:file, file, pos.position_type, pos.position)  }
  def _file_colon_line
                
    _save = self.pos
                    while true # sequence
                      _tmp = apply(:_file_no_colon)
                      file = @result
                      unless _tmp
                        self.pos = _save
                        break
                      end
                      _save1 = self.pos
                      _tmp = begin;  File.exist?(file) ; end
                      self.pos = _save1
                      unless _tmp
                        self.pos = _save
                        break
                      end
                      _tmp = match_string(":")
                      unless _tmp
                        self.pos = _save
                        break
                      end
                      _tmp = apply(:_position)
                      pos = @result
                      unless _tmp
                        self.pos = _save
                        break
                      end
                      @result = begin;                    
  Position.new(:file, file, pos.position_type, pos.position) 
; end
                      _tmp = true
                      unless _tmp
                        self.pos = _save
                      end
                      break
                    end # end sequence

    return _tmp
  end

  # location = (position | < filename >:file &{ @file_exists_proc.call(file) } file_pos_sep position:pos {       Position.new(:file, file, pos.position_type, pos.position)     } | < filename >:file &{ @file_exists_proc.call(file) } {       Position.new(:file, file, nil, nil)     } | class_module_chain?:fn file_pos_sep position:pos {       Position.new(:fn, fn, pos.position_type, pos.position)     } | class_module_chain?:fn {       Position.new(:fn, fn, nil, nil)     })
  def _location
                
    _save = self.pos
                    while true # choice
                      _tmp = apply(:_position)
                      break if _tmp
                      self.pos = _save
                  
    _save1 = self.pos
                      while true # sequence
                        _text_start = self.pos
                        _tmp = apply(:_filename)
                        if _tmp
                          text = get_text(_text_start)
                        end
                        file = @result
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        _save2 = self.pos
                        _tmp = begin;  @file_exists_proc.call(file) ; end
                        self.pos = _save2
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        _tmp = apply(:_file_pos_sep)
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        _tmp = apply(:_position)
                        pos = @result
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        @result = begin;                     
      Position.new(:file, file, pos.position_type, pos.position)
    ; end
                        _tmp = true
                        unless _tmp
                          self.pos = _save1
                        end
                        break
                      end # end sequence

                      break if _tmp
                      self.pos = _save
                  
    _save3 = self.pos
                      while true # sequence
                        _text_start = self.pos
                        _tmp = apply(:_filename)
                        if _tmp
                          text = get_text(_text_start)
                        end
                        file = @result
                        unless _tmp
                          self.pos = _save3
                          break
                        end
                        _save4 = self.pos
                        _tmp = begin;  @file_exists_proc.call(file) ; end
                        self.pos = _save4
                        unless _tmp
                          self.pos = _save3
                          break
                        end
                        @result = begin;                     
      Position.new(:file, file, nil, nil)
    ; end
                        _tmp = true
                        unless _tmp
                          self.pos = _save3
                        end
                        break
                      end # end sequence

                      break if _tmp
                      self.pos = _save
                  
    _save5 = self.pos
                      while true # sequence
                        _save6 = self.pos
                        _tmp = apply(:_class_module_chain)
                        @result = nil unless _tmp
                        unless _tmp
                          _tmp = true
                          self.pos = _save6
                        end
                        fn = @result
                        unless _tmp
                          self.pos = _save5
                          break
                        end
                        _tmp = apply(:_file_pos_sep)
                        unless _tmp
                          self.pos = _save5
                          break
                        end
                        _tmp = apply(:_position)
                        pos = @result
                        unless _tmp
                          self.pos = _save5
                          break
                        end
                        @result = begin;                     
      Position.new(:fn, fn, pos.position_type, pos.position)
    ; end
                        _tmp = true
                        unless _tmp
                          self.pos = _save5
                        end
                        break
                      end # end sequence

                      break if _tmp
                      self.pos = _save
                  
    _save7 = self.pos
                      while true # sequence
                        _save8 = self.pos
                        _tmp = apply(:_class_module_chain)
                        @result = nil unless _tmp
                        unless _tmp
                          _tmp = true
                          self.pos = _save8
                        end
                        fn = @result
                        unless _tmp
                          self.pos = _save7
                          break
                        end
                        @result = begin;                     
      Position.new(:fn, fn, nil, nil)
    ; end
                        _tmp = true
                        unless _tmp
                          self.pos = _save7
                        end
                        break
                      end # end sequence

                      break if _tmp
                      self.pos = _save
                      break
                    end # end choice

    return _tmp
  end

  # if_unless = < ("if" | "unless") > { text }
  def _if_unless
                
    _save = self.pos
                    while true # sequence
                      _text_start = self.pos
                  
    _save1 = self.pos
                      while true # choice
                        _tmp = match_string("if")
                        break if _tmp
                        self.pos = _save1
                        _tmp = match_string("unless")
                        break if _tmp
                        self.pos = _save1
                        break
                      end # end choice

                      if _tmp
                        text = get_text(_text_start)
                      end
                      unless _tmp
                        self.pos = _save
                        break
                      end
                      @result = begin;                    text ; end
                      _tmp = true
                      unless _tmp
                        self.pos = _save
                      end
                      break
                    end # end sequence

    return _tmp
  end

  # condition = < /.+/ > { text}
  def _condition
                
    _save = self.pos
                    while true # sequence
                      _text_start = self.pos
                      _tmp = scan(/\A(?-mix:.+)/)
                      if _tmp
                        text = get_text(_text_start)
                      end
                      unless _tmp
                        self.pos = _save
                        break
                      end
                      @result = begin;                    text; end
                      _tmp = true
                      unless _tmp
                        self.pos = _save
                      end
                      break
                    end # end sequence

    return _tmp
  end

  # breakpoint_stmt_no_condition = location:loc {   Breakpoint.new(loc, false, 'true') }
  def _breakpoint_stmt_no_condition
                
    _save = self.pos
                    while true # sequence
                      _tmp = apply(:_location)
                      loc = @result
                      unless _tmp
                        self.pos = _save
                        break
                      end
                      @result = begin;                   
  Breakpoint.new(loc, false, 'true')
; end
                      _tmp = true
                      unless _tmp
                        self.pos = _save
                      end
                      break
                    end # end sequence

    return _tmp
  end

  # breakpoint_stmt = (location:loc - if_unless:iu - condition:cond {      Breakpoint.new(loc, iu == 'unless', cond) } | breakpoint_stmt_no_condition)
  def _breakpoint_stmt
                
    _save = self.pos
                    while true # choice
                  
    _save1 = self.pos
                      while true # sequence
                        _tmp = apply(:_location)
                        loc = @result
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        _tmp = apply(:__hyphen_)
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        _tmp = apply(:_if_unless)
                        iu = @result
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        _tmp = apply(:__hyphen_)
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        _tmp = apply(:_condition)
                        cond = @result
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        @result = begin;                     
     Breakpoint.new(loc, iu == 'unless', cond)
; end
                        _tmp = true
                        unless _tmp
                          self.pos = _save1
                        end
                        break
                      end # end sequence

                      break if _tmp
                      self.pos = _save
                      _tmp = apply(:_breakpoint_stmt_no_condition)
                      break if _tmp
                      self.pos = _save
                      break
                    end # end choice

    return _tmp
  end

  # list_special_targets = < ("." | "-") > { text }
  def _list_special_targets
                
    _save = self.pos
                    while true # sequence
                      _text_start = self.pos
                  
    _save1 = self.pos
                      while true # choice
                        _tmp = match_string(".")
                        break if _tmp
                        self.pos = _save1
                        _tmp = match_string("-")
                        break if _tmp
                        self.pos = _save1
                        break
                      end # end choice

                      if _tmp
                        text = get_text(_text_start)
                      end
                      unless _tmp
                        self.pos = _save
                        break
                      end
                      @result = begin;                    text ; end
                      _tmp = true
                      unless _tmp
                        self.pos = _save
                      end
                      break
                    end # end sequence

    return _tmp
  end

  # list_stmt = ((list_special_targets | location):loc - integer:int? {   List.new(loc, int) } | (list_special_targets | location):loc {   List.new(loc, nil) })
  def _list_stmt
                
    _save = self.pos
                    while true # choice
                  
    _save1 = self.pos
                      while true # sequence
                    
    _save2 = self.pos
                        while true # choice
                          _tmp = apply(:_list_special_targets)
                          break if _tmp
                          self.pos = _save2
                          _tmp = apply(:_location)
                          break if _tmp
                          self.pos = _save2
                          break
                        end # end choice

                        loc = @result
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        _tmp = apply(:__hyphen_)
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        _save3 = self.pos
                        _tmp = apply(:_integer)
                        int = @result
                        unless _tmp
                          _tmp = true
                          self.pos = _save3
                        end
                        unless _tmp
                          self.pos = _save1
                          break
                        end
                        @result = begin;                     
  List.new(loc, int)
; end
                        _tmp = true
                        unless _tmp
                          self.pos = _save1
                        end
                        break
                      end # end sequence

                      break if _tmp
                      self.pos = _save
                  
    _save4 = self.pos
                      while true # sequence
                    
    _save5 = self.pos
                        while true # choice
                          _tmp = apply(:_list_special_targets)
                          break if _tmp
                          self.pos = _save5
                          _tmp = apply(:_location)
                          break if _tmp
                          self.pos = _save5
                          break
                        end # end choice

                        loc = @result
                        unless _tmp
                          self.pos = _save4
                          break
                        end
                        @result = begin;                     
  List.new(loc, nil)
; end
                        _tmp = true
                        unless _tmp
                          self.pos = _save4
                        end
                        break
                      end # end sequence

                      break if _tmp
                      self.pos = _save
                      break
                    end # end choice

    return _tmp
  end
end
if __FILE__ == $0
  # require 'rubygems'; require_relative '../lib/trepanning';
  
  cp = CmdParse.new('', :debug=>true)
  %w(A::B @@classvar abc01! @ivar @ivar.meth
    Object A::B::C A::B::C::D A::B.c A.b.c.d).each do |name|
    cp.setup_parser(name, true)
    # debugger if name == '@ivar.meth'
    res = cp._class_module_chain
    p res
    p cp.string
    p cp.result
  end
  %w(A::B:5 A::B:@5 @@classvar abc01!:10 @ivar).each do |name|
    cp.setup_parser(name, true)
    res = cp._location
    p res
    p cp.string
    p cp.result
  end
  # require 'trepanning'; 
  ["#{__FILE__}:10", 'A::B  5',
   "#{__FILE__} 20"].each do |name|
    cp.setup_parser(name, {:debug=>true})
    res = cp._location
    p res
    p cp.string
    p cp.result
  end

  ['filename', '"this is a filename"',
   'this\ is\ another\ filename',
   'C\:filename'
   ].each do |name|
    puts '-' * 10
    cp.setup_parser(name, {:debug=>true})
    res = cp._filename
    p res
    puts cp.string
    puts cp.result
  end
end
