require 'hipe-core/lingual/en' # time_ago_in_words

module Hipe::SocialSync::Plugins
  class En; extend Hipe::Lingual::En::Helpers; end
  class Db
    include Hipe::Cli
    cli.out.klass = Hipe::SocialSync::GoldenHammer
    cli.description = "db stuff"
    cli.default_command = 'help'
    cli.does '-h','--help', 'overview of db commands'

    cli.does('init','set up the db for the first time')
    def init(opts)  # this is not a constructor it is a command!
      path = cli.parent.application.db_path
      out = cli.out.new
      if File.exist?(path)
        out.puts %{File already exists: "#{rel_path(path)}."}
        out.puts %{You could db:archive and earse the db?  Nothing accomplished.}
      else
        out.puts %{File didn't exist: "#{rel_path(path)}."}
        cli.parent.application.db_connect
        Hipe::SocialSync::Model.auto_migrate!
        if File.exist?(path)
          out.puts %{Now it exists.}
        else
          out.puts %{Still doesn't exist!?}
        end
      end
      out
    end

    cli.does('list','peruse')
    # File.atime(), ctime() etc last seen bcdd7bf10439f3a5744be1a6f4c8ff8db9313f4ae. we wanted ls -lh for file size
    def list(opts=nil)
      out = cli.out.new
      o = out.data
      o.common_template = 'list'
      o.separator = ' | '
      o.headers = ['path','size','atime','ctime']
      o.ascii_format_row = lambda{|row| "| %31s | %6s | %17s | %17s |".t(*row) }
      o.row = lambda{|row|
        dt = DateTime.parse(row[2])
        time = Time.local(dt.year,dt.month, dt.day, dt.hour, dt.min, dt.sec )
        [File.basename(row[0]),
         row[1],
         En.time_ago_in_words(time),
         En.time_ago_in_words(File.ctime(row[0]))]
      }
      hack = File.dirname(cli.parent.application.db_path)
      cmd = %{ls -lh #{hack}/*db* } << %q{ | awk '{; print $9 "\t" $5 "\t" $6" "$7" "$8  ; }'}
      result = %x{#{cmd}}
      o.list = result.split("\n").map{|line| line.split("\t") }
      #o.list = Dir[File.join(hack,'*db*')]
      o.human_name = 'database file'
      out
    end

    cli.does('auto-migrate','erases all of the data from the database. no undo. '+
     'for now this is only for the test environment.  runs auto_migrate! on each table/resource') do
       option('-F','this option is required to actually carry out the request')
    end

    def auto_migrate(opts)
      raise %{For now this is only used in the test environment, not "#{opts.env}"} unless opts.env == 'test'
      db_path = cli.parent.application.db_path
      raise %{Expecting test database path, had "#{rel_path(db_path)}"} unless %r{/test\.db$} =~ db_path
      out = cli.out.new
      if (opts[:F])
        Hipe::SocialSync::Model.auto_migrate!
        out << %{auto-migrated #{opts.env} db.}
      else
        out.errors << "The -F option is required to carry out this request.  Note this will erase "+
        "the entire #{opts.env} database.  There is no undo.  (Database: #{db_path})"
      end
      out
    end

    cli.does('archive', 'move the file that the database is in.') do
      option('-o','--out-file PATH','move the databse to this file') do |it|
        it.must_not_exist!
      end
    end
    def archive(opts)
      current_file     = cli.parent.application.db_path
      destination_file = opts.out_file || %{#{current_file}.#{DateTime.now.strftime('%Y-%m-%d__%H_%I_%S.db')}}
      out = cli.out.new
      if ! File.exists?(current_file)
        out.errors << %{Database file doesn't exist: "#{rel_path(current_file)}"}
      else
        cli.parent.application.db_connect
        stack = repository.adapter.send :connection_stack
        #if (stack.size > 0)
        #  connection = stack.last
        #  adapter = repository.adapter.send(:close_connection,connection)
        #end
        DataMapper::Repository.adapters.delete(:default) # hackland
        # connection = repository.adapter.send(:open_connection)
        FileUtils.mv(current_file,destination_file)
        out << %{Moved #{rel_path(current_file)} to #{rel_path(destination_file)}}
      end
      out
    end
    def rel_path(path)
      pwd = Hipe::SocialSync::DIR  # FileUtils.pwd
      re = Regexp.new %{^#{Regexp.escape pwd}/(.+)}
      if (md = re.match(path))
        md[1]
      else
        path
      end
    end
  end
end
