require File.dirname(__FILE__) + '/http_client/rest_api'
require File.dirname(__FILE__) + '/server'
require File.dirname(__FILE__) + '/database'
require File.dirname(__FILE__) + '/storage_methods'

module Aqua
  module Store
    module CouchDB  
      
      class ResourceNotFound      < IOError; end
      class RequestFailed         < IOError; end
      class RequestTimeout        < IOError; end
      class ServerBrokeConnection < IOError; end
      class Conflict              < ArgumentError; end  
      
      # Returns a string describing the http adapter in use, or loads the default and returns a similar string
      # @return [String] A string identifier for the HTTP adapter in use
      def self.http_adapter
        @adapter ||= set_http_adapter
      end  
  
      # Sets a class variable with the library name that will be loaded.
      # Then attempts to load said library from the adapter directory.
      # It is extended into the HttpAbstraction module. Then the RestAPI which 
      # references the HttpAbstraction module is loaded/extended into Aqua
      # this makes available Aqua.get 'http:://someaddress.com' and other requests 
      
      # Loads an http_adapter from the internal http_client libraries. Right now there is only the 
      # RestClient Adapter. Other adapters will be added when people get motivated to write and submit them.
      # By default the RestClientAdapter is used, and if the CouchDB module is used without prior configuration
      # it is automatically loaded.
      #
      # @param [optional, String] Maps to the HTTP Client Adapter module name, file name is inferred by removing the 'Adapter' suffix and underscoring the string 
      # @return [String] Name of HTTP Client Adapter module
      # @see Aqua::Store::CouchDB::RestAPI Has detail about the required interface
      # @api public
      def self.set_http_adapter( mod_string='RestClientAdapter' )
    
        # what is happening here:
        # strips the Adapter portion of the module name to get at the client name
        # convention over configurationing to get the file name as it relates to files in http_client/adapter
        # require the hopefully found file
        # modify the RestAPI class to extend the Rest methods from the adapter
        # add the RestAPI to Aqua for easy access throughout the library
        
        @adapter = mod_string
        mod = @adapter.gsub(/Adapter/, '')
        file = mod.underscore
        require File.dirname(__FILE__) + "/http_client/adapter/#{file}"
        RestAPI.adapter = "#{mod_string}".constantize
        extend(::RestAPI)
        @adapter  # return the adapter 
      end
      
      # Cache of CouchDB Servers used by Aqua. Each is identified by its namespace.
      #
      # @api private
      def self.servers
        @servers ||= {}
      end
      
      # Reader for getting or initializtion and getting a server by namespace. Used by various parts of store
      # to define storage strategies. Also conserves memory so that there is only one instance of a Server per
      # namespace. 
      #
      # @param [String] Server Namespace
      # @api private
      def self.server( namespace=nil )
        namespace ||= :aqua
        namespace = namespace.to_sym unless namespace.class == Symbol
        s = servers[ namespace ] 
        s = servers[namespace.to_sym] = Server.new( :namespace => namespace ) unless s 
        s  
      end
      
      # Clears the cached servers. So far this is most useful for testing. 
      # API will depend on usefulness outside this. 
      #
      # @api private
      def self.clear_servers
        @servers = {}
      end 
      
      
      # TEXT HELPERS ================================================
      
      # This comes from the CouchRest Library and its licence applies. 
      # It is included in this library as LICENCE_COUCHREST.
      # The method breaks the parameters into a url query string.
      # 
      # @param [String] The base url upon which to attach query params
      # @param [optional Hash] A series of key value pairs that define the url query params 
      # @api semi-public
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
      
      # A convenience method for escaping a string,
      # namespaced classes with :: notation will be converted to __ 
      # all other non-alpha numeric characters besides hyphens and underscores are removed 
      #
      # @param [String] to be converted
      # @return [String] converted
      #
      # @api private
      def self.escape( str )
        str.gsub!('::', '__')
        str.gsub!(/[^a-z0-9\-_]/, '')
        str
      end  
      
      # DATABASE STRATEGIES ----------------------------------
      # This library was built with to be flexible but have some sensible defaults. Database strategies is 
      # one of those areas. You can configure the CouchDB module to use one of three ways of managing data
      # into databases: 
      #   * :single - This is the default. It uses the CouchDB.server(:aqua) to build a single database where
      #         all the documents are stored. 
      #   * :per_class - This strategy is the opposite of the single strategy in that each class has it's own
      #         database. This will make complex cross class lookups more difficult.
      #   * :configured - Each class configures its own database and server namespace. Any server not 
      #         configured will default to the CouchDB.server. Any database not configured will default to the
      #         default database ... that set by the server namespace.
      # TODO: store these strategies; give feedback to documents about the appropriate database. 
      
      
      # AUTOLOADING ---------
      # auto loads the default http_adapter if Aqua gets used without configuring it first
        
      class << self     
        def method_missing( method, *args )
          if @adapter.nil?
            set_http_adapter # loads up the adapter related stuff
            send( method.to_sym, eval(args.map{|value| "'#{value}'"}.join(', ')) )
          else
            raise NoMethodError
          end    
        end
      end         
    
    end # CouchDB
  end # Store
end # Aqua     