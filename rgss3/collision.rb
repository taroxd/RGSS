# @taroxd metadata 1.0
# @require taroxd_core
# @display  用图片设置地图通行度
# @id collision
# @help
#    使用方法：地图备注 <collision filename>
#             会用 Parallaxes 文件夹下面的对应图片作为该地图的通行度。
#             图片上透明的点表示可以通行，不透明的点表示不能通行。
#             不处理地图循环的情况。

module Taroxd::Collision
  ENABLE_FLOAT_POSITION = false   # 是否允许坐标出现小数。可能会导致未知错误。

  # 人物判定点到图块左上角的距离
  X_OFFSET = 16
  Y_OFFSET = 16

  # position:
  #   行走到的最远位置的坐标（可为 x 坐标或 y 坐标）
  # status:
  #   nil: 完全无法行走
  #   false: 可以行走，但无法走过一格。此时 position 为浮点数
  #   true: 可以完全走过一格，此时 position 为整数
  PassageStatus = Struct.new :position, :status

  def self.passage_status(x, y, d)
    pos = nil
    bx = (x * 32 + X_OFFSET).round
    by = (y * 32 + Y_OFFSET).round

    is_x = d == 4 || d == 6
    current = is_x ? x : y

    if d == 2 || d == 6
      step = 1
      target = (current + 1).floor
    else
      step = -1
      target = (current - 1).ceil
    end

    lbound = (current * 32).round + step
    ubound = target * 32
    bitmap = $game_map.collision_bitmap
    lbound.step(ubound, step) do |i|
      if is_x
        bx = i + X_OFFSET
      else
        by = i + Y_OFFSET
      end

      if bitmap.get_pixel(bx, by).alpha == 0
        pos = i
      else
        break
      end
    end

    if pos
      if pos == ubound
        PassageStatus[pos / 32, true]
      else
        PassageStatus[pos / 32.0, false]
      end
    else
      PassageStatus[nil, nil]
    end
  end
end

RPG::Map.note_s :collision

class Game_Map
  def collision?
    @map.collision
  end

  def collision_bitmap
    @map.collision && Cache.parallax(@map.collision)
  end

  # preload bitmap in cache
  def_after :setup do |_|
    collision_bitmap
  end

  def_and :passable? do |x, y, d|
    Taroxd::Collision.passage_status(x, y, d).status
  end unless Taroxd::Collision::ENABLE_FLOAT_POSITION
end

class Game_CharacterBase
  def_chain :move_straight do |old, d, turn_ok = true|
    if $game_map.collision? && !(@through || debug_through?)
      @move_succeed = passable?(@x.round, @y.round, d)

      if @move_succeed
        pos = Taroxd::Collision.passage_status(@x, @y, d).position
        if pos
          set_direction(d)
          d == 4 || d == 6 ? @x = pos : @y = pos
          increase_steps
        else
          @move_succeed = false
        end
      end

      if !@move_succeed && turn_ok
        set_direction(d)
        check_event_trigger_touch_front
      end
    else
      old.call(d, turn_ok)
    end
  end

end if Taroxd::Collision::ENABLE_FLOAT_POSITION
