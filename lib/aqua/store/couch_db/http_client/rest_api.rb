# HTTP Adapters should implement the following to be used with the RestAPI module
# 
# def self.get(uri, headers=nil)
# end
# 
# def self.post(uri, hash, headers=nil)
# end
# 
# def self.put(uri, hash, headers=nil)
# end
# 
# def self.delete(uri, headers=nil)
# end
# 
# def self.copy(uri, headers)
# end        

module RestAPI
  def self.adapter=( klass )
    @adapter = klass
  end
  
  def self.adapter
    @adapter
  end     
  
  def put(uri, doc = nil)
    hash = doc.to_json if doc
    response = RestAPI.adapter.put( uri, hash )
    JSON.parse( response )
  end

  def get(uri) 
    response = RestAPI.adapter.get(uri)
    JSON.parse( response , :max_nesting => false)
  end

  def post(uri, doc = nil)
    hash = doc.to_json if doc 
    response = RestAPI.adapter.post(uri, hash)
    JSON.parse( response )
  end

  def delete(uri) 
    response = RestAPI.adapter.delete(uri)
    JSON.parse( response )
  end

  def copy(uri, destination)
    response = RestAPI.adapter.copy(uri, {'Destination' => destination}) 
    JSON.parse( response )
  end 

end