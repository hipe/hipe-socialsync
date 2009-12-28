# bacon spec/fixtures/experiment.rb
require 'hipe-socialsync'

describe "Item tests (generated tests)" do

  it "sosy db:auto-migrate -F (i-0)" do
    @app = Hipe::SocialSync::App.new(['-e','dev'])
    x = @app.run(["db:auto-migrate", "-F" "dev"])
    if (x.valid?)
      puts %{ #{x}}
      true.should.equal true
    else
      puts x.to_s
    end
  end

  # add users

  it "sosy users:add user2@user admin@admin (i-13)" do
    x = @app.run(["users:add", "user2@user", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Created user "user2@user". Now there are 2 users.
    __HERE__
    x.to_s.chomp.should.equal y
  end



  # add accounts

  it "# add wordpress account (wpuser1) for admin@admin" do
    @app = Hipe::SocialSync::App.new(['-e','dev'])
    x = @app.run(["accounts:add", "wordpress", "admin@admin", "wpuser1"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added wordpress account of "wpuser1".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it '# add wordpress account (wpuser2) for admin@admin' do
    @app = Hipe::SocialSync::App.new(['-e','dev'])
    x = @app.run(["accounts:add", "wordpress", "admin@admin", "wpuser2"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added wordpress account of "wpuser2".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it '# add tumblr account (tuser1) for admin@admin' do
    @app = Hipe::SocialSync::App.new(['-e','dev'])
    x = @app.run(["accounts:add", "tumblr", "admin@admin", "tuser1"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added tumblr account of "tuser1".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it '# add wordpress account (wpuser3) for user2@user' do
    x = @app.run(["accounts:add", "wordpress", "user2@user", "wpuser3"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added wordpress account of "wpuser3".
    __HERE__
    x.to_s.chomp.should.equal y
  end


  # add items

  it "# add wordpress item (i-5)" do
    x = @app.run(["items:add", "wordpress", "wpuser1", "101", "ignore author", "a cat content", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added blog entry (ours: #1, theirs: #101).
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add another item (i-7)" do
    x = @app.run(["items:add", "wordpress", "wpuser1", "102", "ignore author", "a dog content", "kw1,kw2,kw3", "2008-01-03", "published", "my dog", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added blog entry (ours: #2, theirs: #102).
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add wordpress item from other wordpress user as admin@admin" do
    x = @app.run(["items:add", "wordpress", "wpuser2", "103", "ignore author", "a giraffe content", "kw1,kw2,kw3", "2008-01-04", "published", "my giraffe", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added blog entry (ours: #3, theirs: #103).
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# other sosy user adds wp item (i-15)" do
    x = @app.run(["items:add",
      "wordpress", "wpuser3", "201",
      "ignore author", "hippo content", "kw7,kw8,kw9",
      "2008-01-05", "published", "my hippo", "user2@user"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added blog entry (ours: #4, theirs: #201).
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add tumblr item" do
    x = @app.run(["items:add",
      "tumblr", "tuser1", "901",
      "ignore author", "a camel content", "kw1,kw2,kw3",
      "2008-01-06", "published", "my camel", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added blog entry (ours: #5, theirs: #901).
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy items:list admin@admin (i-8)" do
    x = @app.run(["items:list"])
    1.should.equal 1
    puts %{\n#{x}}
  end

end
