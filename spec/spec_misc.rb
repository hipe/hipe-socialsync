# bacon -n '.*' spec/spec_misc.rb
require 'hipe-socialsync'
require 'bacon'
require 'hipe-core/test/bacon-extensions'


describe "miscelaneous" do

  it "relpath (misc0)" do
    @app = Hipe::SocialSync::App.new(['-e','test'])
    @app.run(['-h'])
    @app.cli.plugins['db'].rel_path('/tmp').should.equal('/tmp')
  end
  
  it "construct app w/o environment params (misc1)" do
    app = Hipe::SocialSync::App.new()
    x = app.run(['-e','test','ping'])
    x.valid?.should.equal true
  end
  
  it "construct app w/o environment params (misc2)" do
    old = @app.cli.config.db.test    
    @app.cli.config.db.test = 'nql:///somefile.db'
    e = lambda do
      x = @app.run(['ping','--db'])
    end.should.raise(Hipe::SocialSync::Exception)
    e.message.should.match(%r{For now this only works for sqlite}i)
    @app.cli.config.db.test = old # unforgivable
  end

  it "app w/ bad environment (misc3)" do
    @app = Hipe::SocialSync::App.new(['-e','mu'])    
    e = lambda do
      x = @app.run(['ping','--db'])
    end.should.raise(Hipe::SocialSync::Exception)
    e.message.should.match(%r{For now this only works for sqlite}i)
  end
end
