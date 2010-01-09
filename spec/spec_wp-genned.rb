# bacon spec/spec_wp-genned.rb
require 'hipe-socialsync'


# You may not want to edit this file.  It was generated from data in "wp.screenshots"
# by hipe-cli gentest on 2010-01-08 22:53.
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
    md = x.to_s.match  %r{^hello.*  my environment is "(.+)"\.$}i
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

  it "sosy users:add user2@user admin@admin  (wp-1)" do
    x = @app.run(["users:add", "user2@user", "admin@admin"])
    y = "Created user \"user2@user\". Now there are 2 users."
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add wordpress admin@admin wpuser1 (wp-2)" do
    x = @app.run(["accounts:add", "wordpress", "admin@admin", "wpuser1"])
    y = "Added wordpress account of \"wpuser1\"."
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add wordpress admin@admin wpuser2 (wp-3)" do
    x = @app.run(["accounts:add", "wordpress", "admin@admin", "wpuser2"])
    y = "Added wordpress account of \"wpuser2\"."
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add tumblr admin@admin tuser1 (wp-4)" do
    x = @app.run(["accounts:add", "tumblr", "admin@admin", "tuser1"])
    y = "Added tumblr account of \"tuser1\"."
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add wordpress user2@user wpuser3 (wp-5)" do
    x = @app.run(["accounts:add", "wordpress", "user2@user", "wpuser3"])
    y = "Added wordpress account of \"wpuser3\"."
    x.to_s.chomp.should.equal y
  end

  it "# add item wordpress wpuser1 101 cat (wp-6)" do
    x = @app.run(["items:add", "wordpress", "wpuser1", "101", "ignore author", "a cat content", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "admin@admin"])
    y = "Added blog entry (ours: #1, theirs: #101)."
    x.to_s.chomp.should.equal y
  end

  it "# add item wordpress wpuser1 102 dog (wp-7)" do
    x = @app.run(["items:add", "wordpress", "wpuser1", "102", "ignore author", "a dog content", "kw1,kw2,kw3", "2008-01-03", "published", "my dog", "admin@admin"])
    y = "Added blog entry (ours: #2, theirs: #102)."
    x.to_s.chomp.should.equal y
  end

  it "# add item wordpress wpuser2 103 giraffe (wp-8)" do
    x = @app.run(["items:add", "wordpress", "wpuser2", "103", "ignore author", "a giraffe content", "kw1,kw2,kw3", "2008-01-04", "published", "my giraffe", "admin@admin"])
    y = "Added blog entry (ours: #3, theirs: #103)."
    x.to_s.chomp.should.equal y
  end

  it "# add item wordpress wpuser3 (user2@user) 201 hippo (wp-9)" do
    x = @app.run(["items:add", "wordpress", "wpuser3", "201", "ignore author", "hippo content", "kw7,kw8,kw9", "2008-01-05", "published", "my hippo", "user2@user"])
    y = "Added blog entry (ours: #4, theirs: #201)."
    x.to_s.chomp.should.equal y
  end

  it "# add item tumblr tuser1 (admin@admin) 901 camel (wp-10)" do
    x = @app.run(["items:add", "--source", "4", "tumblr", "tuser1", "901", "ignore author", "a camel content", "kw1,kw2,kw3", "2008-01-06", "published", "my camel", "admin@admin"])
    y = "Added blog entry (ours: #5, theirs: #901)."
    x.to_s.chomp.should.equal y
  end

  it "sosy wp:pull file-not-there.xml imauzer admin@admin (wp-11)" do
    x = @app.run(["wp:pull", "file-not-there.xml", "imauzer", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    File not found: "file-not-there.xml"
    See "sosy wp:pull -h" for more info.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy wp:pull spec/xml-fixtures/wordpress.peterjennings.2009-11-11.xml imauzer admin@admin (wp-12)" do
    x = @app.run(["wp:pull", "spec/xml-fixtures/wordpress.peterjennings.2009-11-11.xml", "imauzer", "admin@admin"])
    y = "Can't find account with name credential \"imauzer\" and service \"wordpress\" and user \"admin@admin\"."
    x.to_s.chomp.should.equal y
  end

  it "sosy wp:pull --dry spec/xml-fixtures/wordpress.peterjennings.2009-11-11.xml wpuser1 admin@admin (wp-13)" do
    x = @app.run(["wp:pull", "--dry", "spec/xml-fixtures/wordpress.peterjennings.2009-11-11.xml", "wpuser1", "admin@admin"])
    x.valid?.should.equal true
  end
end
