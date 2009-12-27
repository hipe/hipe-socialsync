# bacon -n '.*' spec/spec_accounts-genned.rb
require 'hipe-socialsync'
require 'bacon'
require 'hipe-core/test/bacon-extensions'


# You may not want to edit this file.  It was generated from data in "accounts.screenshots"
# by hipe-cli gentest on 2009-12-27 05:31.
# If tests are failing here, it means that either 1) the gentest generated
# code that makes tests that fail (it's not supposed to do this), 2) That there is something incorrect in
# your "screenshot" data, or 3) that your app or hipe-cli has changed since the screenshots were taken
# and the tests generated from them.
# So, if the tests are failing here (and assuming gentest isn't broken), fix your app, get the output you want,
# make a screenshot (i.e. copy-paste it into the appropriate file), and re-run gentest, run the generated test,
# an achieve your success that way.  It's really that simple.


describe "Account tests (generated tests)" do

  it "sosy db:auto-migrate -F (a-0)" do
    @app = Hipe::SocialSync::App.new(['-e','test']) 
    x = @app.run(["db:auto-migrate", "-F"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    auto-migrated test db.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:list -h (a-1)" do
    x = @app.run(["accounts:list", "-h"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    accounts:list - show all accounts
    
    Usage: sosy accounts:list [-h] current_user_email
        -h
            current_user_email           the email of the current user
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:list  (a-2)" do
    x = @app.run(["accounts:list"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    There is one missing required argument: current_user_email
    See "sosy accounts:list -h" for more info.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:list  admin@admin (a-3)" do
    x = @app.run(["accounts:list", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    0 accounts
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add wordprez admin@admin imauser (a-4)" do
    x = @app.run(["accounts:add", "wordprez", "admin@admin", "imauser"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Can't find service with name "wordprez".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy services:add wordprez admin@admin (a-5)" do
    x = @app.run(["services:add", "wordprez", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Created service "wordprez".  Now there are three services.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add wordprez admin@admin imauser (a-6)" do
    x = @app.run(["accounts:add", "wordprez", "admin@admin", "imauser"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added wordprez account of "imauser".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add wordprez admin@admin imauser2 (a-7)" do
    x = @app.run(["accounts:add", "wordprez", "admin@admin", "imauser2"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Added wordprez account of "imauser2".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:list admin@admin (a-8)" do
    x = @app.run(["accounts:list", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    2                 wordprez             imauser2
    1                 wordprez              imauser
    2 accounts
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:delete wordprez imauser2 admin@admin (a-9)" do
    x = @app.run(["accounts:delete", "wordprez", "imauser2", "admin@admin"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Removed record of wordprez account for "imauser2".
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy accounts:add wordprez admin@admin imauser (a-10)" do
    x = @app.run(["accounts:add", "wordprez", "admin@admin", "imauser"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    account already exists for wordprez with username "imauser"
    __HERE__
    x.to_s.chomp.should.equal y
  end
end
