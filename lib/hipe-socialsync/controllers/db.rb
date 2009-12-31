require 'hipe-core/lingual/en' # time_ago_in_words

module Hipe::SocialSync::Plugins
  class En; extend Hipe::Lingual::En::Helpers; end
  class Db
    include Hipe::Cli
    include Hipe::SocialSync::ControllerCommon
    include Hipe::SocialSync::Model

    cli.out.klass = Hipe::SocialSync::GoldenHammer
    cli.description = "db stuff"
    cli.default_command = 'help'
    cli.does '-h','--help', 'overview of db commands'

    cli.does('init','set up the db for the first time') do
      # option('--fi[x]tures','load them')
    end
    def init(opts)  # this is not a constructor it is a command!
      path = cli.parent.application.db_path
      out = cli.out.new
      if File.exist?(path)
        out.puts %{File already exists: "#{rel_path(path)}."}
        out.puts %{Do you want to db:archive the db first?  Nothing accomplished.}
      else
        out.puts %{File didn't exist: "#{rel_path(path)}."}
        cli.parent.application.db_connect
        Hipe::SocialSync::Model.auto_migrate!
        out.puts %{Ran Hipe::SocialSync::Model.auto_migrate!}
        if File.exist?(path)
          out.puts %{Now it exists.}
        else
          out.puts %{Still doesn't exist!?}
        end
      end
      out
    end

    # cli.does('fixtures','load them (experimental -- bacon tests *as* fixtures)')
    # def fixtures(opts=nil)
    #   hard_coded_filepath = File.join(Hipe::SocialSync::DIR,'spec','fixtures','experiment.rb')
    #   require 'bacon'
    #   require hard_coded_filepath
    #   'done attempting to load fixtures'
    # end
    #
    cli.does('list','peruse')
    # File.atime(), ctime() etc last seen bcdd7bf10439f3a5744be1a6f4c8ff8db9313f4ae. we wanted ls -lh for file size
    def list(opts=nil)
      out = cli.out.new :suggested_template
      o = out.data
      o.tables = [Hipe::Table.make do
        field(:path)  {|x| File.basename(x[0]) }
        field(:size)  {|x| x[1] }
        field(:atime) do |x|
                              dt = DateTime.parse(x[2])      # @todo help i need a second opinion
                              time = Time.local(dt.year,dt.month, dt.day, dt.hour, dt.min, dt.sec )
                              En.time_ago_in_words(time)
        end
        field(:ctime) {|x| En.time_ago_in_words(File.ctime(x[0])) }
      end]

      db_folder = File.dirname(cli.parent.application.db_path)
      cmd = %{ls -lh #{db_folder}/*db* } << %q{ | awk '{; print $9 "\t" $5 "\t" $6" "$7" "$8  ; }'}
      result = %x{#{cmd}}
      o.table.list = result.split("\n").map{|line| line.split("\t") }
      out
    end

    cli.does('auto-migrate','erases all of the data from the database. no undo. '+
     'for now this is only for the test environment.  runs auto_migrate! on each table/resource') do
       option('-F [ENV]','this option is required to actually carry out the request')
    end

    def auto_migrate(opts)
      #if respository.storage_exists?('items') && opts.env != 'test' && Items.count > 0
      #    throw :invalid
      throw :invalid, ValidationErrors[
        %{For now this is only used in the test environment, not #{opts.env}.  For your needs, }<<
        %{consider db:archive and then db:init instead. }
      ] unless (opts.env == 'test' or opts.env && opts[:F] && opts.env == opts[:F])
      db_path = cli.parent.application.db_path
      db_path_re = Regexp.new(Regexp.escape((opts[:F] && opts[:F].strip) || 'test')<<'\.db$')
      throw :invalid, ValidationErrors[
        %{Expecting database path to match #{db_path_re}, had "#{rel_path(db_path)}"}
      ] unless ( db_path_re =~ db_path )
      throw :invalid, ValidationErrors[
        "The -F option is required to carry out this request.  Note this will erase "<<
        "the entire #{opts.env} database.  There is no undo.  (Database: #{db_path})"
      ] unless opts[:F]
      out = cli.out.new
      Hipe::SocialSync::Model.auto_migrate!
      out << %{auto-migrated #{opts.env} db.}
      out
    end

    cli.does('archive', 'move the file that the database is in.') do
      option('-o','--out-file PATH','move the databse to this file') do |it|
        it.must_not_exist
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
