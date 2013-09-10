module Pluto


class Fetcher

  include LogUtils::Logging

  include Models

  def initialize( opts, config )
    @opts    = opts
    @config  = config
    @worker  = ::Fetcher::Worker.new
  end

  attr_reader :opts, :config, :worker


  def fetch_feed( url )
    xml = worker.read( url )

    ###
    # NB: Net::HTTP will NOT set encoding UTF-8 etc.
    # will mostly be ASCII
    # - try to change encoding to UTF-8 ourselves
    logger.debug "xml.encoding.name (before): #{xml.encoding.name}"

    #####
    # NB: ASCII-8BIT == BINARY == Encoding Unknown; Raw Bytes Here

    ## NB:
    # for now "hardcoded" to utf8 - what else can we do?
    # - note: force_encoding will NOT change the chars only change the assumed encoding w/o translation
    xml = xml.force_encoding( Encoding::UTF_8 )
    logger.debug "xml.encoding.name (after): #{xml.encoding.name}"      
    xml
  end


  def parse_feed( xml )
    parser = RSS::Parser.new( xml )
    parser.do_validate            = false
    parser.ignore_unknown_element = true

    puts "Parsing feed..."
    feed = parser.parse
      
    puts "  feed.class=#{feed.class.name}"
    feed
  end


  def run
    logger.debug "RSS::VERSION #{RSS::VERSION}"

    config[ 'feeds' ].each do |feed_key|
      
      feed_hash  = config[ feed_key ]
      feed_url   = feed_hash[ 'feed_url' ]
      
      puts "Fetching feed >#{feed_key}< using >#{feed_url}<..."

      feed_rec = Feed.find_by_key( feed_key )
      if feed_rec.nil?
        feed_rec      = Feed.new
        feed_rec.key  = feed_key
      end
      feed_rec.feed_url = feed_url
      feed_rec.url      = feed_hash[ 'url' ]
      feed_rec.title    = feed_hash[ 'title' ]    # todo: use title from feed?
      feed_rec.save!

      feed_xml = fetch_feed( feed_url )

#      if opts.verbose?  # also write a copy to disk
#        ## fix: use just File.write instead of fetching again
#        worker.copy( feed_url, "./#{feed_key}.xml" )
#      end

      # xml = File.read( "./#{feed_key}.xml" )

      puts "Before parsing feed >#{feed_key}<..."

      feed = parse_feed( feed_xml )

      if feed.class == RSS::Atom::Feed
        puts "== #{feed.title.content} =="
      else  ## assume RSS::Rss::Feed
        puts "==  #{feed.channel.title} =="
      end

      feed.items.each do |item|
        if feed.class == RSS::Atom::Feed
          item_attribs = handle_feed_item_atom( item )
        else  ## assume RSS::Rss::Feed
          item_attribs = handle_feed_item_rss( item )
        end

        # add feed_id fk_ref
        item_attribs[ :feed_id ] = feed_rec.id

        rec = Item.find_by_guid( item_attribs[ :guid ] )
        if rec.nil?
          rec      = Item.new
          puts "** NEW"
        else
          puts "UPDATE"
        end
                
        rec.update_attributes!( item_attribs )
      end  # each item

    end # each feed

  end # method run


  def handle_feed_item_atom( item )

        ## todo: if content.content empty use summary for example
        item_attribs = {
          title:        item.title.content,
          url:          item.link.href,
          published_at: item.updated.content.utc.strftime( "%Y-%m-%d %H:%M" ),
          # content:   item.content.content,
        }

        item_attribs[ :guid ] = item.id.content

        if item.summary
          item_attribs[ :content ] = item.summary.content
        else
          if item.content
            text  = item.content.content.dup
            ## strip all html tags
            text = text.gsub( /<[^>]+>/, '' )
            text = text[ 0..400 ] # get first 400 chars
            ## todo: check for length if > 400 add ... at the end???
            item_attribs[ :content ] = text
          end
        end

        puts "- #{item.title.content}"
        puts "  link >#{item.link.href}<"
        puts "  id (~guid) >#{item.id.content}<"
        
        ### todo: use/try published first? why? why not?
        puts "  updated (~pubDate) >#{item.updated.content}< >#{item.updated.content.utc.strftime( "%Y-%m-%d %H:%M" )}< : #{item.updated.content.class.name}"
        puts
        
        # puts "*** dump item:"
        # pp item

        item_attribs
  end

  def handle_feed_item_rss( item )

       item_attribs = {
          title:        item.title,
          url:          item.link,
          published_at: item.pubDate.utc.strftime( "%Y-%m-%d %H:%M" ),
          # content:  item.content_encoded,
        }
        
        # if item.content_encoded.nil?
          # puts " using description for content"
          item_attribs[ :content ] = item.description
        # end
        
        item_attribs[ :guid ] = item.guid.content
        
        puts "- #{item.title}"
        puts "  link (#{item.link})"
        puts "  guid (#{item.guid.content})"
        puts "  pubDate >#{item.pubDate}< >#{item.pubDate.utc.strftime( "%Y-%m-%d %H:%M" )}< : #{item.pubDate.class.name}"
        puts

        # puts "*** dump item:"
        # pp item

        item_attribs
  end


end # class Fetcher

end # module Pluto
