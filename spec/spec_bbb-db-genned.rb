# bacon -n '.*' spec/spec_bbb-db-genned.rb
require 'hipe-socialsync'
require 'bacon'
require 'hipe-core/test/bacon-extensions'


# You may not want to edit this file.  It was generated from data in "bbb-db.screenshots"
# by hipe-cli gentest on 2009-12-29 06:16.
# If tests are failing here, it means that either 1) the gentest generated
# code that makes tests that fail (it's not supposed to do this), 2) That there is something incorrect in
# your "screenshot" data, or 3) that your app or hipe-cli has changed since the screenshots were taken
# and the tests generated from them.
# So, if the tests are failing here (and assuming gentest isn't broken), fix your app, get the output you want,
# make a screenshot (i.e. copy-paste it into the appropriate file), and re-run gentest, run the generated test,
# an achieve your success that way.  It's really that simple.


describe "Bbb db tests (generated tests)" do

  it "sosy db:archive (bbb-db-0)" do
    @app = Hipe::SocialSync::App.new(['-e','test']) 
    x = @app.run(["db:archive"])
    x.to_s.should.match %r{^moved [^ ]+ to|database file doesn't exist}i
  end

  it "sosy db:archive (bbb-db-1)" do
    x = @app.run(["db:archive"])
    x.to_s.should.match %r{^database file doesn't exist}i
  end

  it "sosy db:init (bbb-db-2)" do
    x = @app.run(["db:init"])
    x.to_s.should.match %r{still doesn't exist}i
  end

  it "sosy db:init (bbb-db-3)" do
    x = @app.run(["db:init"])
    x.to_s.should.match %r{still doesn't exist}i
  end

  it "sosy db:list (bbb-db-4)" do
    x = @app.run(["db:list"])
    x.to_s.should.match %r{path.+size.+atime.+ctime}i
  end
end
