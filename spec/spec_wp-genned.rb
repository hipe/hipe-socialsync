# bacon -n '.*' spec/spec_wp-genned.rb
require 'hipe-socialsync'


# You may not want to edit this file.  It was generated from data in "wp.screenshots"
# by hipe-cli gentest on 2009-12-29 06:16.
# If tests are failing here, it means that either 1) the gentest generated
# code that makes tests that fail (it's not supposed to do this), 2) That there is something incorrect in
# your "screenshot" data, or 3) that your app or hipe-cli has changed since the screenshots were taken
# and the tests generated from them.
# So, if the tests are failing here (and assuming gentest isn't broken), fix your app, get the output you want,
# make a screenshot (i.e. copy-paste it into the appropriate file), and re-run gentest, run the generated test,
# an achieve your success that way.  It's really that simple.


describe "Wp tests (generated tests)" do

  it "sosy ping (wp-0)" do
    @app = Hipe::SocialSync::App.new(['-e', $hipe_env || 'test']) 
    x = @app.run(["ping"])
    env = $hipe_env || 'test'
    md = x.to_s.match  %r{^hello\.  my environment is "(.+)"\.$}i
    md.should.be.kind_of MatchData
    md[1].should.equal env
    x = @app.run(["db:auto-migrate", "-F", env])
    md = x.to_s.match  %r{auto-migrated ([^ ]+) db}
    md.should.be.kind_of MatchData
    md[1].should.equal env
    
    x = @app.run(["db:auto-migrate", "-F", env])
    md = x.to_s.match %r{auto-migrated ([^ ]+) db}i
    md.should.be.kind_of MatchData
    md[1].should.equal env
  end

  it "sosy accounts:add wordpress admin@admin imauser (wp-1)" do
    x = @app.run(["accounts:add", "wordpress", "admin@admin", "imauser"])
    y = "Added wordpress account of \"imauser\"."
    x.to_s.chomp.should.equal y
  end

  it "sosy wp:pull file-not-there.xml imauzer admin@admin (wp-2)" do
    x = @app.run(["wp:pull", "file-not-there.xml", "imauzer", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    File not found: "file-not-there.xml"
    See "sosy wp:pull -h" for more info.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy wp:pull spec/xml-fixtures/wordpress.peterjennings.2009-11-11.xml imauzer admin@admin (wp-3)" do
    x = @app.run(["wp:pull", "spec/xml-fixtures/wordpress.peterjennings.2009-11-11.xml", "imauzer", "admin@admin"])
    y = "Can't find account with name credential \"imauzer\" and service \"wordpress\" and user \"admin@admin\"."
    x.to_s.chomp.should.equal y
  end
end
