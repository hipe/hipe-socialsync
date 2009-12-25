# bacon -n '.*' spec/spec_users-genned.rb
require 'hipe-socialsync'


# You may not want to edit this file.  It was generated from data in "users.screenshots"
# by hipe-cli gentest on 2009-12-25 04:15.
# If tests are failing here, it means that either 1) the gentest generated
# code that makes tests that fail (it's not supposed to do this), 2) That there is something incorrect in
# your "screenshot" data, or 3) that your app or hipe-cli has changed since the screenshots were taken
# and the tests generated from them.
# So, if the tests are failing here (and assuming gentest isn't broken), fix your app, get the output you want,
# make a screenshot (i.e. copy-paste it into the appropriate file), and re-run gentest, run the generated test,
# an achieve your success that way.  It's really that simple.


describe "Generated test (generated tests)" do

  it "# bad plugin name (gt-0)" do
    @app = Hipe::SocialSync::App.new 
    x = @app.run(["db:rotate"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Unrecognized plugin "db". Known plugins are "accounts", "item", "services", "users" and "wp"
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# move database. (gt-1)" do
    x = @app.run(["db-rotate", "-c"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    moved dev.db to backup file.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# list from beginning (gt-2)" do
    x = @app.run(["users:list"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    1               admin@admin
    (1 users)
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add with missing parameters (gt-3)" do
    x = @app.run(["users:add"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    There are two missing required arguments: email and admin_email
    See "sosy users:add -h" for more info.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "should work (gt-4)" do
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

  it "# extra argument (gt-5)" do
    x = @app.run(["users:add", "blah", "blah", "blah"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    there is one unexpected argument: "blah": 
    See "sosy users:add -h" for more info.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# bad admin email (gt-6)" do
    x = @app.run(["users:add", "blah", "blah"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Can't find user with email "blah".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# bad email format (gt-7)" do
    x = @app.run(["users:add", "blah", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    "blah" is not a valid email address.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add user (gt-8)" do
    x = @app.run(["users:add", "mark@mark", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Created user "mark@mark". Now there are 2 users.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# list users (gt-9)" do
    x = @app.run(["users:list"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    1               admin@admin
    2                 mark@mark
    (2 users)
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add again (gt-10)" do
    x = @app.run(["users:add", "mark2@mark", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Created user "mark2@mark". Now there are 3 users.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# add with already used name (gt-11)" do
    x = @app.run(["users:add", "mark@mark", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    There is already a user "mark@mark".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# delete with missing args (gt-12)" do
    x = @app.run(["users:delete"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    There are two missing required arguments: email and admin
    See "sosy users:delete -h" for more info.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# delete -h (gt-13)" do
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

  it "# delete with too many arguments (gt-14)" do
    x = @app.run(["users:delete", "blah", "blah", "blah"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    there is one unexpected argument: "blah": 
    See "sosy users:delete -h" for more info.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "# delete user (gt-15)" do
    x = @app.run(["users:delete", "mark2@mark", "admin@admin"])
    y = "Deleted user \"mark2@mark\" (#3)."
    x.to_s.chomp.should.equal y
  end
end
