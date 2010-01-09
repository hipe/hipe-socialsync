# bacon spec/spec_aaa-db-genned.rb
require 'hipe-socialsync'
require 'bacon'
require 'hipe-core/test/bacon-extensions'


# You may not want to edit this file.  It was generated from data in "aaa-db.screenshots"
# by hipe-cli gentest on 2010-01-08 22:53.
# If tests are failing here, it means that either 1) the gentest generated
# code that makes tests that fail (it's not supposed to do this), 2) That there is something incorrect in
# your "screenshot" data, or 3) that your app or hipe-cli has changed since the screenshots were taken
# and the tests generated from them.
# So, if the tests are failing here (and assuming gentest isn't broken), fix your app, get the output you want,
# make a screenshot (i.e. copy-paste it into the appropriate file), and re-run gentest, run the generated test,
# an achieve your success that way.  It's really that simple.


describe "Db tests (generated tests)" do

  it "sosy ping (db-0)" do
    @app = Hipe::SocialSync::App.new(['-e','test'])
    x = @app.run(["ping"])
    puts "SKIPPING aaa file"
    1.should.equal 1
  end
end
