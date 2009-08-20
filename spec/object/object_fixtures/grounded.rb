require 'ostruct'
# this is a non-aquatic object
class Grounded 
  def initialize( hash = {} )
    hash.each do |key, value|
      send( "#{key}=", value )
    end 
  end
  
  attr_accessor :hash_up, # a hash
   :arraynged, # an array
   :openly_structured # an ostruct
end    