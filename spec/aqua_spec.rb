require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Aqua" do
  describe 'loading internal storage libraries' do
    it 'loading without an argument should not raise an error' do 
      lambda{ Aqua.set_storage_engine }.should_not raise_error
    end  
  end
  
  describe 'loading external storage libraries' do
  end
  
  describe 'configuration generalities' do
    it 'gem should allow persistance on all objects'
    it 'gem should allow persistance with a class declaration'
    it 'gem should allow persistance via module inclusion'
    it 'gem should allow persistance via Aquaed inheritance'
  end    
end