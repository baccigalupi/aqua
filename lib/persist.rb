# require gems
require 'rubygems'
begin
  require 'json'
rescue LoadError
  raise "JSON constant not found. Please install a JSON library." unless Kernel.const_defined?("JSON")
end

require 'cgi'

# require local libs
$:.unshift File.join(File.dirname(__FILE__))
require 'persist/support/mash'
require 'persist/support/string_extensions'
require 'persist/http_client/rest_api'
require 'persist/server'
require 'persist/database'


module Persist
  # A convenience method for escaping a string,
  # namespaced classes with :: notation will be converted to __ 
  # all other non-alpha numeric characters besides hyphens and underscores are removed
  def self.escape( str )
    str.gsub!('::', '__')
    str.gsub!(/[^a-z0-9\-_]/, '')
    str
  end  
  
  # There is only one adapter per Persist module class.
  # Calling Persist.http_adapter will automatically load the default
  # adapter, which is RestClient
  def self.http_adapter
    @adapter ||= set_http_adapter
  end  
  
  # NOTE: I think this drop in adapter interface could be simpler. 
  # Not sure we need both the RestAPI converter and the 
  
  # Sets a class variable with the library name that will be loaded.
  # Then attempts to load said library from the adapter directory.
  # It is extended into the HttpAbstraction module. Then the RestAPI which 
  # references the HttpAbstraction module is loaded/extended into Persist
  # this makes available Persist.get 'http:://someaddress.com' and other requests 
  def self.set_http_adapter( mod_string='RestClientAdapter' )
    
    # what is happening here:
    # strips the Adapter portion of the module name to get at the client name
    # convention over configurationing to get the file name as it relates to files in http_client/adapter
    # require the hopefully found file
    # modify the RestAPI class to extend the Rest methods from the adapter
    # add the RestAPI to Persist for easy access throughout the library
     
    @adapter = mod_string
    mod = @adapter.gsub(/Adapter/, '')
    file = mod.underscore
    require "persist/http_client/adapter/#{file}"
    RestAPI.adapter = "#{mod_string}".constantize
    extend(::RestAPI)
    @adapter  # return the adapter 
  end 
  
  def self.paramify_url( url, params = {} )
    if params && !params.empty?
      query = params.collect do |k,v|
        v = v.to_json if %w{key startkey endkey}.include?(k.to_s)
        "#{k}=#{CGI.escape(v.to_s)}"
      end.join("&")
      url = "#{url}?#{query}"
    end
    url
  end
  
  # Module attribute accessor server: allows conservation of memory so that an new server 
  # is not instantiated for each class/database. 
  def self.server
    @server
  end
  
  def self.server=( s )
    @server = s
  end
  
  # auto loads the default http_adapter if Persist gets used without configuration
  class << self     
    def method_missing( method )
      if @adapter.nil?
        http_adapter
        self.send( method.to_sym )
      end    
    end
  end  
  
  class ResourceNotFound      < IOError; end
  class RequestFailed         < IOError; end
  class RequestTimeout        < IOError; end
  class ServerBrokeConnection < IOError; end
  class Conflict              < ArgumentError; end
   
end # Persist  