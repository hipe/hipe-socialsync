require 'highline/import'    # for password prompting
require 'hipe-core/lingual/ascii-typesetting'
require 'hipe-core/struct/daterange'
require 'openstruct'

module Hipe::SocialSync::Plugins
  class Tumblr
    Url = 'http://www.tumblr.com/api/write'   # http://www.tumblr.com/docs/api#api_write
    include Hipe::Cli
    include Hipe::SocialSync::Model
    include Hipe::SocialSync::ControllerCommon
    DATETIME_RE = '\d\d(?:\d\d)?-\d\d?-\d\d?(?: \d\d?:\d\d(?::\d\d)?)?{0,2}'
    def self.generator_name; 'ADE - slow burn' end

    cli.does('push',"push the intermediate yml file up to tumblr") do
      option('--sleep-every SEC',  %{sleep for n seconds after you push these many items, e.g.}+
                                   %{ --sleep-every="10"}){
        it.must_be_integer.must_be_in_range(0..60)
      }
      option('--sleep-for SEC',%{sleep for this many seconds after n items you push, }+
                               %{e.g. --sleep-for="0.123" }){
        it.must_be_in_range(0..600)
      }
      option('-r','--date-range RANGE', %{The range of dates of the blogs you want to push, e.g. }+
          %{"--date-range='2010-01-01 10:10 - 2010-02-01 5:55:55'".  (note that the spaces around the middle }+
          %{are important. and a date like "2001-02-03" (with no time) actually means midnight of the previous day.}){
        it.must_match_regexp(%r{^(#{DATETIME_RE})? - (#{DATETIME_RE})?$},"See description for correct dange ranges")
      }
      option('-d', '--dry', %{Don't actually push these up, just show a preview of what you would do.})
      option('--limit LIMIT',"only push this many", :default=>2){
        it.must_be_integer.must_be_in_range(0..20)
      }
      required('from-service','wp|tumblr', ['wp','tumblr'])
      required('from-service-username')
      required('email','the email address of your tumblr account')
    end

    def push from_svc, from_cred, to_cred, current_user_email, opts
      @out = cli.out.new
      @password = prompt_for_password
      @url = Url
      @to_cred = to_cred

      # validate that objects exist
      user = User.first!(:email=>current_user_email)
      svc = Service.first!(:name=>from_svc)
      acct = Account.first!(:name_credential=>from_cred,:service=>svc,:user=>user)

      @dry = opts.dry
      @num_pushed = 0
      @limit = opts.limit
      date_range = DateRange[opts.date_range] || DateRange::Any

      h = {:order => [:published_at.desc]}
      h[:account] = acct
      if (opts.date_range)
        h[:published_at.lt] = date_range.begin
        h[:published_at.gt] = date_range.end
      end

      items = Item.all(h)
      if items.count == 0
        return (@out.puts(%{no wp items found #{date_range}}))
      end

      catch(:limit_reached) do
        items.each do |item|
          push?(article)
        end
      end
      rescue SocketError => e
        err={:message=>%{Got a socket error: "#{e.message}" -- Is your internet on?  }+
          %{Do you *have* the Internet?},:e=>e}
      rescue RestClient::RequestFailed => e
        pd = @post_data.clone
        pd[:body] = Hipe::AsciiTypesetting.truncate(@post_data[:body],60)
        pp(pd, str='')
        err={:message=>%{Failed to push blog entry to #{@url}! Got an exception of type "#{e.class}" }+
        %{that says: "#{e.message}".  We got this response body: "#{e.response.body}".\n\n}+
        %{We tried to push this blog entry: \n#{s}\n\n(end of error)}, :e=>e}
      end
      raise Exception[err[:message],{:original_exception=>err[:e]}] if err
      @out.puts "done pushing #{@num_pushed} articles to tumblr."
    end

    def push? item
      if (@sleep_every && (@num_pushed > 0 && (@num_pushed % @sleep_every == 0)))
        @out.puts %{After pushing #{@sleep_every} items, will sleep for #{@sleep_for} seconds}
        sleep @sleep_for
      end

      if item.content.strip.empty?
        @out.puts %{skipping article with empty body from #{item.published_at} ...}
        return
      end

      push! item

      if (@limit && @num_pushed >= @limit)
        @out.puts %{Reached limit of #{@limit} items}
        throw :limit_reached
      end
    end

    def push! item
      post_data = post_data item
      @post_date_str = item.published_at.to_s
      @out.puts %{attempting to post article from #{@post_date_str} ...}
      if (@dry)
        @out.puts "(dry run)"
        sleep 0.5
      else
        resp = Exception.wrap { RestClient.post(@url, post_data) }
        @out.puts %{(tublr id: "#{resp}")}
      end
      @num_pushed += 1
      @out.puts "..done."
    end

    def post_data item
      o = OpenStruct.new
      o.title       =   item.title
      o.body        =   item.content
      o.email       =   @to_cred
      o.password    =   @password
      o.type        =   'regular'
      o.generator   =   self.generator_name
      o.date        =   item.published_at
      o.private     =   0
      o.tags        =   item.tags
      o.format      =   'html'  # html | markdown
      o
    end
  end
end
