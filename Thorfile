# this file was originally copy-pasted from webrat's Thorfile.  Thank you Bryan Helmkamp!
module GemHelpers

  def generate_gemspec
    $LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))
    require "cli"
    
    Gem::Specification.new do |s|    
      s.name      = 'hipe-socialsync'
      s.version   = Hipe::Cli::VERSION
      s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
      s.author    = "Mark Meves"
      s.email     = "mark.meves@gmail.com"
      s.homepage  = "http://github.com/hipe/hipe-socialsync"
      s.date      = %q{2009-11-19}  
      s.summary   = %q{Getopt plus validations and help screen generation}  
      s.description  = <<-EOS.strip
      hipe-socialsync is an experimental command-line "framework" that aides
      in parsing commands and options and displaying and formatting
      help screens, etc.
      EOS
      # s.rubyforge_project = "webrat"

      require "git"
      repo = Git.open(".")

      s.files      = normalize_files(repo.ls_files.keys - repo.lib.ignored_files)
      s.test_files = normalize_files(Dir['spec/**/*.rb'] - repo.lib.ignored_files)

      s.has_rdoc = false  #*
      #s.extra_rdoc_files = %w[README.rdoc MIT-LICENSE.txt History.txt]
      s.extra_rdoc_files = %w[MIT-LICENSE.txt History.txt]

      #s.add_dependency "nokogiri", ">= 1.2.0"
      #s.add_dependency "rack", ">= 1.0"
    end
  end

  def normalize_files(array)
    # only keep files, no directories, and sort
    array.select do |path|
      File.file?(path)
    end.sort
  end

  # Adds extra space when outputting an array. This helps create better version
  # control diffs, because otherwise it is all on the same line.
  def prettyify_array(gemspec_ruby, array_name)
    gemspec_ruby.gsub(/s\.#{array_name.to_s} = \[.+?\]/) do |match|
      leadin, files = match[0..-2].split("[")
      leadin + "[\n    #{files.split(",").join(",\n   ")}\n  ]"
    end
  end

  def read_gemspec
    @read_gemspec ||= eval(File.read("hipe-socialsync.gemspec"))
  end

  def sh(command)
    puts command
    system command
  end
end

class Default < Thor
  include GemHelpers

  desc "gemspec", "Regenerate hipe-socialsync.gemspec"
  def gemspec
    File.open("hipe-socialsync.gemspec", "w") do |file|
      gemspec_ruby = generate_gemspec.to_ruby
      gemspec_ruby = prettyify_array(gemspec_ruby, :files)
      gemspec_ruby = prettyify_array(gemspec_ruby, :test_files)
      gemspec_ruby = prettyify_array(gemspec_ruby, :extra_rdoc_files)

      file.write gemspec_ruby
    end

    puts "Wrote gemspec to hipe-socialsync.gemspec"
    read_gemspec.validate
  end

  desc "build", "Build a hipe-socialsync gem"
  def build
    sh "gem build hipe-socialsync.gemspec"
    FileUtils.mkdir_p "pkg"
    FileUtils.mv read_gemspec.file_name, "pkg"
  end

  desc "install", "Install the latest built gem"
  def install
    sh "gem install --local pkg/#{read_gemspec.file_name}"
  end

  desc "release", "Release the current branch to GitHub and Gemcutter"
  def release
    gemspec
    build
    Release.new.tag
    Release.new.gem
  end
end

class Release < Thor
  include GemHelpers

  desc "tag", "Tag the gem on the origin server"
  def tag
    release_tag = "v#{read_gemspec.version}"
    sh "git tag -a #{release_tag} -m 'Tagging #{release_tag}'"
    sh "git push origin #{release_tag}"
  end

  desc "gem", "Push the gem to Gemcutter"
  def gem
    sh "gem push pkg/#{read_gemspec.file_name}"
  end
end