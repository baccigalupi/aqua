require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

Aqua.set_storage_engine('CouchDB') # to initialize the Aqua::Store namespace

describe 'Aqua::Store::CouchDB' do
     
  describe 'http_client setup' do
    describe 'autoloading' do
      it 'should not raise an error loading the default adapter' do 
        lambda{ Aqua::Store::CouchDB.set_http_adapter }.should_not raise_error
      end
    
      it 'should add rest methods to the Aqua module' do
        Aqua::Store::CouchDB.set_http_adapter
        Aqua::Store::CouchDB.should respond_to(:get)
      end 
    end
    
    describe 'manual loading of an alternate library' do
      # TODO: when there is an alternate library
    end         
  end
  
  describe 'servers' do 
    it 'server(:symbol) should return an existing server if the "symbol" namespace exists'
    it 'server(:symbol) should return a new server if the "symbol" namespace doesn\'t exist'
  end  
end    
  