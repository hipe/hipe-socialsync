module Hipe::SocialSync::Plugins
  class App
    include Hipe::Cli
    include Hipe::SocialSync::ControllerCommon
    include Hipe::Lingual::English

    cli.out.klass = Hipe::Io::GoldenHammer
    cli.does '-h','--help', 'overview of app commands'
    cli.default_command = :help

    cli.does(:transports)
    def transports(opts=nil)
      require 'ruby-debug'
      trans = cli.parent.application.transports
      path = File.join(Hipe::SocialSync::DIR,'lib','hipe-socialsync','transport')
      Dir.new(path).map{|entry| /^(.+)\.rb$/=~ entry ? $1 : nil}.compact.each do |basename|
        require_me = File.join('hipe-socialsync','transport',File.basename(basename))
        require require_me
      end
      instances = {}
      trans.keys.each do |k|
        instances[k] = trans.new_instance(k)
      end
      t = instances[:tumblr]

      begin
        t.username = 'hipe'
        t.as_json = true
        t.record = true
        puts "set tumblr things and press continue to read"
        debugger
        response = t.read
        puts "check response"
        debugger
      end while true


      #instances[:tumblr].read
      return "donzorz."
      c = Class.new
      instances.each do |pair|
        c.send(:define_method,pair[0]){instances[pair[0]]}
      end
      msg = "Play with " << en{np(:the,'transport',instances.keys.map{|x|x.to_s})}.say
      o = c.new
      o.instance_eval{ @eval_me = "\n" * 5 + "debugger\n" + msg.dump + "\n" * 5; @file = __FILE__; @line = __LINE__}
      def o.go
        puts @eval_me
        instance_eval @eval_me, @file, @line
      end
      o.go
    end




    cli.does(:prune, 'erase temp files and files deemed not worthy.') do
      option('-h',&help)
      option('-d','--dry','dry run. show a preview of which folders/files you would off')
    end
    def prune opts
      out = cli.out.new
      out.string.flush_to << $stdout
      lizt = prune_files
      if lizt.size == 0
        out.puts "# (no files to prune.)"
      end
      lizt.each do |entry|
        fake_cmd = "rm -rf #{entry}"
        if (opts.dry)
          out.puts fake_cmd
          sleep(0.06)
        else
          out.puts fake_cmd
          FileUtils.remove_entry_secure entry
        end
      end
      out
    end

    # @return array of absolute (?) filenames
    def prune_files
      root = cli.parent.application.data_path
      these_folders =
      folder_list = [
        'coverage/',
        'pkg/'
      ].map{|x| Dir[File.join(root, x)] }.flatten # only the ones that exits
      these_files = Dir[File.join(root,'data/test.db.*')]
      these_folders + these_files
    end
  end
end
