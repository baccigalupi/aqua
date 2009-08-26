class User
  aquatic :embed => { :stub => :username }
  
  attr_accessor :name, # An array of strings or a hash of strings 
    :created_at,# Time
    :dob,       # Date
    :username,  # simple string 
    :log,       # an Aquatic Object 
    :password,  # hidden value
    :grab_bag,   # non Aquatic Object
    :other_user # a non-embeddable Aquatic Object
  hide_attributes :password
  
  def initialize( hash={} )
    hash.each do |key, value|
      send( "#{key}=", value )
    end  
  end  
  
  
  # convenience methods for inspection during testing
  # ------------------------------------------------- 
  
  def simple_classes
    _simple_classes
  end 
  
  # for testing whether attributse are hidden
  def visible_attr 
    _storable_attributes
  end

  # for testing class level configuration options
  def self.aquatic_options
    _aqua_opts
  end
         
end 