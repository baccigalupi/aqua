dir = File.dirname(__FILE__)
require dir + '/pack'
require dir + '/query'
require dir + '/unpack'
require dir + '/config'

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
  def self.aquatic( opts=nil )
    include Aqua::Tank
    configure_aqua( opts ) if opts
  end   
end  
    