# bacon spec/spec_items-genned.rb
require 'hipe-socialsync'


# You may not want to edit this file.  It was generated from data in "items.screenshots"
# by hipe-cli gentest on 2010-01-08 23:11.
# If tests are failing here, it means that either 1) the gentest generated
# code that makes tests that fail (it's not supposed to do this), 2) That there is something incorrect in
# your "screenshot" data, or 3) that your app or hipe-cli has changed since the screenshots were taken
# and the tests generated from them.
# So, if the tests are failing here (and assuming gentest isn't broken), fix your app, get the output you want,
# make a screenshot (i.e. copy-paste it into the appropriate file), and re-run gentest, run the generated test,
# an achieve your success that way.  It's really that simple.


describe "Item tests (generated tests)" do

  it "# destroy and init the database (i-0) (i-0)" do
    env = $hipe_env || 'test'
    raise "no: #{env}" unless ['dev','test'].include?(env)
    @app = Hipe::SocialSync::App.new(['-e',env])
    x = @app.run(["db:auto-migrate", "-F", env])
    x.valid?.should.equal true
  end

  it "sosy items:add -h (i-1)" do
    x = @app.run(["items:add", "-h"])
    x.valid?.should.equal true
  end

  it "# add item wrong service name (i-2)" do
    x = @app.run(["items:add", "wordpresz", "doofis", "123", "me", "i am a blog entry", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "admin@admin"])
    y = "Can't find service with name \"wordpresz\"."
    x.to_s.chomp.should.equal y
  end

  it "# add item no such account (i-3)" do
    x = @app.run(["items:add", "wordpress", "doofis", "123", "me", "i am a blog entry", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "admin@admin"])
    y = "Can't find account with name credential \"doofis\" and service \"wordpress\" and user \"admin@admin\"."
    x.to_s.chomp.should.equal y
  end

  it "# add account with everything ok (i-4)" do
    x = @app.run(["accounts:add", "wordpress", "admin@admin", "imauser"])
    y = "Added wordpress account of \"imauser\"."
    x.to_s.chomp.should.equal y
  end

  it "# add item with everything ok (i-5)" do
    x = @app.run(["items:add", "wordpress", "imauser", "123", "some-other-author", "i am a blog entry", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "admin@admin"])
    y = "Added blog entry (ours: #1, theirs: #123)."
    x.to_s.chomp.should.equal y
  end

  it "# add same item again and FAIL (i-6)" do
    x = @app.run(["items:add", "wordpress", "imauser", "123", "some-other-author", "i am a blog entry", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "admin@admin"])
    y = "Md5 \"7d9ad782a0a270d410bea8b81569e6c5\" is already taken.  Another blog entry (#123) from 2008-01-02 already has that content.  You already have another wordpress blog entry in the \"imauser\" account with that foreign id (#123)."
    x.to_s.chomp.should.equal y
  end

  it "# add another (i-7) (i-7)" do
    x = @app.run(["items:add", "wordpress", "imauser", "124", "some-other-author", "i am a blog entry again", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "admin@admin"])
    y = "Added blog entry (ours: #2, theirs: #124)."
    x.to_s.chomp.should.equal y
  end

  it "# list should be two (i-8) (i-8)" do
    x = @app.run(["items:list"])
    x.data.tables[0].list.size.should.equal 2
  end

  it "# delete help should work (i-9) (i-9)" do
    x = @app.run(["items:delete", "-h"])
    x.valid?.should.equal true
  end

  it "sosy items:delete  blah adminz (i-10)" do
    x = @app.run(["items:delete", "blah", "adminz"])
    x.to_s.should.match %r{item ids "blah" does not match the correct pattern}
  end

  it "sosy items:delete  blah admin@admin (i-11)" do
    x = @app.run(["items:delete", "blah", "admin@admin"])
    x.to_s.should.match %r{item ids "blah" does not match the correct pattern}
  end

  it "sosy items:delete 1 admin@admin (i-12)" do
    x = @app.run(["items:delete", "1", "admin@admin"])
    y = "Removed the reflection of the item \"my cat\""
    x.to_s.chomp.should.equal y
  end

  it "sosy users:add temp@user admin@admin (i-13)" do
    x = @app.run(["users:add", "temp@user", "admin@admin"])
    y = "Created user \"temp@user\". Now there are 2 users."
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add wordpress temp@user meeee (i-14)" do
    x = @app.run(["accounts:add", "wordpress", "temp@user", "meeee"])
    y = "Added wordpress account of \"meeee\"."
    x.to_s.chomp.should.equal y
  end

  it "# other user adds item (i-15)" do
    x = @app.run(["items:add", "wordpress", "meeee", "789", "the-author", "i am a blog entry", "", "2008-01-03", "published", "my dog", "temp@user"])
    y = "Added blog entry (ours: #3, theirs: #789)."
    x.to_s.chomp.should.equal y
  end

  it "sosy items:delete 3 admin@admin (i-16)" do
    x = @app.run(["items:delete", "3", "admin@admin"])
    y = "That item doesn't belong to you."
    x.to_s.chomp.should.equal y
  end

  it "# temp@user adds blog item 501 (i-17)" do
    x = @app.run(["items:add", "wordpress", "meeee", "501", "auth501", "i am blog entry 501", "kw1,kw2,kw3", "2008-05-01", "published", "blog title 501", "temp@user"])
    y = "Added blog entry (ours: #4, theirs: #501)."
    x.to_s.chomp.should.equal y
  end

  it "# temp@user adds blog item 502 (i-18)" do
    x = @app.run(["items:add", "wordpress", "meeee", "502", "auth502", "i am blog entry 502", "kw1,kw2,kw3", "2008-05-02", "published", "blog title 502", "temp@user"])
    y = "Added blog entry (ours: #5, theirs: #502)."
    x.to_s.chomp.should.equal y
  end

  it "# when deleting multiple note the cool lingual junk (i-19)" do
    x = @app.run(["items:delete", "3,4,5", "temp@user"])
    y = "Removed the reflection of the item \"my dog\", \"blog title 501\" and \"blog title 502\""
    x.to_s.chomp.should.equal y
  end
end
