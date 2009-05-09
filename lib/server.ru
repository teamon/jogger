require 'rack/response'


J = YAML.load(File.read("content.yml"))

MONTHS = %w(stycznia lutego marca kwietnia maja czerwca lipa sierpnia września pażdziernika listopada grudnia)

def tag(body, pattern, replacement)
  body.gsub! %r|<#{pattern}/>|, replacement.to_s
  body.gsub! %r|&#{pattern};|, replacement.to_s
end

def parse_with_entry(body, entry, counter = 0)
  tag body, "ENTRY_SUBJECT", entry[:subject]
  tag body, "ENTRY_TITLE", entry[:subject]
  
  tag body, "ENTRY_DATE", "#{entry[:date].day} #{MONTHS[entry[:date].month]} #{entry[:date].hour}"
  tag body, "ENTRY_DATE_DAY", entry[:date].day
  tag body, "ENTRY_DATE_MONTH", MONTHS[entry[:date].month]
  tag body, "ENTRY_DATE_YEAR", entry[:date].year
  tag body, "ENTRY_HOUR", entry[:date].hour
  
  tag body, "ENTRY_ID", rand(100)
  tag body, "ENTRY_LEVEL", rand(3)
  
  tag body, "ENTRY_CONTENT", entry[:content].sub(%r|<EXCERPT>|, "")
  tag body, "ENTRY_CONTENT_LONG", entry[:content].split(%r|<EXCERPT>|).last
  tag body, "ENTRY_CONTENT_SHORT", entry[:content].split(%r|<EXCERPT>|).first
  body.gsub!(%r|<ENTRY_CONTENT_SHORT_EXIST>(.+)</ENTRY_CONTENT_SHORT_EXIST>|m) { entry[:content]["<EXCERPT>"] ? parse_with_entry($1, entry) : "" }
  body.gsub!(%r|<ENTRY_CONTENT_SHORT_NOT_EXIST>(.+)</ENTRY_CONTENT_SHORT_NOT_EXIST>|m) { entry[:content]["<EXCERPT>"] ? "" : parse_with_entry($1, entry) }
  
  tag body, "ENTRY_COMMENT_HREF", "/entry"
  tag body, "ENTRY_COMMENT_HREF_DESCR", "3 komentarze"
  tag body, "ENTRY_CLASS", "entry#{(counter % 2)+1}"
  entry_counter = 0 if body["ENTRY_CLASS_RESET"]
  
  body.gsub!(%r|<ENTRY_CATEGORY_BLOCK>(.+)</ENTRY_CATEGORY_BLOCK>|m) do
    category_block = $1
    category_counter = -1
    entry[:categories].map do |category|
      category_counter += 1
      catbody = category_block.dup
      
      tag catbody, "ENTRY_CATEGORY_CLASS", "entrycategory#{(category_counter % 2)+1}"
      tag catbody, "ENTRY_CATEGORY_HREF", "/za_duzo_bys_chcial"
      tag catbody, "ENTRY_CATEGORY_HREF_DESCR", category
      tag catbody, "ENTRY_CATEGORY_TITLE", category
      catbody.gsub!(%r|<ENTRY_CATEGORY_NOT_LAST>(.+)</ENTRY_CATEGORY_NOT_LAST>|m) { category_counter == entry[:categories].size ? "" : $1 }
      catbody
    end.join
  end
  
  tag body, "ENTRY_TRACKBACK_HREF", entry[:trackback]
  body.gsub!(%r|<ENTRY_TRACKBACK_EXIST>(.+)</ENTRY_TRACKBACK_EXIST>|m) { entry[:trackback] ? parse_with_entry($1, entry) : "" }
  body.gsub!(%r|<ENTRY_TRACKBACK_NOT_EXIST>(.+)</ENTRY_TRACKBACK_NOT_EXIST>|m) { entry[:trackback] ? "" : parse_with_entry($1, entry) }
  
  ["PREV", "NEXT"].each do |type|
    p = type.downcase.to_sym
    
    body.gsub!(%r|<ENTRY_#{type}_EXIST>(.+)</ENTRY_#{type}_EXIST>|m) { p ? parse_with_entry($1, entry) : "" }
    body.gsub!(%r|<ENTRY_#{type}_NOT_EXIST>(.+)</ENTRY_#{type}_NOT_EXIST>|m) { p ? "" : parse_with_entry($1, entry) }
   
    if p = entry[:prev]
      tag body, "ENTRY_#{type}_SUBJECT", p[:subject]
      tag body, "ENTRY_#{type}_TITLE", p[:subject]
      tag body, "ENTRY_#{type}_CONTENT", p[:content].sub(%r|<EXCERPT>|, "")
      tag body, "ENTRY_#{type}_CONTENT_SHORT", p[:content].split(%r|<EXCERPT>|).first
      tag body, "ENTRY_#{type}_DATE", "#{p[:date].day} #{MONTHS[p[:date].month]} #{p[:date].hour}"
      tag body, "ENTRY_#{type}_HREF", "/entry"
    end
  end
  

  body.gsub!(%r|<ENTRY_IS_MINIBLOG>(.+)</ENTRY_IS_MINIBLOG>|m) { entry[:miniblog] ? parse_with_entry($1, entry) : "" }
  
  body
end

def parse(type, body)
  body.gsub!(%r|<INCLUDE>(.+)</INCLUDE>|) { parse nil, File.read("files/#{$1}") }
  
  body.gsub!(%r|<ARCHIVE_BLOCK>(.+)</ARCHIVE_BLOCK>|m) do
    archive_block = $1
    archive_counter = -1
    J[:archive].map do |archive|
      archive_counter += 1
      archbody = archive_block.dup
      
      tag archbody, "ARCHIVE_ENTRIES", archive[:entries]
      tag archbody, "ARCHIVE_HREF", "/za_duzo_bys_chcial"
      tag archbody, "ARCHIVE_HREF_DESCR", archive[:name]
      tag archbody, "ARCHIVE_CLASS", "archive#{(archive_counter % 2)+1}"
      tag archbody, "ARCHIVE_CURRENT_DESCR", "Maj 2009"
      archbody.gsub!(%r|<ARCHIVE_NOT_LAST>(.+)</ARCHIVE_NOT_LAST>|m) { archive_counter == J[:archive].size ? "" : $1 }
      archbody
    end.join
  end
  
  case type
  when :entries
    body.gsub!(%r|<ENTRY_BLOCK>(.+)</ENTRY_BLOCK>|m) do
      entry_block = $1
      entry_counter = -1
      J[:entries].map {|entry| parse_with_entry(entry_block.dup, entry, entry_counter += 1) }.join    
    end
    
    body.gsub!(%r|<PAGE_BLOCK_EXIST>(.+)</PAGE_BLOCK_EXIST>|) { parse(:entries, $1) }
    body.gsub!(%r|<PAGE_PREV_EXIST>(.+)</PAGE_PREV_EXIST>|) { parse(:entries, $1) }
    body.gsub!(%r|<PAGE_NEXT_EXIST>(.+)</PAGE_NEXT_EXIST>|) { parse(:entries, $1) }
    tag body, "PAGE_PREV_HREF", "/prev"
    tag body, "PAGE_NEXT_HREF", "/next"
    
    
  when :comments
    parse_with_entry(body, J[:entries].first)
    
  when :login
    
  when :page
    tag body, "PAGE_SUBJECT", J[:pages].first[:subject]
    tag body, "PAGE_SUBJECT", J[:pages].first[:subject]
    tag body, "PAGE_CONTENT", J[:pages].first[:content]
  else
    
  end
  
  body
end

app = Proc.new do |env|
  path = env["REQUEST_URI"]
  
  if path =~ %r[/files/]
    Rack::File.new(Dir.pwd).call(env)
  else
    content = case path
    when "/"
      parse :entries, File.read("Szablon wpisów.html")
    when "/entry"
      parse :comments, File.read("Szablon komentarzy.html")
    when "/login"
      parse :login, File.read("Szablon logowanie.html")
    else
      path = "strony/#{path.gsub('-', ' ').gsub('/', '').capitalize}.html"
      if File.exists?(path)
        parse File.read(path)
      else
        "NotFound"
      end
    end
    
    [200, {"Content-type" => "text/html"}, content || ""]
  end
  
end

run app