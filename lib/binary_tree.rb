# require './lib/binary_tree.rb'; bt = BinaryTree.new; bt.add(3); puts bt

# bt.add(2)
# bt.add(88)
# bt.find(88)
# #<BinaryTreeNode:0x1010573f8 @value=88>

# puts bt.find(88)
# 88
#	-> 	nil
#	-> 	nil
# => nil 

# bt.find(33)
# => nil

module BinaryTreeHelper
  private
  def add_or_create node, val
    # puts "initial node: #{node.inspect}"
    node ? node.add(val) : node = BinaryTreeNode.new(val)
    # puts "final-node:#{node.inspect}; val:#{val.inspect}"    
    node
  end
end

class BinaryTreeNode
  include BinaryTreeHelper
  attr_accessor :value, :left, :right
  
  def initialize(val)
    @value = val
  end

  def add(val)
    if (val < @value)
    @left = add_or_create(@left, val)
  else
    @right = add_or_create(@right, val)
  end
    # puts "value-ivar: #{@value.inspect}left-ivar: #{@left.inspect}; right-ivar: #{@right.inspect}; val: #{val.inspect}"
  end
  
  def to_s(tabs="")
    child_tabs = "#{tabs}\t"
<<EON
#{tabs}#{@value.inspect}
#{child_tabs}-> #{@left ? @left.to_s(child_tabs) : "#{child_tabs}nil"}
#{child_tabs}-> #{@right ? @right.to_s(child_tabs) : "#{child_tabs}nil"}
EON
  end
end

class BinaryTree
  include BinaryTreeHelper
  attr_accessor :root
  
  def initialize(val=nil)
    add(val) if val
  end
  
  def add(val)
    # puts "initial root-ivar: #{@root.inspect}"
    @root = add_or_create(@root, val)
    # puts "root-ivar: #{@root.inspect}; val: #{val.inspect}"
  end
  
  # need to balance my tree!
  # ?need min/max ?
  
  def min(node=@root)
    return node if node.left.nil?
    min(node.left)
  end
  
  def max(node=@root)
    return node if node.right.nil?
    min(node.right)
  end
  
  def find(val, node=@root)
    return node if !node || node.value == val || nil == val

    if val < node.value
      return find(val, node.left)
    else
      return find(val, node.right)
    end
  end
  
  def to_s
<<EOT
  |
  v
  #{@root.to_s}
EOT
  end
end