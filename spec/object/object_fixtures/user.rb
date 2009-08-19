class User
  include Aqua::Tank
  
  attr_accessor :name, :dob, :username, :log, :password
  hide_attributes :password
  
  # convenience methods for inspection during testing 
  def to_store
    _pack
    __pack
  end
  
  def visible_attr 
    _storable_attributes
  end
  
       
end 