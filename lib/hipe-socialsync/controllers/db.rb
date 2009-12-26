module Hipe::SocialSync::Plugins
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
    
    cli.does('list','maybe something')
    def list(opts=nil)
      out = cli.out.new
      o = out.data
      o.common_template = 'list'
      o.separator = ' | '
      o.headers = ['path','size','atime','ctime']
      o.ascii_format_row = lambda{|row|"| %10s | %10s | %20s | %20s |".t(*row) }
      o.row = lambda{|row| 
        [
         # File.basename(o),
         # File.size(o), 
         # time_ago_in_words(File.atime(o)),
         # time_ago_in_words(File.ctime(o))
         File.basename(row[0]),
         row[1], 
         time_ago_in_words(DateTime.parse(row[2]).to_time),
         time_ago_in_words(File.ctime(row[0]))
      ]}
      hack = File.dirname(cli.parent.application.db_path)
      cmd = %{ls -lh #{hack}/*db* } << %q{ | awk '{; print $9 "\t" $5 "\t" $6" "$7" "$8  ; }'}
      result = %x{#{cmd}}
      o.list = result.split("\n").map{|line| line.split("\t") }
      #o.list = Dir[File.join(hack,'*db*')]
      o.human_name = 'database file'
      out
    end
    
    SEC_PER_MIN = 60
    SEC_PER_HOUR = SEC_PER_MIN * 60
    SEC_PER_DAY = SEC_PER_HOUR * 24
    SEC_PER_WEEK = SEC_PER_DAY * 7
    SEC_PER_MONTH = SEC_PER_WEEK * 4

    # action_view was too heavy to pull in just for this
    def time_ago_in_words(t)
      seconds_ago = (Time.now - t)
      in_future = seconds_ago <= 0 
      distance = seconds_ago.abs
      amt, unit, fmt = case distance
        when (0..SEC_PER_MIN)              then [distance,              'second', '%.0f']
        when (SEC_PER_MIN..SEC_PER_HOUR)   then [distance/SEC_PER_MIN,  'minute', '%.1f']
        when (SEC_PER_HOUR..SEC_PER_DAY)   then [distance/SEC_PER_HOUR, 'hour',   '%.1f']
        when (SEC_PER_DAY..SEC_PER_WEEK)   then [distance/SEC_PER_DAY,  'day',    '%.1f']
        else                                    [distance/SEC_PER_WEEK, 'week',   '%.1f']
      end
      number = ((amt.round - amt).abs < 0.1) ? amt.round : fmt.t(amt)
      noun =  ('1' == number.to_s) ? unit : unit.pluralize
      %{#{number} #{noun} #{in_future ? 'from now' : 'ago'}}
    end
    
    cli.does('backup', 'experimental') do
      option('-c','--consistent','output the same thing every time (for testing)')
      option('-o','--out-file PATH','write backup database to this file')
    end
    def backup(opts)
      #filename = db_path
      #begin
      #  if (File.exists?(filename))
      #    backup = opts.out_file || %{#{filename}.#{DateTime.now.strftime('%Y-%m-%d__%H_%I_%S.db')}}
      #    FileUtils.mv(filename,backup)
      #    raise "Rotate only works when we have one (:default) adapter" unless
      #      DataMapper::Repository.adapters.keys == [:default]
      #    DataMapper::Repository.adapters.clear # hack1 -- now that it's not on the filesystem we don't want it here
      #    result = %{Moved #{File.basename(filename)} to }+(opts.consistent ? "backup file." : %{#{backup}.})
      #    connect!
      #    Hipe::SocialSync::Model.auto_migrate
      #  else
      #    result = %{file #{filename} doesn't exist}
      #  end
      #rescue Errno::ENOENT => e
      #  result = Exception.upgrade(e)
      #end
      #Hipe::Io::GoldenHammer[result]
      'needs some reworking'
    end
  end
end
