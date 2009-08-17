require 'rest_client'

module RestClientAdapter
  def self.convert_exception(&blk)
    begin
      yield
    rescue Exception => e
      ending = e.class.to_s.match(/[a-z0-9_]*\z/i)
      begin
        error = "Aqua::Store::CouchDB::#{ending}".constantize
      rescue
        raise e
      end
      raise error, e.message    
    end    
  end  
  
  def self.get(uri, headers={})
    convert_exception do 
      RestClient.get(uri, headers)
    end    
  end

  def self.post(uri, hash, headers={})
    convert_exception do
      RestClient.post(uri, hash, headers)
    end  
  end

  def self.put(uri, hash, headers={})
    convert_exception do
      RestClient.put(uri, hash, headers)
    end  
  end

  def self.delete(uri, headers={})
    convert_exception do 
      RestClient.delete(uri, headers)
    end  
  end

  def self.copy(uri, headers)
    convert_exception do 
      RestClient::Request.execute(  :method   => :copy,
                                    :url      => uri,
                                    :headers  => headers) 
    end                                
  end 
end