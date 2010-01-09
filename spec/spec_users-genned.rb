# bacon spec/spec_users-genned.rb
require 'hipe-socialsync'


# You may not want to edit this file.  It was generated from data in "users.screenshots"
# by hipe-cli gentest on 2010-01-08 22:53.
# If tests are failing here, it means that either 1) the gentest generated
# code that makes tests that fail (it's not supposed to do this), 2) That there is something incorrect in
# your "screenshot" data, or 3) that your app or hipe-cli has changed since the screenshots were taken
# and the tests generated from them.
# So, if the tests are failing here (and assuming gentest isn't broken), fix your app, get the output you want,
# make a screenshot (i.e. copy-paste it into the appropriate file), and re-run gentest, run the generated test,
# an achieve your success that way.  It's really that simple.


describe "User tests (generated tests)" do

  it "# sosy auto-migrate -F (u-0) (u-0)" do
    @app = Hipe::SocialSync::App.new(['-e','test'])
    x = @app.run(["db:auto-migrate", "-F", "test"])
    y = "auto-migrated test db."
    x.to_s.chomp.should.equal y
  end

  it "# list from beginning (u-1)" do
    x = @app.run(["users:list"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    1               admin@admin
    (1 users)
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add with missing parameters (u-2)" do
    x = @app.run(["users:add"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    There are two missing required arguments: email and admin_email
    See "sosy users:add -h" for more info.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy users:add -h (u-3)" do
    x = @app.run(["users:add", "-h"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    users:add - add a user to the list

    Usage: sosy users:add [-h] email admin_email
        -h
            email                        any ol' name you want, not an existing name
            admin_email                  the person acting as the admin
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# extra argument (u-4)" do
    x = @app.run(["users:add", "blah", "blah", "blah"])
    x.to_s.should.match Regexp.new('there is one unexpected argument: "blah": {1}'<<"\n"<<
    'See "sosy users:add -h" for more info\.$')
  end

  it "# bad admin email (u-5)" do
    x = @app.run(["users:add", "blah", "blah"])
    y = "Can't find user with email \"blah\"."
    x.to_s.chomp.should.equal y
  end

  it "# bad email format (u-6)" do
    x = @app.run(["users:add", "blah", "admin@admin"])
    y = "\"blah\" is not a valid email address."
    x.to_s.chomp.should.equal y
  end

  it "# add user (u-7)" do
    x = @app.run(["users:add", "mark@mark", "admin@admin"])
    y = "Created user \"mark@mark\". Now there are 2 users."
    x.to_s.chomp.should.equal y
  end

  it "# list users (u-8)" do
    x = @app.run(["users:list"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    1               admin@admin
    2                 mark@mark
    (2 users)
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add again (u-9)" do
    x = @app.run(["users:add", "mark2@mark", "admin@admin"])
    y = "Created user \"mark2@mark\". Now there are 3 users."
    x.to_s.chomp.should.equal y
  end

  it "# add with already used name (u-10)" do
    x = @app.run(["users:add", "mark@mark", "admin@admin"])
    y = "There is already a user \"mark@mark\"."
    x.to_s.chomp.should.equal y
  end

  it "# delete with missing args (u-11)" do
    x = @app.run(["users:delete"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    There are two missing required arguments: email and admin
    See "sosy users:delete -h" for more info.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# delete -h (u-12)" do
    x = @app.run(["users:delete", "-h"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    users:delete - delete user accounts

    Usage: sosy users:delete [-h] email admin
        -h
            email
            admin
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# delete with too many arguments (u-13)" do
    x = @app.run(["users:delete", "blah", "blah", "blah"])
    x.to_s.should.match Regexp.new( '^there is one unexpected argument: "blah": {1}'<<"\n"<<
     'See "sosy users:delete -h" for more info\.$')
  end

  it "# delete user (u-14)" do
    x = @app.run(["users:delete", "mark2@mark", "admin@admin"])
    y = "Deleted user \"mark2@mark\" (#3)."
    x.to_s.chomp.should.equal y
  end
end
