# encoding: UTF-8

module Pluto


module TemplateHelper

  def strip_tags( hy )
    ### tobe done
    ## strip markup tags; return plain text
    hy.gsub( /<[^>]+>/, '' )
  end


  def whitelist( hy, tags, opts={} )

    # note: assumes properly escaped <> in hy/hypertext
    
    ###############################################
    # step one - save whitelisted tags use ‹tag›
    tags.each do |tag|
      # make sure we won't swall <br> for <b> for example, thus use \s+ before [^>]
      # note: we strip all attribues
      hy = hy.gsub( /<(\/#{tag}|#{tag}\s*\/)>/, "‹\1›" )  # closing tag e.g. </p> or compact tag e.g. <p/> or <p />
      ## todo: check if <p /> or <p /> is allowed or exists in the wild w/ xhtml
      #  todo: we should normalize it to <tag/> w/o any spaces
      hy = hy.gsub( /<(#{tag})(\s+[^>]*)?>/, "‹\1›" )  # opening tag <p>
    end
    
    # hack: normalize <tag /> or <tag  />  to => <tag/>, that is, remove all spaces
    hy = hy.gsub( /\s+\/›/, '/›' )    # is this a real case, needed?

    ############################
    # step two - clean tags

    #   strip images - special treatment for debugging
    hy = hy.gsub( /<img[^>]*>/, '♦' )   # for debugging use black diamond e.g. ♦
    hy = hy.gsub( /<\/img>/, '' )   # should not exists

    # strip all remaining tags
    hy = hy.gsub( /<[^>]+>/, '' )
    
    ############################################
    # step three - restore whitelisted tags

    hy
  end  # method whitelist

  ##  change to simple_hypertext or
  #     hypertext_simple or
  #     sanitize ???
  
  def textify( hy )   # hy -> hypertext
    ## turn into text
    # todo: add options for
    #   keep links, images, lists (?too), code, codeblocks

    hy = whitelist( hy, [:br, :p, :ul, :ol, :li, :pre, :code] )

   # strip bold
#    hy = hy.gsub( /<b[^>]*>/, '**' )  # fix: will also swallow bxxx tags - add b space
#    hy = hy.gsub( /<\/b>/, '**' )

    # strip em
#   hy = hy.gsub( /<em[^>]*>/, '__' )
#   hy = hy.gsub( /<\/em>/, '__' )

    # clean (prettify) literal urls (strip protocoll) 
    hy = hy.gsub( /(http|https):\/\//, '' )

#    hy = hy.gsub( /&nbsp;/, ' ' )

#    # try to cleanup whitespaces
#    # -- keep no more than two spaces
#    hy = hy.gsub( /[ \t]{3,}/, '  ' )
#    # -- keep no more than two new lines
#    hy = hy.gsub( /\n{2,}/m, "\n\n" ) 
#    # -- remove all trailing spaces
#    hy = hy.gsub( /[ \t\n]+$/m, '' )
#    # -- remove all leading spaces
#    hy = hy.gsub( /^[ \t\n]+/m, '' ) 

    hy
  end


####
# fix: move to DateHelper  ??


  def time_ago_in_words( from_time )
    from_time = from_time.to_time
    to_time   = Time.now
    
    ### todo: will not handle future dates??
    ## what todo do??
    ## use -1..-50000000000 ??  "future"

    ## from_time, to_time = to_time, from_time if from_time > to_time

    distance_in_minutes = ((to_time - from_time)/60.0).round

    case distance_in_minutes
      when 0..1             then  "just now"
      when 2...45           then  "%d minutes ago" % distance_in_minutes
      when 45...90          then  "an hour ago"   ## use one instead of 1 ?? why? why not?
      # 90 mins up to 24 hours
      when 90...1440        then  "%d hours ago" % (distance_in_minutes.to_f / 60.0).round
      # 24 hours up to 42 hours
      when 1440...2520      then "a day ago"   ## use one day ago - why? why not?
      # 42 hours up to 30 days
      when 2520...43200     then "%d days ago" % (distance_in_minutes.to_f / 1440.0).round
      # 30 days up to 60 days
      #  fix: use pluralize for months
      when 43200...86400    then "%d months ago" % (distance_in_minutes.to_f / 43200.0).round
      # 60 days up to 365 days
      when 86400...525600   then "%d months ago" % (distance_in_minutes.to_f / 43200.0).round
      ## fix - add number of years ago
      else                       "over a year ago"  #todo: use over a year ago???
    end
  end


end # module TemplateHelper
end # module Pluto