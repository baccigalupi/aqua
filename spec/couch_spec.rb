require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Persist::CouchServer" do
  describe 'domain_url' do
    it 'should default to "http://localhost"' 
    it 'should be settable'
  end
  
  describe 'port' do 
    it 'should default to "5984"' 
    it 'should be settable'
  end
end
