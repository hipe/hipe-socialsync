module Hipe::SocialSync::Plugins
  class Services
    include Hipe::Cli
    include Hipe::SocialSync::Model
    cli.out.class = Hipe::Io::GoldenHammer
    cli.default_command = 'help'
    cli.does '-h','--help'
    cli.does(:add, "add a service to the list"){
      option('-h',&help)
      required(:name,"any ol' name you want, not an existing name")
      required(:email,"the email of the person adding this service")
    }
    def add(name, email,opts) 
      out = cli.out.new     
      user = User.first!(:email=>email)
      Service.kreate name, user
      out.puts %{created service "#{name}". Now there are #{Service.count} services.}
      out
    end

    cli.does(:list, "show all services"){
      option('-h',&help)
    }
    def list(opts)
      out = cli.out.new
      out.data.services = Service.all( :order => [:name.asc] )
      out.data.services.each do |svc|
        out.puts sprintf('%-5d  %20s', svc.id, svc.name)
      end
      out.puts %{(#{Service.count} services)}
      out
    end

    cli.does(:delete, "remove the service."){
      option('-h',&help)
      required(:name, 'name of service to delete')      
      required('current-user-email', 'who are you')
    }
    def delete(name, user, opts)
      cli.out.new.puts(Service.remove(name, user))      
    end
  end
end

