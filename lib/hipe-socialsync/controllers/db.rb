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
    def init(opts)  
      path = cli.parent.application.db_path
      out = cli.out.new
      if File.exist?(path)
        out.puts %{File already exists: "#{path}."}
        out.puts %{Consider db:backup and erasing the db?  Nothing accomplished.}
      else
        out.puts %{File didn't exist: "#{path}."}
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
      o.ascii_format_row = lambda{|row| "| %10s | %6s | %14s | %14s |".t(*row) }
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
    
    
     
     cli.does('backup', 'experimental') do
       option('-c','--consistent','output the same thing every time (for testing)')
       option('-o','--out-file PATH','write backup database to this file')
     end
     def backup(opts)
      filename = db_path
      begin
        if (File.exists?(filename))
          backup = opts.out_file || %{#{filename}.#{DateTime.now.strftime('%Y-%m-%d__%H_%I_%S.db')}}
          FileUtils.mv(filename,backup)
          raise "Rotate only works when we have one (:default) adapter" unless
            DataMapper::Repository.adapters.keys == [:default]
          DataMapper::Repository.adapters.clear # hack1 -- now that it's not on the filesystem we don't want it here
          result = %{Moved #{File.basename(filename)} to }+(opts.consistent ? "backup file." : %{#{backup}.})
          connect!
          Hipe::SocialSync::Model.auto_migrate
        else
          result = %{file #{filename} doesn't exist}
        end
      rescue Errno::ENOENT => e
        result = Exception.upgrade(e)
      end
      Hipe::Io::GoldenHammer[result]
      'needs some reworking'
    end
  end
end