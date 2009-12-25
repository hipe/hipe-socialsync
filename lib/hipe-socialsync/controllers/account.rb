module Hipe::SocialSync::Plugins
  class Accounts
    include Hipe::Cli
    include Hipe::SocialSync::Model
    cli.out.class = Hipe::Io::GoldenHammer
    cli.default_command = 'help'
    cli.description = "accounts"
    cli.does 'help'
    cli.does(:add, "add an account"){
      option('-h',&help)
      required('service_name')
      required('credential_name')
      required('user_name')
      
    }
    def add service_name, credential_name, user_name, opts=nil
      out = cli.out.new
      user = User.first!(:email=>user_name)
      Account.kreate service_name, credential_name, user_name
      out.puts %{added account for "#{service_name}".}
      out
    end

  #cli.does(:list, "show all accounts")
  #def list(*args)
  #  out = cli.out.new
  #  all = User.all :order => [:email.asc]
  #  all.each{|x| out.puts sprintf('%-5d  %20s', x.id, x.email)}
  #  out.puts %{(#{User.count} users)}
  #  out
  #end
  #
  #cli.does(:delete,"delete user accounts"){
  #  required('email')
  #}
  #def delete email
  #  @out.puts "not implemented!"
  #end
  end
end