# @taroxd metadata 1.0
# @id metadata
# @display 元数据
# @help 读取 taroxd 脚本的元数据

module Taroxd
  module Metadata
    def self.read(source)
      return unless source.include?('@taroxd metadata')
      metadata = {}
      source.scan(/^# @(\w+)(?: +(.+))?/) do |key, value|
        key = key.to_sym
        value ||= ""
        original_value = metadata[key]
        value = original_value ? "#{original_value}\n#{value}" : value
        metadata[key] = value.chomp
      end
      metadata
    end
  end
end