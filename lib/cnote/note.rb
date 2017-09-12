require "time"

class Note
  attr_reader :title,
              :content,
              :tags,
              :filename,
              :path,
              :modified,
              :created

  attr_writer :created

  def initialize(path)
    @meta_regex = /^<!\-{3}(.*)\-{2}>/

    @content = ""
    @tags = []
    @filename = File.basename(path)
    @path = path

    File.open(@path, "r") do |file|
      refresh(file.read)
    end

    @modified = File.mtime(@path) if !@modified
    @created = @modified if !@created

    @title = "Untitled" if !@title
  end

  def refresh(contents)
    @title = nil
    @content = ''

    contents.each_line do |line|
      line = line.strip
      if @meta_regex =~ line
        parse_meta($~[1])
      elsif !@title
        if line != ""
          @title = line.gsub(/#|[^a-z0-9\s\.\-]/i, "").strip
        end
      else
        @content << line + "\n"
      end
    end
  end

  def add_tags(tags)
    @tags = @tags.concat(tags)
    @modified = Time.new
    write_meta
  end

  def remove_tags(tags)
    @tags = @tags - tags
    @modified = Time.new
    write_meta
  end

  def excerpt
    @content.gsub(/[#*\-~]/i, "").strip.slice(0, 80)
  end

  def time_fmt(time)
    time.strftime("%A, %B %e %Y, %l:%M:%S%p")
  end

  def update
    @modified = Time.new
    write_meta
  end

  private def parse_meta(meta)
    key, value = meta.split(":", 2).map { |v| v.strip }

    case key.downcase
    when "tags"
      @tags = value.split(",").map { |v| v.strip }
    when "created"
      @created = Time.parse(value)
    when "modified"
      @modified = Time.parse(value)
    end
  end

  private def write_meta
    meta_regex = /<!\-{3}.+:(.*)\-{2}>/
  
    File.open(@path, "r") do |file|
      contents = file.read

      contents.gsub!(meta_regex, "")
      
      trailing_empty = 0
      contents.lines.reverse.each do |line|
        if line.strip == ""
          trailing_empty += 1
        else
          break
        end
      end

      # Leave two empty lines before metadata.
      contents = contents.lines.slice(0, contents.lines.length - trailing_empty).join("")

      contents += "\n"
      contents += "<!--- created: #{@created} -->\n"
      contents += "<!--- modified: #{@modified} -->\n"
      contents += "<!--- tags: #{@tags.join(", ")} -->\n"

      File.open(@path, "w") do |file|
        file.write(contents)
      end

      refresh(contents)
    end
  end
end