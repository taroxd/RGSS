# @taroxd metadata 1.0
# @id event_astar
# @require taroxd_core
# @require astar
# @display 事件寻路

Taroxd::EventAStar = true

class Game_Character < Game_CharacterBase
  def find_path_toward(x, y)
    return @find_path if @find_path_xy == [x, y, @x, @y]
    @find_path = Taroxd::AStar.path(self, x, y)
    @find_path_xy = x, y, @x, @y
    @find_path
  end

  # 保留原方法，以备需要的时候使用。
  alias_method :move_toward_character_directly, :move_toward_character

  def move_toward_character(character)
    dir = find_path_toward(character.x, character.y).shift
    return move_toward_character_directly(character) unless dir
    move_straight(dir)
    @find_path_xy[2, 2] = @x, @y if @move_succeed
  end

  # 使用此方法 require 坐标类
  def move_toward_point(x, y)
    move_toward_character Taroxd::Point[x, y]
  end
end

class Game_Event < Game_Character
  alias_method :move_type_toward_player, :move_toward_player
end