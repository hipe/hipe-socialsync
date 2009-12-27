# bacon -n '.*' spec/spec_services-genned.rb
require 'hipe-socialsync'


# You may not want to edit this file.  It was generated from data in "services.screenshots"
# by hipe-cli gentest on 2009-12-27 05:31.
# If tests are failing here, it means that either 1) the gentest generated
# code that makes tests that fail (it's not supposed to do this), 2) That there is something incorrect in
# your "screenshot" data, or 3) that your app or hipe-cli has changed since the screenshots were taken
# and the tests generated from them.
# So, if the tests are failing here (and assuming gentest isn't broken), fix your app, get the output you want,
# make a screenshot (i.e. copy-paste it into the appropriate file), and re-run gentest, run the generated test,
# an achieve your success that way.  It's really that simple.


describe "Service tests (generated tests)" do

  it "sosy db:auto-migrate -F (s-0)" do
    @app = Hipe::SocialSync::App.new(['-e','test'])
    x = @app.run(["db:auto-migrate", "-F"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    auto-migrated test db.
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy services:add -h (s-1)" do
    x = @app.run(["services:add", "-h"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    services:add - add a service to the list

    Usage: sosy services:add [-h] name current_user_email
        -h
            name                         any ol' name you want, not an existing name
            current_user_email           the email of the person adding this service
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy services:add eraseme admin@admin (s-2)" do
    x = @app.run(["services:add", "eraseme", "admin@admin"])
    y = "Created service \"eraseme\".  Now there are three services."
    x.to_s.chomp.should.equal y
  end

  it "sosy -e test services:list (s-3)" do
    x = @app.run(["-e", "test", "services:list"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    3                  eraseme
    2                   tumblr
    1                wordpress
    3 services
    __HERE__
    x.to_s.chomp.should.equal y
  end

  it "sosy services:delete notthere admin@admin (s-4)" do
    x = @app.run(["services:delete", "notthere", "admin@admin"])
    y = "Can't find service with name \"notthere\"."
    x.to_s.chomp.should.equal y
  end

  it "sosy services:delete eraseme no@user (s-5)" do
    x = @app.run(["services:delete", "eraseme", "no@user"])
    y = "Can't find user with email \"no@user\"."
    x.to_s.chomp.should.equal y
  end

  it "sosy services:delete eraseme admin@admin (s-6)" do
    x = @app.run(["services:delete", "eraseme", "admin@admin"])
    y = "Deleted service \"eraseme\" (#3)."
    x.to_s.chomp.should.equal y
  end
end
