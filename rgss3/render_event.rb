# @taroxd metadata 1.0
# @require taroxd_core
# @id render_event
# @display 重复设置事件
# @help
#   在事件名称上备注 <render event_id>
#     那么这个事件会完全被该地图中的事件 event_id 代替。
#   在事件名称上备注 <render event_id map_id>
#     那么这个事件会完全被地图 map_id 中的事件 event_id 代替。

module Taroxd::RenderEvent

  # 获取地图（RPG::Map）。map_id 为 0 时获取当前地图。
  def self.load_map(map_id)
    case map_id
    when 0, $game_map.map_id
      $game_map.data_object
    when @last_map_id
      @last_map
    else
      @last_map_id = map_id
      @last_map = load_data sprintf("Data/Map%03d.rvdata2", map_id)
    end
  end
end

class RPG::Event

  # 重定义：获取事件页
  def pages
    @rendered_pages ||= rendered_pages
  end

  private

  def rendered_pages
    return @pages unless @name =~ /<render\s+(\d+)(\s+\d+)?>/i
    Taroxd::RenderEvent.load_map($2.to_i).events[$1.to_i].pages
  end

end
