# bacon -n '.*' spec/spec_aaa-db-genned.rb
require 'hipe-socialsync'
require 'bacon'
require 'hipe-core/test/bacon-extensions'


# You may not want to edit this file.  It was generated from data in "aaa-db.screenshots"
# by hipe-cli gentest on 2009-12-27 05:31.
# If tests are failing here, it means that either 1) the gentest generated
# code that makes tests that fail (it's not supposed to do this), 2) That there is something incorrect in
# your "screenshot" data, or 3) that your app or hipe-cli has changed since the screenshots were taken
# and the tests generated from them.
# So, if the tests are failing here (and assuming gentest isn't broken), fix your app, get the output you want,
# make a screenshot (i.e. copy-paste it into the appropriate file), and re-run gentest, run the generated test,
# an achieve your success that way.  It's really that simple.


describe "Db tests (generated tests)" do

  it "sosy db:archive (db-0)" do
    @app = Hipe::SocialSync::App.new(['-e','test'])
    x = @app.run(["db:archive"])
    x.to_s.should.match %r{^moved [^ ]+ to|database file doesn't exist}i
  end

  it "sosy db:archive (db-1)" do
    x = @app.run(["db:archive"])
    x.to_s.should.match %r{^database file doesn't exist}i
  end

  it "sosy db:init (db-2)" do
    x = @app.run(["db:init"])
    x.to_s.should.match %r{now it exists}i
  end

  it "sosy db:init (db-3)" do
    x = @app.run(["db:init"])
    x.to_s.should.match %r{file already exists}i
  end

  it "sosy db:archive -o 'data/test.db' (db-4)" do
    x = @app.run(["db:archive", "-o", "data/test.db"])
    x.to_s.should.match %r{File must not exist}i
  end

  it "sosy db:list (db-5)" do
    x = @app.run(["db:list"])
    x.to_s.should.match %r{path.+size.+atime.+ctime}i
  end

  it "sosy db:auto-migrate (db-6)" do
    x = @app.run(["db:auto-migrate"])
    x.to_s.should.match %r{The -F option is required to carry out this request}i
  end
end
