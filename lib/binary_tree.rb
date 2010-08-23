class BinaryTree
  include BinaryTreeHelper
  def add(value)
    add_or_create(@root, value)
  end
end

class BinaryTreeNode
  include BinaryTreeHelper
  def initialize(value)
    @value = value
  end

  def add(value)
    add_or_create((value < @value) ? @left : @right, value)
  end
end

module BinaryTreeHelper
  private
  def add_or_create node, value
    node ? node.add(value) : node = BinaryTreeNode.new(value)
  end
end
