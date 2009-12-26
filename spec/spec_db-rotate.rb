# bacon -n '.*' spec/spec_db-rotate.rb
require 'hipe-socialsync'
require 'hipe-core/test/bacon-extensions'


describe "db-rotate" do

  it "should write to backup file *and reconnect and write to new db* *and automigrate* even if you don't need it (dbr-1)" do
    @app = Hipe::SocialSync::App.new
    outfile = File.join(Hipe::SocialSync::DIR,'spec','writable-temp','backup.db')
    FileUtils.rm(outfile) if File.exist?(outfile)
    debugger
    x = @app.run(["db-rotate", "-o", outfile])
    y = %{Moved dev.db to #{outfile}.}
    x.to_s.should.equal y
    (File.exist?(outfile)).should.equal true
    path = @app.db_path
    File.exist?(path).should.equal true
    FileUtils.rm(outfile) # cleanup
  end

end
