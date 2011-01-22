require 'coderay/encoders/term'
TERM_TOKEN_COLORS = {
  :comment => '1;36',    # yellow brownish
  :global_variable => '36',  # yellow brownish 
  :regexp => {
    :content => '33',  # light turquoise (from read)
    :delimiter => '1;29',
    :modifier => '35',
    :function => '1;29'
  },
  :reserved => '1;32',  # green (from red)
  :symbol   => '35',    # purple
}
module CodeRay::Encoders
  class Term < Encoder
    TERM_TOKEN_COLORS.each_pair do |key, value|
      TOKEN_COLORS[key] = value
    end
  end
end
