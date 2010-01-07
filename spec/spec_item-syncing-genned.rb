# bacon -n '.*' spec/spec_item-syncing-genned.rb
require 'hipe-socialsync'


# You may not want to edit this file.  It was generated from data in "item-syncing.screenshots"
# by hipe-cli gentest on 2010-01-06 19:27.
# If tests are failing here, it means that either 1) the gentest generated
# code that makes tests that fail (it's not supposed to do this), 2) That there is something incorrect in
# your "screenshot" data, or 3) that your app or hipe-cli has changed since the screenshots were taken
# and the tests generated from them.
# So, if the tests are failing here (and assuming gentest isn't broken), fix your app, get the output you want,
# make a screenshot (i.e. copy-paste it into the appropriate file), and re-run gentest, run the generated test,
# an achieve your success that way.  It's really that simple.


describe "Item syncing tests (generated tests)" do

  it "# destroy and setup database (item-sync-0)" do
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

  it "sosy users:add hipe@sosy admin@admin (item-sync-1)" do
    x = @app.run(["users:add", "hipe@sosy", "admin@admin"])
    y = "Created user \"hipe@sosy\". Now there are 2 users."
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add wordpress hipe@sosy wpuser1 (item-sync-2)" do
    x = @app.run(["accounts:add", "wordpress", "hipe@sosy", "wpuser1"])
    y = "Added wordpress account of \"wpuser1\"."
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add wordpress hipe@sosy wpuser2 (item-sync-3)" do
    x = @app.run(["accounts:add", "wordpress", "hipe@sosy", "wpuser2"])
    y = "Added wordpress account of \"wpuser2\"."
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add tumblr hipe@sosy chip.malice@gmail.com (item-sync-4)" do
    x = @app.run(["accounts:add", "tumblr", "hipe@sosy", "chip.malice@gmail.com"])
    y = "Added tumblr account of \"chip.malice@gmail.com\"."
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add wordpress hipe@sosy wpuser3 (item-sync-5)" do
    x = @app.run(["accounts:add", "wordpress", "hipe@sosy", "wpuser3"])
    y = "Added wordpress account of \"wpuser3\"."
    x.to_s.chomp.should.equal y
  end

  it "# add item wordpress wpuser1 101 cat (item-sync-6)" do
    x = @app.run(["items:add", "wordpress", "wpuser1", "101", "ignore author", "a cat content", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "hipe@sosy"])
    y = "Added blog entry (ours: #1, theirs: #101)."
    x.to_s.chomp.should.equal y
  end

  it "# add item wordpress wpuser1 102 dog (item-sync-7)" do
    x = @app.run(["items:add", "wordpress", "wpuser1", "102", "ignore author", "a dog content", "kw1,kw2,kw3", "2008-01-03", "published", "my dog", "hipe@sosy"])
    y = "Added blog entry (ours: #2, theirs: #102)."
    x.to_s.chomp.should.equal y
  end

  it "# add item wordpress wpuser2 103 giraffe (item-sync-8)" do
    x = @app.run(["items:add", "wordpress", "wpuser2", "103", "ignore author", "a giraffe content", "kw1,kw2,kw3", "2008-01-04", "published", "my giraffe", "hipe@sosy"])
    y = "Added blog entry (ours: #3, theirs: #103)."
    x.to_s.chomp.should.equal y
  end

  it "# add item wordpress wpuser3 (hipe@sosy) 201 hippo (item-sync-9)" do
    x = @app.run(["items:add", "wordpress", "wpuser3", "201", "ignore author", "hippo content", "kw7,kw8,kw9", "2008-01-05", "published", "my hippo", "hipe@sosy"])
    y = "Added blog entry (ours: #4, theirs: #201)."
    x.to_s.chomp.should.equal y
  end

  it "# add item tumblr chip (hipe@sosy) 901 camel (item-sync-10)" do
    x = @app.run(["items:add", "--source", "4", "tumblr", "chip.malice@gmail.com", "901", "ignore author", "a camel content", "kw1,kw2,kw3", "2008-01-06", "published", "my camel", "hipe@sosy"])
    y = "Added blog entry (ours: #5, theirs: #901)."
    x.to_s.chomp.should.equal y
  end

  it "# target account (item-sync-11)" do
    x = @app.run(["item:add_target_account", "1", "tumblr", "chip.malice@gmail.com", "hipe@sosy"])
    y = "Added target tumblr/chip.malice@gmail.com to item \"my cat\"."
    x.to_s.chomp.should.equal y
  end

  it "# target same account again (item-sync-12)" do
    x = @app.run(["item:add_target_account", "1", "tumblr", "chip.malice@gmail.com", "hipe@sosy"])
    y = "Account tumblr/chip.malice@gmail.com has already been targeted by item \"my cat\"."
    x.to_s.chomp.should.equal y
  end

  it "# remove all targets (item-sync-13)" do
    x = @app.run(["item:remove_target_accounts", "1", "hipe@sosy"])
    y = "Removed one target from item \"my cat\"."
    x.to_s.chomp.should.equal y
  end

  it "# remove all targets again (item-sync-14)" do
    x = @app.run(["item:remove_target_accounts", "1", "hipe@sosy"])
    y = "Item \"my cat\" is already cleared of targets."
    x.to_s.chomp.should.equal y
  end

  it "# add target again (item-sync-15)" do
    x = @app.run(["item:add_target_account", "1,2", "tumblr", "chip.malice@gmail.com", "hipe@sosy"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added target tumblr/chip.malice@gmail.com to item "my cat".
    Added target tumblr/chip.malice@gmail.com to item "my dog".
    __HERE__
    x.to_s.chomp.should.equal y
  end
end
