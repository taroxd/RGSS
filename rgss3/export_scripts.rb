# @taroxd metadata 1.0
# @display 导出脚本
# @id export_scripts
# @require metadata

module Taroxd
  module ExportScripts
    Success = Class.new(StandardError)
    PATH = 'rgss3'
    EXT = '.rb'
    
    def self.call
      if File.directory?(PATH)
        Dir.glob("#{PATH}/*#{EXT}", &File.method(:delete))
      else
        Dir.mkdir(PATH)
      end

      $RGSS_SCRIPTS.each do |(_, tag, _, contents)|
        next unless contents.force_encoding('utf-8')[/\S/]
        metadata = Taroxd::Metadata.read(contents)
        next unless metadata
        filename = metadata[:id]
        if filename
          File.open("#{PATH}/#{filename}#{EXT}", 'wb', encoding: 'utf-8') do |f|
            f.write contents.delete("\r")
          end
        end
      end
      # raise in order to navigate to this page
      raise Success, 'Scripts are exported successfully.' 
    end

    call if $TEST && !$BTEST
  end
end
