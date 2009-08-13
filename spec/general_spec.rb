require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Persist" do
  describe 'http_client setup' do
    it 'should not raise an error loading the default adapter' do 
      lambda{ Persist.set_http_adapter }.should_not raise_error
    end
    
    it 'should add rest methods to the Persist module' do
      Persist.set_http_adapter
      Persist.should respond_to(:get)
    end      
  end  
  
  it 'gem should allow persistance on all objects'
  it 'gem should allow persistance with a class declaration'
  it 'gem should allow persistance via module inclusion'
  it 'gem should allow persistance via Persisted inheritance'
  
  it 'class declaration "persist" should take options for namespacing ... and other configuration options'
  
  describe 'application data separation' do # for ease of replication etc
    it 'applications data can be separated with the namespacing option'
    it 'the namespacing option will prefix the escaped class name as the db name'
  end  
  
  describe 'databases' do 
    it 'each class should have its own database'
    it 'database name should be after the escaped class name'
    it 'namespaced classes should be escaped for CouchDB naming'
  end
  
  describe 'classes' do
    'should be saved into the design document'
  end  
  
  describe 'instances' do
    it 'simple attributes should be saved in record by default'
    it 'more complex attributes should be saved to their own database by default'
    it 'non-collection attributes should have options for saving internally, externally or stubbed'
    it 'should save singleton methods'
  end
  
  describe 'collections' do
    it 'collection attributes should have options for saving internally, externally or stubbed'
  end 
  
  it 'should recursively save complex objects'

end  
