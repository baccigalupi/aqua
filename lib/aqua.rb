# DEPENDENCIES -------------------------------------
# require gems
require 'rubygems' 
require 'ruby2ruby'
require 'mime/types'
# Pick your json poison. Just make sure that in adds the JSON constant
unless defined?(JSON)
  begin
    require 'json'
  rescue LoadError
    raise LoadError, "JSON constant not found. Please install a JSON library"
  end  
end
# There is also a dependency on the http_client of your choosing. Currently only ...
# require 'rest_client'
# It is required when a libarary is configured. If the library is not configured then it will 
# automatically load the default: rest_client

# standard libraries
require 'cgi'
require 'time'
require 'ostruct'
require 'tempfile'

# require local libs
$:.unshift File.join(File.dirname(__FILE__))
  # monkey pathches
require 'aqua/support/mash'
require 'aqua/support/string_extensions'
  # object methods
require 'aqua/object/tank'
  # a little more monkey patching for object packaging
require 'aqua/support/initializers'
  # storage 
require 'aqua/store/storage' 


# LIBRARY SETUP -----------------------------------
module Aqua
  class ObjectNotFound < IOError; end
  
  # Loads the requested backend storage engine. Used early on in configuration. 
  # If not declared in configuration, will be called automatically with default 
  # engine, at runtime, when needed.
  #
  # @overload set_storage_engine( engine )
  #   Loads an Aqua internal library.
  #   @param [String] CamelCase string defining the overarching engine type
  # @overload set_storage_engine( engine_details )
  #   Loads any engine provided a path to the self-loading library and the module full name
  #   @param [Hash] options that describe how to find the external library
  #   @option engine_details [String] :require The path or gem name used in a require statement
  #   @option engine_details [String] :module String with the full module name
  # @return [TrueClass] when successful. 
  # @raise [ArgumentError] when argument is neither a Hash nor a String.
  # 
  # @example Internal library loading from a string
  #   Aqua.set_storage_engine( "CouchDB" )
  #
  # @example External library loading from a gem. :module argument is the gem's module responsible for implementing the storage methods
  #   Aqua.set_storage_engine( :require => 'my_own/storage_gem', :module => 'MyOwn::StorageGem::StorageMethods' )
  #
  # @example External library loading from a non-gem external library. 
  #   Aqua.set_storage_engine( :require => '/absolute/path/to/library', :module => 'My::StorageLib::StorageMethods' )
  #
  # @api public
  def self.set_storage_engine( engine="CouchDB" ) 
    if engine.class == String
      load_internal_engine( engine )
      true
    elsif engine.class == Hash
      engine = Mash.new( engine )
      require engine[:require]
      include_engine( engine[:module] )
      true
    else
      raise ArgumentError, 'engine must be a string relating to an internal Aqua library store, or a hash of values indicating where to find the external library'
    end      
  end
  
  # Loads an internal engine from a string
  # @api private
  def self.load_internal_engine( str )
    underscored = str.underscore
    require "aqua/store/#{underscored}/#{underscored}"
    include_engine( "Aqua::Store::#{str}::StorageMethods" )
  end
  
  # Loads an external engine from a hash of options. 
  # @see Aqua#set_storage_engine for the public method that uses this internally
  # @api private
  def self.include_engine( str )
    Aqua::Storage.class_eval do
      include str.constantize
    end
  end       

end # Aqua  

# This is temporary until more engines are available!
Aqua.set_storage_engine('CouchDB') # to initialize CouchDB
