module Hipe::SocialSync::Plugins
  class App
    include Hipe::Cli
    include Hipe::SocialSync::ControllerCommon
    cli.out.klass = Hipe::Io::GoldenHammer
    cli.does '-h','--help', 'overview of app commands'
    cli.default_command = :help

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
