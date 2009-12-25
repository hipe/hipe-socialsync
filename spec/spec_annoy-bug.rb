# bacon -n '.*' spec/spec_annoy-bug.rb
require 'hipe-socialsync'

describe "Annoy Bug" do

  it "# bad plugin name (ab-0)" do
    @app = Hipe::SocialSync::App.new 
    x = @app.run(["db:rotate"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Unrecognized plugin "db". Known plugins are "accounts", "item", "services", "users" and "wp"
    __HERE__
    x.to_s.chomp.should.equal y
  end
  
  it "# bad plugin name (ab-0.5)" do
    @app = Hipe::SocialSync::App.new 
    x = @app.run(["db:rotate"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    Unrecognized plugin "db". Known plugins are "accounts", "item", "services", "users" and "wp"
    __HERE__
    x.to_s.chomp.should.equal y
  end  
  
  it "# move database. (ab-1)" do
    debugger
    x = @app.run(["db-rotate", "-c"])
    y =<<-__HERE__.gsub(/^    /,'').chomp
    moved dev.db to backup file.
    __HERE__
    x.to_s.chomp.should.equal y
  end  
  
end