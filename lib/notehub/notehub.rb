#!/usr/bin/ruby

class Hash
  def to_query
    prefix = "?"
    query_string = ""
    self.each {|p, v|
      query_string += "#{prefix}#{p}=#{CGI.escape(v)}"
      prefix = "&"
    }
    query_string
  end
end

class String
  def hr(length=0)
    length = `tput cols`.strip.to_i if length == 0
    out = ""
    length.times do
      out += self
    end
    out
  end
end


class NotehubAPI
  API_VERSION = "1.4"
  attr_reader :notes, :default_password, :default_theme, :default_font, :default_header_font

  def initialize(opts={})

    opts['config_location'] ||= "#{ENV['HOME']}/.notehub"
    opts['config_file'] ||= "#{opts['config_location']}/config.yml"
    opts['notes_db'] ||= "#{opts['config_location']}/notes.db"

    config_file = opts['config_file']
    @notes_db = opts['notes_db']

    # Set up config
    FileUtils.mkdir_p(opts['config_location'],:mode => 0755) unless File.directory? opts['config_location']
    unless File.exists?(config_file)
      new_config = {
        'publisher_id' => "your_publisher_id",
        'secret_key' => "your_secret_key",
        'default_password' => "default password for editing notes",
        'default_theme' => "light",
        'default_font' => 'Georgia'
      }.to_yaml

      File.open(config_file, 'w') { |yf| YAML::dump(new_config, yf) }
    end

    config = YAML.load_file(config_file)
    @pid = config['publisher_id']
    @psk = config['secret_key']
    if config['default_password'] && config['default_password'].length > 0
      @default_password = config['default_password']
    else
      @default_password = false
    end
    @default_theme = config['default_theme'] || 'light'
    @default_font = config['default_font'] || 'Georgia'
    @default_header_font = config['default_header_font'] || 'Georgia'

    # verify config
    if @pid == "your_publisher_id" || @psk == "your_secret_key"
      puts "Please edit #{config_file} and run again"
      Process.exit 1
    end

    # set up notes database
    unless File.exists?(@notes_db)
      new_db = {'notes' => {}}
      File.open(@notes_db, 'w') { |yf| YAML::dump(new_db, yf) }
    end

    # load existing notes
    @notes = YAML.load_file(@notes_db)
  end

  def store_note(note)
    @notes['notes'][note['id']] = note
    File.open(@notes_db, 'w') { |yf| YAML::dump(@notes, yf) }
  end

  def post_api(params, action="post")
    uri = URI("http://www.notehub.org/api/note")

    if action == "put"
      req = Net::HTTP::Put.new(uri)
    else
      req = Net::HTTP::Post.new(uri)
    end
    req.set_form_data(params)

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      json = JSON.parse(res.body)
      if json['status']['success']
        return json
      else
        raise "POST request returned error: #{json['status']['message']}"
      end
    else
      # res.value
      p res.body if res
      raise "Error retrieving POST request to API"
    end
    # res = Net::HTTP.post_form(uri, params)
  end

  def get_api(params)
    params['version'] = API_VERSION

    uri = URI("http://www.notehub.org/api/note#{params.to_query}")

    Net::HTTP.start(uri.host, uri.port) do |http|
      req = Net::HTTP::Get.new uri
      res = http.request req
      if res && res.code == "200"
        json = JSON.parse(res.body)
        if json['status']['success']
          return json
        else
          raise "GET request returned error: #{json['status']['message']}"
        end
      else
        p res.body if res
        raise "Error retrieving GET request to API"
      end
    end
  end

  def new_note(text, pass=false, options={})
    options[:theme] ||= nil
    options[:font] ||= nil

    params = {}
    params['note'] = text.strip
    params['pid'] = @pid
    params['signature'] = Digest::MD5.hexdigest(@pid + @psk + text.strip)
    params['password'] = Digest::MD5.hexdigest(pass) if pass
    params['version'] = API_VERSION

    params['theme'] = options[:theme] unless options[:theme].nil?
    params['text-font'] = options[:font] unless options[:font].nil?
    params['header-font'] = options[:header_font] unless options[:header_font].nil?

    res = post_api(params)

    if res && res['status']['success']
      note_data = read_note(res['noteID'])
      note = {
        'title' => note_data['title'][0..80],
        'id' => res['noteID'],
        'url' => res['longURL'],
        'short' => res['shortURL'],
        'stats' => note_data['statistics'],
        'pass' => pass || ""
      }
      store_note(note)
      return note
    else
      if res
        raise "Failed: #{res['status']['comment']} "
      else
        raise "Failed to create note"
      end
    end
  end

  def update_note(id, text, pass=false)
    # TODO: Signature invalid
    params = {}
    pass ||= @default_password
    # raise "Password required for update" unless pass

    md5_pass = Digest::MD5.hexdigest(pass)

    params['password'] =  md5_pass
    params['noteID'] = id
    params['note'] = text.strip
    params['pid'] = @pid
    sig = @pid + @psk + id + text.strip + md5_pass
    params['signature'] = Digest::MD5.hexdigest(sig)
    params['version'] = API_VERSION
    res = post_api(params,"put")

    if res && res['status']['success']
      note_data = read_note(id)
      note = {
        'title' => note_data['title'][0..80].strip,
        'id' => id,
        'url' => res['longURL'],
        'short' => res['shortURL'],
        'stats' => note_data['statistics'],
        'pass' => pass || ""
      }
      store_note(note)
      return note
    else
      if res
        raise "Failed: #{res['status']['comment']} "
      else
        raise "Failed to update note"
      end
    end
  end

  def read_note(id)
    params = {'noteID' => id}
    get_api(params)
  end

  def list_notes(term=".*")
    notes = find_notes(term)
    notes.each {|note|
      puts "> #{note['title']} [ #{note['id']} ]"
    }
  end

  def find_notes(term=".*")
    term.gsub!(/\s+/,".*?")
    found_notes = []
    @notes['notes'].each {|k, v|
      v['id'] = k
      found_notes.push(v) if v['title'] =~ /#{term}/i
    }
    found_notes
  end

  def choose_note(term=".*")
    # TODO: If there's input on STDIN, gets fails. Use highline?
    puts "Choose a note:"

    list = find_notes(term)
    list.each_with_index { |note, i| puts "% 3d: %s" % [i+1, note['title']] }
    # list.each_with_index { |f,i| puts "% 3d: %s" % [i+1, f] }
    num = ask("Which note?  ", Integer) { |q| q.in = 1..list.length }

    return false if num =~ /^[a-z ]*$/i

    list[num.to_i - 1]
  end
end

# nh = NotehubAPI.new
# nh.chooose_note
