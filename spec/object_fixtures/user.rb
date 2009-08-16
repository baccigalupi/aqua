class User
  include Persist::Pack
  
  attr_accessor :name
  attr_accessor :dob 
  
  def to_store
    _pack
    __pack
  end  
end 