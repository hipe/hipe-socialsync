module Hipe::SocialSync::Plugins
  class Services
    include Hipe::Cli
    include Hipe::SocialSync::Model
    cli.out.class = Hipe::SocialSync::GoldenHammer
    cli.description = "manage services"
    cli.default_command = 'help'
    cli.does '-h','--help'
    
    cli.does(:add, "add a service to the list"){
      option('-h',&help)
      required(:name,"any ol' name you want, not an existing name")
      required(:current_user_email, "the email of the person adding this service")
    }
    def add name, email, opts
      out = cli.out.new     
      admin = User.first_or_throw :email=>email
      Service.kreate name, admin
      # out.puts %{created service "#{name}". Now there are #{Service.count} services.}
      out.puts %{Created service "#{name}".  Now }+Hipe::Lingual.en{sp(np('service',Service.count))}.say+'.'
      out
    end

    cli.does(:list, "show all services"){
      option('-h',&help)
    }
    def list(opts)
      out = cli.out.new
      out.data.common_template = 'list'      
      out.data.list = Service.all :order => [:name.asc] 
      out.data.klass = Service
      out.data.row = lambda{|x| ['%-5d'.t(x.id),'%20s'.t(x.name)]}
      out
    end

    cli.does(:delete, "remove the service."){
      option('-h', &help)
      required(:name, 'name of service to delete')      
      required(:current_user_email, 'who are you.')
    }
    def delete name, current_user_email, opts=nil
      out = cli.out.new
      out << Service.remove(name, User.first_or_throw(:email=>current_user_email))
      out
    end
  end
end