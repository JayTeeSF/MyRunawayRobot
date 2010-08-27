class BitField
  attr_reader :size
  include Enumerable

  ELEMENT_WIDTH = 32

  def initialize(size)
    @size = size
    @field = Array.new(((size - 1) / ELEMENT_WIDTH) + 1, 0)
  end
  
  # Set a bit (1/0)
  def []=(position, value)
    if value == 1
      @field[position / ELEMENT_WIDTH] |=1 << (position % ELEMENT_WIDTH)
    elsif (@field[position / ELEMENT_WIDTH]) & (1 << (position % ELEMENT_WIDTH)) != 0
      @field[position / ELEMENT_WIDTH] ^= 1 << (position % ELEMENT_WIDTH)
    end
  end

  # Read a bit (1/0)
  def [](position)
    @field[position / ELEMENT_WIDTH] & 1 << (position % ELEMENT_WIDTH) > 0 ? 1 : 0
  end

  # Iterate over each bit
  def each(&block)
    @size.times { |position| yield self[position] }
  end

  # Return field as string "0101000"
  def to_s
    inject("") { |a, b| a + b.to_s }
  end

  # Return total # of bits that are set
  def total_set
    @field.inject(0) { |a, byte| a += byte & 1 and byte >>= 1 until byte == 0; a }
  end

end
