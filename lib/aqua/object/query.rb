module Aqua::Query
  
  def self.included( klass ) 
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
    end  
  end 
  
  module ClassMethods
  end
  
  module InstanceMethods
  end

end   