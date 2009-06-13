require 'mechanize'
require 'ezcrypto'

class Rubber
  def initialize(args)
    @args = args
    @agent = WWW::Mechanize.new
  end

  def run
    case @args[0]
    when 'configure'
      configure
    when 'download'
      download
    when 'upload'
      @args.shift
      upload(@args)
    when 'server'
      server
    else
      usage
    end
  end

  protected

  def ez
    EzCrypto::Key.with_password "password", (RUBY_PLATFORM =~ /mswin32/ ? `hostname` : `uname -a`)
  end

  def load_config_file
    if File.exists?("config.yml")
      @config = YAML.load(File.read("config.yml"))
      @config[:password] = ez.decrypt64 @config[:password]
    else
      puts "Brak pliku config.yml. Uruchom 'rubber configure'"
      exit
    end
  end

  def configure
    print "jabber id: "
    id = STDIN.gets.chomp
    print "hasło: "
    system "stty -echo"
    pass = ez.encrypt64 STDIN.gets.chomp
    system "stty echo"
    puts

    File.open("config.yml", "w") {|f| f.write YAML.dump({:jabber_id => id, :password => pass}) }
    File.open("content.yml", "w") {|f| f.write File.read(File.join(File.dirname(__FILE__), "content.yml.sample")) } unless File.exists?("content.yml")
    puts "Plik config.yml został utworzony."
  end

  def server
    system("thin start -R #{File.join(File.dirname(__FILE__), "server.ru")} -p 1337")
  end

  def download
    login
    get_filemap
    get_pagesmap

    # files
    Dir.mkdir("files") unless File.exists?("files")
    @filemap.each do |filename, url|
      puts "Pobieranie #{filename}"

      if confirm(filename)
        File.open(filename, 'wb') {|f| f.write @agent.get(url).body }
      end
    end

    # strony
    Dir.mkdir("strony") unless File.exists?("strony")
    @pagesmap.each do |filename, url|
      puts "Pobieranie #{filename}"

      if confirm(filename)
        File.open(filename, 'w') {|f| f.write @agent.get("https://login.jogger.pl#{url}").forms.first.templatesContent }
      end
    end
    
    # posty
    Dir.mkdir("posty") unless File.exists?("posty")
    File.open(File.join("posty", "new_one.html"), 'w') {|f| f.write File.read(File.join(File.dirname(__FILE__), "new_entry.html.sample"))} unless File.exists?(File.join("posty", "new_one.html"))
  end

  def upload(files = [])
    login
    get_filemap
    get_pagesmap

    files.each do |file|
      if url = @pagesmap[file]
        form = @agent.get(url).forms.first
        form.templatesContent = File.read(file)
        form.submit
        puts "Plik #{file} został zaktualizowany"
      elsif url = @filemap[file] || file =~ %r[^files/]
        form = @agent.get('https://login.jogger.pl/templates/files/').forms.first
        form.file_uploads.first.file_name = file
        form.submit
        puts "Plik #{file} został zaktualizowany"
      else
        puts "Plik #{file} nie istnieje"
      end
    end
  end

  def confirm(filename)
    if File.exists?(filename) && @args[1] != '--force'
      puts "Plik #{filename} istnieje. Nadpisac? [T/N]"

      loop do
        print "> "
        res = STDIN.gets.chomp.upcase

        if res == "T"
          return true
        elsif res == "N"
          return false
        else
          puts "Nie czaje..."
        end
      end

    end

    return true
  end

  def get_pagesmap
    @pagesmap = Hash[*@agent.get('https://login.jogger.pl/templates/edit/').links.select{|e| e.href =~ %r[/templates/edit/\?page_id] }.map {|e| ["strony/#{e.text}.html", e.href]}.flatten]
    @pagesmap["Szablon_wpisow.html"] ='/templates/edit/?file=entries'
    @pagesmap["Szablon_komentarzy.html"] ='/templates/edit/?file=comments'
    @pagesmap["Szablon_logowania.html"] ='/templates/edit/?file=login'
   end

  def get_filemap
    @filemap = Hash[*@agent.get('https://login.jogger.pl/templates/files/').parser.css("td > a").map {|e| ["files/#{e.text}", e[:href]] }.flatten]
  end

  def login
    load_config_file
    form = @agent.get('https://login.jogger.pl/login/').forms.first
    form.login_jabberid = @config[:jabber_id]
    form.login_jabberpass = @config[:password]
    page = form.submit

    if page.uri.to_s == 'https://login.jogger.pl/login/'
      puts "Identyfikator jabbera lub hasło jest nieporawne"
      exit
    end
  end

  def usage
    puts <<-USAGE
rubber [action]

Actions:
 download (--force)
 upload [file]
 server
USAGE
    exit
  end

end
