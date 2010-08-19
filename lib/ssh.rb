class Ssh
  require 'rubygems'
  require 'net/ssh'
  attr_accessor :user, :host, :connection, :cmd

  def initialize
    @host, @user, @cmd = nil
  end

  def connect(host,user,pwd)
    @host = host
    @user = user
    @connection = Net::SSH.start(@host,  @user, :password => pwd)
  end

  def do(cmd)
    @cmd = cmd
    @connection.exec! @cmd
  end

  def close
    @connection.close
  end

  # ssh = Ssh.new
  # ssh.connect(h,u,p)
  # ssh.connection.exec! cmd
  # ssh.close
end

