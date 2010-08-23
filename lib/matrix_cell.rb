class MatrixCell
  
  include Comparable

  attr_accessor :down, :right, :value
  
  def initialize(width, down, right, ascii_char)
    @down = down # 0-based
    @right = right # 0-based
  
    @ascii_char = ascii_char # Map.value_of ascii_char
    
    # unique-cell-value
    @value = (width * @down) + distance
  end
  
  def distance
    down + right
  end
  
  def <=>(anOther)
    value <=> anOther.value
  end

end