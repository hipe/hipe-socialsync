# bacon -n '.*' spec/spec_misc.rb
require 'hipe-socialsync'
require 'bacon'
require 'hipe-core/test/bacon-extensions'


Hipe::SocialSync::App.new.run(['-e','test','ping','--db'])
require 'hipe-socialsync/model'
include Hipe::SocialSync::Model

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
  module SomeModule
    class Thing;
      include DataMapper::Resource
      include Hipe::SocialSync::Model::DataObjectCommon
      extend  Hipe::SocialSync::Model::DataObjectCommonClassMethods
      def id; 0 end
    end
  end

  it "DataObjectCommon should word (misc4)" do
    klass = SomeModule::Thing
    obj = SomeModule::Thing.new
    obj.one_word.should.equal '#0'
    klass.class_basename.should.equal 'Thing'
    x = catch(:invalid) do
      klass.kind_of_or_throw('something',nil,Fixnum)
    end
    x.should.be.kind_of Hipe::SocialSync::Model::ValidationErrors
    x.to_s.should.equal "Something not found."

    x = catch(:invalid) do
      klass.kind_of_or_throw('something','a',Fixnum)
    end
    x.should.be.kind_of Hipe::SocialSync::Model::ValidationErrors
    x.to_s.should.equal "Something should be fixnum but was string."

    x = catch(:invalid) do
      klass.to_time_or_throw('foo')
    end
    x.should.be.kind_of Hipe::SocialSync::Model::ValidationErrors
    x.to_s.should.equal %{Invalid date: "foo"}
  end


  it "Validation Errors (misc5)" do

    e = lambda do
      x = ValidationErrors[]
    end.should.raise(ArgumentError)
    e.message.should.match %r{bad signature}i

    e = ValidationError.new(nil,{:a=>['b','c']})
    e.message.should.equal '{:a=>["b", "c"]}'

  end

end
