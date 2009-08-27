class Gerbilmiester
  aquatic :embed => [:gerbil, :bacon]
  
  # saved state instance variable
  def gerbil
    @gerbil ||= true
  end
  
  # not an instance method with saved state, 
  # but we should be able to stub this.
  def bacon
    'chunky' 
  end 
  
  def herd
    gerbil ? 'Yah, yah, little gerbil' : 'Nothing to herd here, move along!'
  end     
end 