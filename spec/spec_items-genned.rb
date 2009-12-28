# bacon -n '.*' spec/spec_items-genned.rb
require 'hipe-socialsync'


# You may not want to edit this file.  It was generated from data in "items.screenshots"
# by hipe-cli gentest on 2009-12-28 18:35.
# If tests are failing here, it means that either 1) the gentest generated
# code that makes tests that fail (it's not supposed to do this), 2) That there is something incorrect in
# your "screenshot" data, or 3) that your app or hipe-cli has changed since the screenshots were taken
# and the tests generated from them.
# So, if the tests are failing here (and assuming gentest isn't broken), fix your app, get the output you want,
# make a screenshot (i.e. copy-paste it into the appropriate file), and re-run gentest, run the generated test,
# an achieve your success that way.  It's really that simple.


describe "Item tests (generated tests)" do

  it "sosy db:auto-migrate -F test (i-0)" do
    @app = Hipe::SocialSync::App.new(['-e','test'])
    x = @app.run(["db:auto-migrate", "-F", "test"])
    x.valid?.should.equal true
  end

  it "sosy items:add -h (i-1)" do
    x = @app.run(["items:add", "-h"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    items:add - add an entry and asociate it w/ an account

    Usage: sosy items:add [-h|--help] service_name name_credential foreign_id author content_str keywords_str published_at status title current_user_email
        -h, --help
            service-name
            name-credential
            foreign-id
            author
            content-str
            keywords-str
            published_at
            status
            title
            current_user_email
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add item wrong service name  (i-2)" do
    x = @app.run(["items:add", "wordpresz", "doofis", "123", "me", "i am a blog entry", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Can't find service with name "wordpresz".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add item no such account (i-3)" do
    x = @app.run(["items:add", "wordpress", "doofis", "123", "me", "i am a blog entry", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Can't find account with name credential "doofis" and service "wordpress" and user "admin@admin".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add account with everything ok (i-4)" do
    x = @app.run(["accounts:add", "wordpress", "admin@admin", "imauser"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added wordpress account of "imauser".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add item with everything ok (i-5)" do
    x = @app.run(["items:add", "wordpress", "imauser", "123", "some-other-author", "i am a blog entry", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added blog entry (ours: #1, theirs: #123).
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add same item again and FAIL (i-6)" do
    x = @app.run(["items:add", "wordpress", "imauser", "123", "some-other-author", "i am a blog entry", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Md5 "7d9ad782a0a270d410bea8b81569e6c5" is already taken.  Another blog entry (#123) from 2008-01-02 already has that content.  You already have another wordpress blog entry in the "imauser" account with that foreign id (#123).
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add another (i-7) (i-7)" do
    x = @app.run(["items:add", "wordpress", "imauser", "124", "some-other-author", "i am a blog entry again", "kw1,kw2,kw3", "2008-01-02", "published", "my cat", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added blog entry (ours: #2, theirs: #124).
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# list should be two (i-8) (i-8)" do
    x = @app.run(["items:list"])
    x.data.table.list.size.should.equal 2
  end

  it "# delete help should work (i-9) (i-9)" do
    x = @app.run(["items:delete", "-h"])
    x.valid?.should.equal true
  end

  it "sosy items:delete  blah adminz (i-10)" do
    x = @app.run(["items:delete", "blah", "adminz"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Can't find user with email "adminz".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy items:delete  blah admin@admin (i-11)" do
    x = @app.run(["items:delete", "blah", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Can't find item with id "blah".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy items:delete 1 admin@admin (i-12)" do
    x = @app.run(["items:delete", "1", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Removed the reflection of the item "my cat".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy users:add temp@user admin@admin (i-13)" do
    x = @app.run(["users:add", "temp@user", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Created user "temp@user". Now there are 2 users.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add wordpress temp@user meeee (i-14)" do
    x = @app.run(["accounts:add", "wordpress", "temp@user", "meeee"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added wordpress account of "meeee".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# other user adds item (i-15)" do
    x = @app.run(["items:add", "wordpress", "meeee", "789", "the-author", "i am a blog entry", "", "2008-01-03", "published", "my dog", "temp@user"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added blog entry (ours: #3, theirs: #789).
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy items:delete 3 admin@admin (i-16)" do
    x = @app.run(["items:delete", "3", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    That item doesn't belong to you.
    __HERE__
    x.to_s.chomp.should.equal y
  end
end
