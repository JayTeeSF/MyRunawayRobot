NilClass.class_eval do
  def blank?
    true
  end
  def empty?
    true
  end
  def [](*args)
    return true
  end
  def min
    1000000
  end
  def max
    1000000
  end
end
# []' on nil:NilClass
