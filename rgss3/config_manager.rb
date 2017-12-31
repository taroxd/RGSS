# @taroxd metadata 1.0
# @display 全局配置管理器
# @id config_manager

module Taroxd
  module ConfigManager
    SAVEFILE_NAME = 'config.rvdata2'

    if File.exist?(SAVEFILE_NAME)
      @data = load_data(SAVEFILE_NAME)
    else
      @data = {}
    end

    def self.[](key)
      @data[key]
    end

    def self.[]=(key, value)
      @data[key] = value
      on_change
    end

    def self.on_change
      save_data @data, SAVEFILE_NAME
    end

    # This method can be used for consecutive value changes,
    # so that the file is written only once.
    # The methods defined in Hash can be used for data manipulation.
    def self.data
      if block_given?
        begin
          yield @data
        ensure
          on_change
        end
      else
        @data
      end
    end
  end
end
