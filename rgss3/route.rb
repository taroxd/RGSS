# @taroxd metadata 1.0
# @require taroxd_core
# @require global
# @id route
# @display 多路线系统
# @help
#  一条路线，包括玩家位置，队伍成员，持有物品等。
#  游戏中的变量和开关是所有路线共有的。
#  该脚本可以进行路线的切换。
#  游戏开始时，路线 id 为 0。
#
#  进入空路线时，队伍无成员，不持有任何物品。玩家的位置不变。
#  建议用以下方式来初始化一条路线：
#  淡出画面 - route.id = id - 初始化路线 - 淡入画面
#
#  -- 用法 -- 在事件脚本中输入 --
#    route.id：获取当前路线的 id。
#    route.id = id：
#      切换到第 id 号路线，无淡入淡出效果。
#    set_route(id)：
#      切换到第 id 号路线，有淡入淡出效果。
#    route << id：将第 id 号路线合并入当前路线，并清除第 id 号路线。
#    route.clear(id)：清除第 id 号路线。

# 路线类，保存了路线 id 和数据。该类的实例会存入存档。
class Taroxd::Route

  # 数据
  class Contents

    attr_reader :party, :map_id, :x, :y, :d

    def initialize
      @party = $game_party
      @map_id = $game_map.map_id
      @x = $game_player.x
      @y = $game_player.y
      @d = $game_player.direction
    end

    def restore
      $game_party = @party
      $game_player.reserve_transfer(@map_id, @x, @y, @d)
    end
  end

  def self.current
    Taroxd::Global[:route] ||= new
  end

  attr_reader :id

  def initialize
    @id = 0
    @data = []   # Contents 实例的数组
  end

  def id=(id)
    return if @id == id
    @data[@id] = Contents.new
    @id = id
    contents = @data[id]
    contents ? contents.restore : init_route
    on_change
  end

  # 合并路线
  def <<(id)
    if @id != id && @data[id]
      $game_party.merge_party(@data[id].party)
      clear(id)
      on_change
    end
    self
  end

  def clear(id = nil)
    id ? @data[id] = nil : @data.clear
  end

  def on_change
    $game_player.refresh
    $game_map.need_refresh = true
  end

  private

  # 进入一条新路线时执行的内容
  def init_route
    $game_party = Game_Party.new
  end
end

class Game_Interpreter

  def route
    Taroxd::Route.current
  end

  # 设置路线并淡入淡出
  def set_route(id)
    return if $game_party.in_battle
    command_221           # 淡出画面
    route.id = id
    Fiber.yield while $game_player.transfer?
    command_222           # 淡入画面
  end

end

class Game_Party < Game_Unit

  # 合并金钱、角色、物品
  def merge_party(other)
    gold, actors, items, weapons, armors = other.merge_contents
    gain_gold(gold)
    @actors |= actors
    merge_item @items,   items,   $data_items
    merge_item @weapons, weapons, $data_weapons
    merge_item @armors,  armors,  $data_armors
  end

  protected

  def merge_contents
    [@gold, @actors, @items, @weapons, @armors]
  end

  private

  def merge_item(to, from, database)
    to.merge!(from) do |id, v1, v2|
      [v1 + v2, max_item_number(database[id])].min
    end
  end
end
