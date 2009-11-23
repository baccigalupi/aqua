require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require_fixtures

require File.expand_path( File.dirname(__FILE__) + '/../../../lib/aqua/object/extensions/callbacks' )
 
describe 'Aqua::Callbacks' do 
  module Committer
    def self.included( klass )
      klass.class_eval do 
        extend Aqua::Callbacks
        attr_writer :message, :blocker
      end 
    end    
    
    def message
      @message ||= ""
    end
    
    def blocker
      @blocker ||= ""
    end    
  
    def commit
      self.message << 'I am commited! '
    end 
    
    def pre_commit
      self.message << "I happen before the commit. "
    end
  
    def post_commit
      self.message << "I happen after the commit. " 
    end
    
    def around_commit
      self.message << 'Wrap. '
      yield
      self.message << 'Wrap. '
    end  
  end 
  
  class Beforer 
    include Committer
    before :commit, :pre_commit 
    before :commit do
      blocker << "Beforing it. "
    end  
  end 
  
  class Afterer
    include Committer
    after :commit, :post_commit 
    after :commit do
      blocker << "Aftering it. "
    end
  end
  
  class Arounder
    include Committer
    around :commit, :around_commit 
    around :commit do
      blocker << "Arounding the before. "
      yield 
      blocker << "Arounding the after. "
    end
  end
  
  class Blank
    include Committer
  end      
  
  describe 'class' do
    it 'should respond to #define_callbacks' do
      Blank.should respond_to(:define_callbacks)
    end 
  end   
    
  describe '#before' do
    it 'should execute the callback before the originating method' do 
      committer = Beforer.new
      committer.commit
      committer.message.should == "I happen before the commit. I am commited! "
    end
    
    it 'should execute the passed block before the origintating method' do 
      committer = Beforer.new
      committer.commit
      committer.blocker.should == "Beforing it. "
    end     
  end   
  
  describe '#after' do
    it 'should execute the callback after the originating method' do 
      committer = Afterer.new
      committer.commit
      committer.message.should == "I am commited! I happen after the commit. "
    end
    
    it 'should execute the passed block after the origintating method' do 
      committer = Afterer.new
      committer.commit
      committer.blocker.should == "Aftering it. "
    end     
  end
  
  describe '#around' do
    it 'should execute the callback before and after the originating method' do 
      pending "how around works ???"
      committer = Arounder.new
      committer.commit
      committer.message.should == "Wrap. I am commited! Wrap. "
    end
    
    it 'should execute the passed block after the origintating method' do
      pending "how around should work ??" 
      committer = Arounder.new
      committer.commit
      committer.blocker.should == "Arounding it. Arounding it."
    end
  end      

end  