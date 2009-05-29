require 'rack/response'
require 'uri'

MONTHS = %w(stycznia lutego marca kwietnia maja czerwca lipa sierpnia września pażdziernika listopada grudnia)

def colorize!(content)
  content.gsub!(%r|\{geshi +lang=(.+?)\}(.+?)\{/geshi\}|m) { "<pre>#{$2}</pre>" }
end

def tag(body, pattern, replacement)
  body.gsub! %r|<#{pattern}/>|, replacement.to_s
  body.gsub! %r|&#{pattern};|, replacement.to_s
end

def parse_with_comment(body, comment, counter = 0)
  tag body, "COMMENT_CLASS", "comment#{(counter % 2)+1}"
  tag body, "COMMENT_EDIT_HREF", "/edit_me_please"
  tag body, "COMMENT_NICK", comment[:nick]
  tag body, "COMMENT_DATE", "#{comment[:date].day} #{MONTHS[comment[:date].month]} #{comment[:date].hour}"
  tag body, "COMMENT_DATE_DAY", comment[:date].day
  tag body, "COMMENT_DATE_MONTH", MONTHS[comment[:date].month]
  tag body, "COMMENT_DATE_YEAR", comment[:date].year
  tag body, "COMMENT_HOUR", comment[:date].hour
  tag body, "COMMENT_NUMBER", counter+1
  tag body, "COMMENT_CONTENT", comment[:content]
  tag body, "COMMENT_FAVICON", comment[:favicon]
  tag body, "COMMENT_FAVICON2", comment[:favicon]
  tag body, "COMMENT_ID", rand(100)
  tag body, "COMMENT_NICK_CLASS", comment[:class]
  
  body.gsub!(%r|<COMMENT_FAVICON_EXIST>(.+?)</COMMENT_FAVICON_EXIST>|m) { comment[:favicon] ? parse_with_comment($1, comment, counter) : "" }
  body.gsub!(%r|<COMMENT_FAVICON_NOT_EXIST>(.+?)</COMMENT_FAVICON_NOT_EXIST>|m) { comment[:favicon] ? "" : parse_with_comment($1, comment, counter) }
  body.gsub!(%r|<COMMENT_EDIT_EXIST>(.+?)</COMMENT_EDIT_EXIST>|m) { comment[:edit] ? parse_with_comment($1, comment, counter) : "" }
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
  
  colorize!(entry[:content])
  
  tag body, "ENTRY_CONTENT", entry[:content].sub(%r|<EXCERPT>|, "")
  tag body, "ENTRY_CONTENT_LONG", entry[:content].split(%r|<EXCERPT>|).last
  tag body, "ENTRY_CONTENT_SHORT", entry[:content].split(%r|<EXCERPT>|).first
  body.gsub!(%r|<ENTRY_CONTENT_SHORT_EXIST>(.+?)</ENTRY_CONTENT_SHORT_EXIST>|m) { entry[:content]["<EXCERPT>"] ? parse_with_entry($1, entry) : "" }
  body.gsub!(%r|<ENTRY_CONTENT_SHORT_NOT_EXIST>(.+?)</ENTRY_CONTENT_SHORT_NOT_EXIST>|m) { entry[:content]["<EXCERPT>"] ? "" : parse_with_entry($1, entry) }
  
  tag body, "ENTRY_COMMENT_HREF", "/entry"
  tag body, "ENTRY_COMMENT_HREF_DESCR", entry[:comments] ? "#{entry[:comments].size} komentarzy" : "Brak komentarzy"
  tag body, "ENTRY_CLASS", "entry#{(counter % 2)+1}"
  entry_counter = 0 if body["ENTRY_CLASS_RESET"]
  
  body.gsub!(%r|<ENTRY_CATEGORY_BLOCK>(.+?)</ENTRY_CATEGORY_BLOCK>|m) do
    category_block = $1
    category_counter = -1
    entry[:categories].map do |category|
      catbody = category_block.dup
      category_counter += 1
      
      tag catbody, "ENTRY_CATEGORY_CLASS", "entrycategory#{(category_counter % 2)+1}"
      tag catbody, "ENTRY_CATEGORY_HREF", "/za_duzo_bys_chcial"
      tag catbody, "ENTRY_CATEGORY_HREF_DESCR", category
      tag catbody, "ENTRY_CATEGORY_TITLE", category
      catbody.gsub!(%r|<ENTRY_CATEGORY_NOT_LAST>(.+?)</ENTRY_CATEGORY_NOT_LAST>|m) { category_counter == entry[:categories].size-1 ? "" : $1 }
      catbody
    end.join
  end
  
  body.gsub!(%r|<ENTRY_TAG_BLOCK_EXIST>(.+?)</ENTRY_TAG_BLOCK_EXIST>|m) { entry[:tags] ? parse_with_entry($1, entry) : "" }
  body.gsub!(%r|<ENTRY_TAG_BLOCK>(.+?)</ENTRY_TAG_BLOCK>|m) do
    tag_block = $1
    entry[:tags].map do |t|
      tagbody = tag_block.dup
      tag tagbody, "ENTRY_TAG_DESCR", t
      tagbody
    end.join
  end
  
  tag body, "ENTRY_TRACKBACK_HREF", entry[:trackback]
  body.gsub!(%r|<ENTRY_TRACKBACK_EXIST>(.+?)</ENTRY_TRACKBACK_EXIST>|m) { entry[:trackback] ? parse_with_entry($1, entry) : "" }
  body.gsub!(%r|<ENTRY_TRACKBACK_NOT_EXIST>(.+?)</ENTRY_TRACKBACK_NOT_EXIST>|m) { entry[:trackback] ? "" : parse_with_entry($1, entry) }
  
  ["PREV", "NEXT"].each do |type|
    p = entry[type.downcase.to_sym]
    
    body.gsub!(%r|<ENTRY_#{type}_EXIST>(.+?)</ENTRY_#{type}_EXIST>|m) { p ? parse_with_entry($1, entry) : "" }
    body.gsub!(%r|<ENTRY_#{type}_NOT_EXIST>(.+?)</ENTRY_#{type}_NOT_EXIST>|m) { p ? "" : parse_with_entry($1, entry) }
   
    if p
      tag body, "ENTRY_#{type}_SUBJECT", p[:subject]
      tag body, "ENTRY_#{type}_TITLE", p[:subject]
      tag body, "ENTRY_#{type}_CONTENT", p[:content].sub(%r|<EXCERPT>|, "")
      tag body, "ENTRY_#{type}_CONTENT_SHORT", p[:content].split(%r|<EXCERPT>|).first
      tag body, "ENTRY_#{type}_DATE", "#{p[:date].day} #{MONTHS[p[:date].month]} #{p[:date].hour}"
      tag body, "ENTRY_#{type}_HREF", "/entry"
    end
  end

  body.gsub!(%r|<ENTRY_IS_MINIBLOG>(.+?)</ENTRY_IS_MINIBLOG>|m) { entry[:miniblog] ? parse_with_entry($1, entry) : "" }
  
  body
end

def parse(type, body)  
  body.gsub!(%r|<INCLUDE>(.+?)</INCLUDE>|) { parse nil, File.read("files/#{$1}") }
  
  body.gsub!(%r|<ARCHIVE_BLOCK>(.+?)</ARCHIVE_BLOCK>|m) do
    archive_block = $1
    archive_counter = -1
    @Jogger[:archive].map do |archive|
      archive_counter += 1
      archbody = archive_block.dup
      
      tag archbody, "ARCHIVE_ENTRIES", archive[:entries]
      tag archbody, "ARCHIVE_HREF", "/za_duzo_bys_chcial"
      tag archbody, "ARCHIVE_HREF_DESCR", archive[:name]
      tag archbody, "ARCHIVE_CLASS", "archive#{(archive_counter % 2)+1}"
      tag archbody, "ARCHIVE_CURRENT_DESCR", "Maj 2009"
      archbody.gsub!(%r|<ARCHIVE_NOT_LAST>(.+?)</ARCHIVE_NOT_LAST>|m) { archive_counter == @Jogger[:archive].size-1 ? "" : $1 }
      archbody
    end.join
  end
  
  body.gsub!(%r|<CATEGORY_BLOCK>(.+?)</CATEGORY_BLOCK>|m) do
    category_block = $1
    category_counter = -1
    @Jogger[:categories].map do |category|
      catbody = category_block.dup
      category_counter += 1
      
      tag catbody, "CATEGORY_CLASS", "category#{(category_counter % 2)+1}"
      tag catbody, "CATEGORY_ENTRIES", category[:entries]
      tag catbody, "CATEGORY_HREF", "/za_duzo_bys_chcial"
      tag catbody, "CATEGORY_HREF_DESCR", category[:name]
      tag catbody, "CATEGORY_TITLE", category[:name]
      tag catbody, "CATEGORY_ID", category_counter
      tag catbody, "CATEGORY_LEVEL", rand(6)
      tag catbody, "CATEGORY_SUB_CLASS", "subcategory#{category[:sub]}"
      catbody.gsub!(%r|<CATEGORY_NOT_LAST>(.+?)</CATEGORY_NOT_LAST>|m) { category_counter == @Jogger[:categories].size-1 ? "" : $1 }
      catbody
    end.join
  end
  
  body.gsub!(%r|<LINK_BLOCK_EXIST>(.+?)</LINK_BLOCK_EXIST>|m) { @Jogger[:links] ? parse(nil, $1) : "" }
    
  body.gsub!(%r|<LINK_GROUP_BLOCK>(.+?)</LINK_GROUP_BLOCK>|m) do
    link_group_block = $1
    link_counter = -1
    @Jogger[:links].map do |link_group|
      grobody = link_group_block.dup
      tag grobody, "LINK_GROUP_DESCR", link_group[:name]
      
      grobody.gsub!(%r|<LINK_BLOCK>(.+?)</LINK_BLOCK>|m) do
        link_block = $1
        link_group[:links].map do |link|
          link_counter += 1
          linkbody = link_block.dup
          
          tag linkbody, "LINK_HREF", "/za_duzo_bys_chcial"
          tag linkbody, "LINK_HREF_DESCR", link
          tag linkbody, "LINK_TITLE", link
          tag linkbody, "LINK_CLASS", "link#{(link_counter % 2)+1}"
          link_counter = -1 if linkbody["LINK_CLASS_RESET"]
          
          linkbody
        end.join
      end
      
      grobody
    end.join
  end
  
  tag body, "JID", "me@jabber.foo"
  tag body, "JOG_TITLE", "My super awesome jogger"
  tag body, "JOG", "teamon"
  tag body, "HOME", "/"
  tag body, "RSS", "/rss"
  tag body, "ALL_ENTRIES_HREF", "/"
  tag body, "CURRENT_PAGE_HREF", "/entry"
  
  tag body, "HEADER", <<-HEADER
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html lang="pl">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta name="robots" content="noindex, nofollow">
<title>Jogger :: teamon</title>
<link rel="StyleSheet" href="/files/style.css" type="text/css">
</head>
<body>
  HEADER
  
  tag body, "FOOTER", <<-FOOTER  
</body>
</html>
  FOOTER
  
  case type
  when :entries
    body.gsub!(%r|<MINIBLOG_BLOCK>(.+?)</MINIBLOG_BLOCK>|m) do
      $1.gsub!(%r|<ENTRY_BLOCK>(.+?)</ENTRY_BLOCK>|m) do
        entry_block = $1
        entry_counter = -1
        @Jogger[:entries].select {|e| e[:miniblog] }.map {|entry| parse_with_entry(entry_block.dup, entry, entry_counter += 1) }.join    
      end
    end
    
    body.gsub!(%r|<ENTRY_BLOCK>(.+?)</ENTRY_BLOCK>|m) do
      entry_block = $1
      entry_counter = -1
      @Jogger[:entries].reject {|e| e[:miniblog] }.map {|entry| parse_with_entry(entry_block.dup, entry, entry_counter += 1) }.join    
    end
    
    body.gsub!(%r|<PAGE_BLOCK_EXIST>(.+?)</PAGE_BLOCK_EXIST>|) { parse(:entries, $1) }
    body.gsub!(%r|<PAGE_PREV_EXIST>(.+?)</PAGE_PREV_EXIST>|) { parse(:entries, $1) }
    body.gsub!(%r|<PAGE_NEXT_EXIST>(.+?)</PAGE_NEXT_EXIST>|) { parse(:entries, $1) }
    tag body, "PAGE_PREV_HREF", "/prev"
    tag body, "PAGE_NEXT_HREF", "/next"
    

  when :comments
    entry = @Jogger[:entries].first
    parse_with_entry(body, entry)
    
    body.gsub!(%r|<COMMENT_BLOCK>(.+?)</COMMENT_BLOCK>|m) do
      comment_block = $1
      comment_counter = -1
      entry[:comments].map do |comment|
        parse_with_comment(comment_block.dup, comment, comment_counter += 1)
      end.join   
    end

    body.gsub!(%r|<COMMENT_BLOCK_EXIST>(.+?)</COMMENT_BLOCK_EXIST>|m) { entry[:comments] ? parse(:comments, $1) : "" }
    body.gsub!(%r|<COMMENT_BLOCK_NOT_EXIST>(.+?)</COMMENT_BLOCK_NOT_EXIST>|m) { entry[:comments] ? "" : parse(:comments, $1) }    
    body.gsub!(%r|<COMMENT_ALLOWED_BLOCK>(.+?)</COMMENT_ALLOWED_BLOCK>|m) { entry[:comments_allowed] ? parse(:comments, $1) : "" }   
    body.gsub!(%r|<COMMENT_NONE_BLOCK>(.+?)</COMMENT_NONE_BLOCK>|m) { entry[:comments_allowed] ? "" : parse(:comments, $1) }    
    
    
    
    tag body, "COMMENT_FORM", <<-FORM
    <form action="[adres_wpisu]?op=addcomm" method="post" id="formcomment">
      <fieldset>
        <legend id="formname">Dodaj komentarz</legend>
        <div class="commrow1">
          <label id="commnicklab" for="commnickid">Podpis</label>
          <input type="text" name="commnickid" id="commnickid" value="[Twój_jid]" />
        </div>
        <div class="commrow2">
          <label id="commbodylab" for="commbody">Treść</label>
          <textarea name="commbody" id="commbody" cols="60" rows="6"></textarea>
        </div>
        <div>
          <input type="submit" name="submit" id="submitcomm" value="Wyślij komentarz " />
        </div>
      </fieldset>
    </form>
    FORM
    
    tag body, "COMMENT_FORM2", <<-FORM
    <form action="/comment.php" method="post">
    <div>
      <input type="hidden" name="jid" value="[jid_komentowanego]" />
      <input type="hidden" name="eid" value="[id_wpisu]" />
      <input type="hidden" name="startid" value="0" />
      <input type="hidden" name="op" value="addcomm" />
    </div>
    <table>
      <tr>
        <td>Podpis:</td>
        <td><input type="text" name="commnickid" id="commnickid" value="[Twój_jid]" /></td>
      </tr>
      <tr>
        <td>Treść:</td>
        <td><textarea name="commbody" id="commbody" cols="60" rows="6"></textarea></td>
      </tr>
      <tr>
        <td>&nbsp;</td>
        <td>
          <input type="checkbox" name="notifyentry" value="notify" />Śledź ten wątek i powiadom mnie o nowych komentarzach
        </td>
      </tr>
      <tr>
        <td>&nbsp;</td>
        <td><input type='submit' name="submit" id="submitcomm" value='Wyślij' /></td>
      </tr>
    </table>
    </form>    
    FORM
    
    
    body.gsub!(%r|<COMMENT_FORM_BLOCK>(.+?)</COMMENT_FORM_BLOCK>|m) { $1 }
      
    tag body, "COMMENT_FORM_ACTION", "/lawl"
    tag body, "COMMENT_FORM_BODY", "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    tag body, "COMMENT_FORM_CODE", "..."
    tag body, "COMMENT_FORM_NICKID", "teamon"
    tag body, "COMMENT_FORM_NICKURL", "http://blog.teamon.eu"
    
    body.gsub!(%r|<COMMENT_FORM_NOTIFY_START_BLOCK>(.+?)</COMMENT_FORM_NOTIFY_START_BLOCK>|m) { $1 }
    body.gsub!(%r|<COMMENT_FORM_NOTIFY_STOP_BLOCK>(.+?)</COMMENT_FORM_NOTIFY_STOP_BLOCK>|m) { $1 }
    body.gsub!(%r|<COMMENT_FORM_NOUSER_BLOCK>(.+?)</COMMENT_FORM_NOUSER_BLOCK>|m) { $1 }
    body.gsub!(%r|<COMMENT_LOGGED_BLOCK>(.+?)</COMMENT_LOGGED_BLOCK>|) { "" }
    body.gsub!(%r|<COMMENT_NONE_BLOCK>(.+?)</COMMENT_NONE_BLOCK>|m) { entry[:allowed_comments] ? "" : $1 }

  when :login
    
  when :page
    tag body, "PAGE_SUBJECT", @Jogger[:pages].first[:subject]
    tag body, "PAGE_TITLE", @Jogger[:pages].first[:subject]
    tag body, "PAGE_CONTENT", @Jogger[:pages].first[:content]
  else
    
  end
  
  body
end

app = Proc.new do |env|
  path = env["REQUEST_URI"]
  
  if path =~ %r[/files/]
    Rack::File.new(Dir.pwd).call(env)
  else
    @Jogger = YAML.load(File.read("content.yml"))
    
    content = case path
    when "/"
      parse :entries, File.read("Szablon_wpisow.html")
    when "/entry"
      parse :comments, File.read("Szablon_komentarzy.html")
    when "/login"
      parse :login, File.read("Szablon_logowanie.html")
    else
      page_path = "strony/#{path.gsub('-', ' ').gsub('/', '').capitalize}.html"
      title = URI.unescape(path.gsub('/', ''))
      entry_path = "posty/#{title}.html"
          
      if File.exists?(page_path)
        parse :page, File.read(page_path)
      elsif File.exists?(entry_path)
        @Jogger[:entries][0][:subject] = title
        @Jogger[:entries][0][:content] = File.read(entry_path)
        parse :comments, File.read("Szablon_komentarzy.html")
        
      else
        "NotFound"
      end
      
    end
    
    [200, {"Content-type" => "text/html"}, content || ""]
  end
  
end

run app