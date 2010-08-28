class BitField
  attr_reader :size, :element_width
  include Enumerable

  SMALL = 32
  MEDIUM = 64
  LARGE = 128

  def initialize(size)
    @size = size
    @element_width = (size < SMALL) ? SMALL : (size >= SMALL) ? MEDIUM : (size >= MEDIUM) ? LARGE : size + 1
    # puts "size: #{size} => ew: #{@element_width}"
    @field = Array.new(((size - 1) / element_width) + 1, 0)
  end

  # Set a bit (1/0)
  def []=(position, value)
    if value == 1
      @field[position / element_width] |=1 << (position % element_width)
    elsif (@field[position / element_width]) & (1 << (position % element_width)) != 0
      @field[position / element_width] ^= 1 << (position % element_width)
    end
  end

  # Read a bit (1/0)
  def [](position)
    @field[position / element_width] & 1 << (position % element_width) > 0 ? 1 : 0
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
