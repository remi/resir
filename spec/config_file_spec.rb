require File.dirname(__FILE__) + '/spec_helper'

describe 'resirrc config files' do
  it 'should support the same new syntax changes and improvements that siterc files do'
end

describe 'siterc config files' do

  it 'should be able to load filters by passing the name of the filter(s)' do
    site = Resir::Site.new 'examples/siterc_testing/first'
    req  = Rack::MockRequest.new site
    
    req.get('/some_path').body.should == 'i am the sample filter!'
    req.get('/another_page').body.should == 'i am sample_two, required when you require sample!  NEATO!!!'
    req.get('/yet_another').body.should == "i'm from more filters ... filter!"
    req.get('/yet_another.more_filters_filter').body.should == "i'm from more filters ... filter!"
  end

  it "it can add filters into site.filters using a pretty load_filter { erb {} } style syntax" do
    Resir.filters.keys.should_not include('misc')

    site = Resir::Site.new 'examples/siterc_testing/first'
    req  = Rack::MockRequest.new site
    
    site.filters.keys.should include('misc')
    Resir.filters.keys.should_not include('misc')
    
    req.get('/blah').body.should == 'i am the misc filter'
    req.get('/blah.misc').body.should == 'i am the misc filter'
  end

  it "it can manually add filters into site.filters" do
    Resir.filters.keys.should_not include('manual')

    site = Resir::Site.new 'examples/siterc_testing/first'
    req  = Rack::MockRequest.new site
    
    site.filters.keys.should include('manual')
    Resir.filters.keys.should_not include('manual')
    
    req.get('/page').body.should == 'manually set this filter in .siterc'
  end

  it "should have access to site (as 'site' or 'self')" do
    site = Resir::Site.new 'examples/siterc_testing/first'

    site.hello.should == 'hello from a new variable added by siterc'
    site.new_site_method.should == 'hello from new site method!'
    site.added_to_site.should == 'added this to var of name site'
  end

  it "can add helper methods by class_eval'ing onto [self.]responder" do
    site = Resir::Site.new 'examples/siterc_testing/first'
    req  = Rack::MockRequest.new site
    req.get('/').body.should == 'calling blah: BLAH'
  end

end
