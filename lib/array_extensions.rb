Array.class_eval do
  # def shuffle
  #   sort_by { rand }
  # end
  # 
  # def shuffle!
  #   self = shuffle
  # end

  def shuffle!
    size.downto(1) { |n| push delete_at(rand(n)) }
    self
  end

  # def mid(minimum=min,maximum=max)
  #   diff = maximum - minimum
  #   minimum + (diff / 2)
  # end

  def sum &block
    if block_given?
      (self.collect block).sum_without_block
    else
      sum_without_block
    end
  end

  def sum_without_block
    sum = 0
    self.each do |val|
      sum += val
    end
    sum
  end

  def random_pick
    self[rand(self.size)]
  end
end
