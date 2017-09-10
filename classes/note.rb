class Note
  attr_reader :title, :content, :tags, :filename, :path

  def initialize(path)
    @content = ''
    @tags = []
    @filename = File.basename(path)
    @path = path

    refresh

    @title = 'Untitled' if !@title
  end

  def refresh
    File.open(@path, 'r') do |file|
      file.each_line do |line|
        line = line.strip
        if !@title
          if line != ''
            @title = line.gsub(/#|[^a-z0-9\s\.\-]/i, '').strip
          end
        else
          @content << line
        end
      end
    end
  end

  def excerpt
    @content.gsub(/[#*\-~]/i, '').strip.slice(0, 80)
  end
end