module Textbringer
  class DiredMode < Mode
    
    LS_OPTIONS = '-alpH'
    BEFORE_FILENAME_REGEX = /^\S+\s+[^\n]\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+|^total\s\w+$|^\S+:$/
    FILENAME_REGEX = /(?!\s+)(\S+)$/
    SYMLINK_REGEX = /(\S+)(?=\s+\-\>)/
    
    define_generic_command :dired_find_file
    define_generic_command :dired_up_directory
    define_generic_command :dired_next_line
    define_generic_command :dired_previous_line
    define_generic_command :dired_copy_file_name_as_kill
    define_generic_command :dired_revert
    
    define_keymap :DIRED_MODE_MAP
    DIRED_MODE_MAP.define_key("n", :dired_next_line_command)
    DIRED_MODE_MAP.define_key("p", :dired_previous_line_command)
    DIRED_MODE_MAP.define_key("w", :dired_copy_file_name_as_kill_command)
    DIRED_MODE_MAP.define_key("g", :dired_revert_command)
    DIRED_MODE_MAP.define_key("\C-m", :dired_find_file_command)
    DIRED_MODE_MAP.define_key("^", :dired_up_directory_command)

    def initialize(buffer)
      super(buffer)
      buffer.keymap = DIRED_MODE_MAP
    end
    
    def self.open(directory)
      base_name = File.basename(directory)
      buffer = Buffer.new_buffer("Directory: #{base_name}",
                                  new_file: false, file_name: directory)
      
      contents = %x(ls #{LS_OPTIONS} #{directory})
      buffer.insert("#{directory}:\n")
      buffer.insert(contents)

      buffer.read_only = true
      buffer.apply_mode(self)
      buffer.goto_char(buffer.point_min)
      buffer.re_search_forward('\./')
      buffer.backward_char(2)
      buffer.next_line(2)
      buffer
    end

    def file_at_point
      line = @buffer.line_at_point
      file_name = line.split[8..].join(' ')
      if file_name['->'] # symbolic link
        file_name = file_name.split('->')[0].strip
      end
      File.join(@buffer.default_directory, file_name)
    end

    def dired_find_file
      find_file(file_at_point)
    end

    def dired_up_directory
      split = @buffer.default_directory.split(File::SEPARATOR)
      new_path = split[0..-2].join(File::SEPARATOR)
      find_file(new_path)
    end

    def dired_copy_file_name_as_kill
      file_name = File.basename(file_at_point)
      KILL_RING.push(file_name)
      message(file_name)
    end

    def dired_revert
      directory = @buffer.default_directory
      pos = @buffer.point
      line, _ = @buffer.get_line_and_column(pos)
      @buffer.kill
      find_file(directory)
      new_line, _ = Buffer.current.get_line_and_column(Buffer.current.point)
      Buffer.current.next_line(line - new_line)
    end

    def align_with_file_name
      @buffer.beginning_of_line
      @buffer.re_search_forward(BEFORE_FILENAME_REGEX, raise_error: false)
    end

    def dired_next_line
      next_line
      align_with_file_name
    end

    def dired_previous_line
      previous_line
      align_with_file_name
    end
  end
end
