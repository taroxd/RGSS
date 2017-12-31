# @taroxd metadata 1.0
# @display 删除部分 rescue
# @help 测试模式下，删除默认脚本中的部分 rescue
# @id remove_rescue

module Taroxd
  RemoveRescue = $TEST
end

if Taroxd::RemoveRescue
  class RPG::UsableItem::Damage
    def eval(a, b, v)
      [Kernel.eval(@formula), 0].max * sign
    end
  end

  class << DataManager

    def savedata_exist(index)
      filename = make_filename(index)
      return unless File.exist?(filename)
      block_given? ? yield(filename) : filename
    end

    alias_method :save_game, :save_game_without_rescue

    def load_game(index)
      load_game_without_rescue(index) if savedata_exist(index)
    end

    def load_header(index)
      load_header_without_rescue(index) if savedata_exist(index)
    end

    def delete_save_file(index)
      savedata_exist(index) { |f| File.delete(f) }
    end

    def savefile_time_stamp(index)
      savedata_exist(index) { |f| File.mtime(f) } || Time.at(0)
    end
  end
end