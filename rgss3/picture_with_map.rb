# @taroxd metadata 1.0
# @id picture_with_map
# @display 图片跟随地图移动
# @require taroxd_core
# @help 编号大于 50 的图片会跟随地图移动。

Taroxd::PictureWithMap = true

class Game_Picture
  # 图片是否随地图移动
  def move_with_map?
    @number > 50
  end

  def_with :x do |old|
    move_with_map? ? $game_map.adjust_x(old / 32.0) * 32 : old
  end

  def_with :y do |old|
    move_with_map? ? $game_map.adjust_y(old / 32.0) * 32 : old
  end
end
