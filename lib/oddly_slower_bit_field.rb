#require 'rubygems'
#require 'inline'
class BitField
  include Enumerable
  attr_reader :size

  def initialize(size)
    @size = size
    @field = 0
  end

  def []=(position,value)
    return if value == self[position]
    value == 0 ? @field ^= 1 << position : @field |= 1 << position
  end

  def set(position)
    self[position] = 1
  end

  def clear(position)
    self[position] = 0
  end

  def [](position)
    @field[position]
    #getbit(@field,position)
  end

#  inline(:C) do |builder|
#    builder.c "int getbit(char *z, int position) {
#      if (z[position/8] & (1<<(position%8)))
#        return 1;
#      return 0;
#    }"
#  end


  def is_set?(position)
    @field[position] == 1
  end

  def each(&block)
    @size.times { |position| yield @field[position] }
  end

  def are_set
    @result = Array.new
    @size.times { |position| self.is_set?(position) and @result << position }
    return @result
  end

  def to_s
    return inject("") { |string,position| string + position.to_s }
  end

  def clear_all
    @field = 0
  end

  def set_all
    @field = (2 ** (@size+1)) -1
  end
end

