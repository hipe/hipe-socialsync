require 'highline/import'    # for password prompting
require 'yaml'               # for representing the intermediate data file
require 'hipe-core/asciitypesetting'
require 'hipe-core/daterange'
require 'pp'


module Hipe::SocialSync::Plugins
  class Tumblr
    include Hipe::Cli::App
    DATETIME_RE = '\d\d(?:\d\d)?-\d\d?-\d\d?(?: \d\d?:\d\d(?::\d\d)?)?{0,2}'
    cli.does :push, {
      :description => "push the intermediate yml file up to tumblr",
      :required => [
        { :name => :YML_IN,
          :description => "the intermediate yml file.",
          :it => [:must_exist, :gets_opened]
        },
        { :name=>:EMAIL,
          :description=>'the email address of your tumblr account'
        }
      ],
      :options => {
        :sleep_every => {
          :description => %{sleep for n seconds after you push these many items, e.g. --sleep-every="10"},
          :range=>(0..1000)
        },
        :sleep_for => {
          :description => %{sleep for this many seconds after n items you push, e.g. --sleep-for="0.123" },
          :range =>(0..1000)
        },
        '-r --date-range' => {
          :description => %{The range of dates of the blogs you want to push, e.g. }+
          %{"--date-range='2010-01-01 10:10 - 2010-02-01 5:55:55'".  (note that the spaces around the middle }+
          %{are important. and a date like "2001-02-03" (with no time) actually means midnight of the previous day.},
          :regexp=>%r{^(#{DATETIME_RE})? - (#{DATETIME_RE})?$},
          :regexp_sentence=>"See description for correct dange ranges"
        },
        :dry => {
          :type => :boolean,
          :description   => %{Don't actually push these up, just show a preview of what you would do.}
        },
        :limit => {
          :description => "only push this many",
          :range => (0...1000)
        }
      }
    } # end command push

    def push yml_file, email, opts
      @dry = opts[:dry]
      @limit = opts[:limit]
      @sleep_for = opts[:sleep_for]
      @sleep_every = opts[:sleep_every]
      @num_pushed = 0
      @password = prompt_for_password      
      @date_range = DateRange[opts[:date_range]]
      raise Exception.factory("Failed to parse intermediate yaml file") unless yml = YAML::load(yml_file[:fh])
      begin
        catch(:limit_reached) do
          yml[:articles].each do |article|
            maybe_push article
          end
        end
      rescue SocketError => e
        err={:msg=>%{Got a socket error: "#{e.message}" -- Is your internet on?  }+
          %{Do you *have* the Internet?},:e=>e}
      rescue RestClient::RequestFailed => e
        err={:msg=>%{Couldn't connect to "#{@last_url}".  Resouce Not Found! ("#{e.message}") }+
          %{-- are you sure you're connected to the internet? }, :e=>e }
      rescue RestClient::RequestFailed => e
        pd = @post_data.clone
        pd[:body] = Hipe::AsciiTypesetting.truncate(@post_data[:body],60)
        pp(pd, str='')
        err={:msg=>%{Failed to push blog entry to target site! Got an exception of type "#{e.class}" }+
        %{that says: "#{e.message}".  We got this response body: "#{e.response.body}".\n\n}+
        %{We tried to push this blog entry: \n#{s}\n\n(end of error)}, :e=>e}
      end
      raise Exception.factory(err[:msg], :original_exception=>err[:e]) if err
      puts "done pushing #{@num_pushed} articles to tumblr."
    end

    def maybe_push article
      if (@sleep_every && (@num_pushed > 0 && (@num_pushed % @sleep_every == 0)))
        @out.puts %{After pushing #{@sleep_every} items, will sleep for #{@sleep_for} seconds}
        sleep @sleep_for
      end      
      if (@date_range and failure = @date_range.outside?(article[:post_date]))
        @out.puts failure
        return
      end
      params = self.params article
      if params[:body].empty?
        @out.puts %{skipping article with empty body from #{params[:date]} ...}
        return
      end
      _push params
      if (@limit && @num_pushed >= @limit)
        puts %{Reached limit of #{@limit} items}
        throw :limit_reached
      end
    end

    def _push post_data
      # http://www.tumblr.com/docs/api#api_write
      post_date_str = post_data[:date]
      @out.puts %{attempting to post article from #{@post_date_str} ...}
      url = 'http://www.tumblr.com/api/write'
      if (@dry)
        @out.puts "(dry run)"
        sleep 0.5
      else
        resp = RestClient.post(url, post_data) #throws on fail
        @out.puts %{(tublr id: "#{resp}")}
      end
      @num_pushed += 1
      print "..done.\n"
    end

    def params article
      {
        :title =>       article[:title],
        :body =>        article[:content],
        :email =>       @cli_arguments[:TUMBLR_ACCOUNT_EMAIL],
        :password =>    @password,
        :type =>        'regular',
        :generator =>   tumblr_generator_name,
        :date =>        article[:post_date],
        :private =>     0,
        :tags =>        article[:tags],
        :format =>      'html'  # html | markdown
      }
    end
  end
end