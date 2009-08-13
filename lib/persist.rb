# require gems
# This was grabbed from CouchRest, wholecloth. See LICENSE_COUCHREST for licensing.
require 'rubygems'
begin
  require 'json'
rescue LoadError
  raise "You need install and require your own json compatible library since couchrest rest couldn't load the json/json_pure gem" unless Kernel.const_defined?("JSON")
end
require 'rest_client'   

# require local libs
$:.unshift File.join(File.dirname(__FILE__))
require 'persist/support/mash'
require 'persist/store/store'


module Persist
 # errors here!
end  