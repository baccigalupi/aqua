dir = File.dirname(__FILE__)
require dir + '/pack'
require dir + '/packer'
require dir + '/query'
require dir + '/unpacker'
require dir + '/unpack'
require dir + '/config'
require dir + '/stub'

module Aqua::Tank
  def self.included( klass )
    klass.class_eval do
      include Aqua::Pack
      include Aqua::Unpack
      include Aqua::Config
      include Aqua::Query 
    end
  end
end

# Adds class method for declaring an object as 
Object.class_eval do
  
  # Used in class declarations to load an Aqua::Tank into the class, making it Aqua persistable
  #
  # @param [Hash]
  # @option opts [String] :database Database name to use
  # @option opts [true, false, Hash] :embed 
  #   True will embed the object in another when it appears in an instance variable 
  #   False will store it in its own document 
  #   When size 1 hash which :stub as the key. It will store the object separately, but save certain values into the object.
  #
  # @api public 
  def self.aquatic( opts=nil )
    include Aqua::Tank
    configure_aqua( opts ) if opts
  end
  
  # Returns true of false depending on whether the class has Aqua::Tank modules extended into it. 
  # @return [true, false] 
  # 
  # @api public
  def self.aquatic?
    respond_to?( :configure_aqua )
  end  
  
  # Returns true of false depending on whether object instance has Aqua::Tank modules included. 
  # @return [true, false] 
  # 
  # @api public
  def aquatic?
    self.class.aquatic?
  end  
     
end  
    