module RestAPI
  def self.adapter=( klass )
    @adapter = klass
  end
  
  def self.adapter
    @adapter
  end     
  
  def put(uri, object = nil)
    hash = object.to_persist if doc
    begin
      JSON.parse( RestAPI.adapter.put( uri, hash ) )
    rescue Exception => e
      if $DEBUG
        raise "Error while sending a PUT request #{uri}\n#to_persist hash: #{hash.inspect}\n#{e}"
      else
        raise e
      end
    end
  end

  def get(uri)
    begin
      JSON.parse( RestAPI.adapter.get(uri), :max_nesting => false)
    rescue => e
      if $DEBUG
        raise "Error while sending a GET request #{uri}\n: #{e}"
      else
        raise e
      end
    end
  end

  def post(uri, doc = nil)
    hash = doc.to_persist if doc
    begin
      JSON.parse( RestAPI.adapter.post(uri, hash))
    rescue Exception => e
      if $DEBUG
        raise "Error while sending a POST request #{uri}\n#to_persist hash: #{hash.inspect}\n#{e}"
      else
        raise e
      end
    end
  end

  def delete(uri)
    JSON.parse(RestAPI.adapter.delete(uri))
  end

  def copy(uri, destination) 
    JSON.parse(RestAPI.adapter.copy(uri, {'Destination' => destination}))
  end 

end