NilClass.class_eval do
  def [](*args)
    return true
  end
end
# []' on nil:NilClass
