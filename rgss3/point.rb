# @taroxd metadata 1.0
# @display 坐标类
# @id point
# @help 
#
# 该类的作用是表示一个地图上的点的坐标
# 可以伪装成 Game_Character 的对象传给一些接受 character 参数的方法。


module Taroxd
  Point = Struct.new(:x, :y) do

    alias_method :real_x, :x
    alias_method :real_y, :y

    def moveto(x, y)
      self.x = x
      self.y = y
    end

    def pos?(x2, y2)
      x == x2 && y == y2
    end

    def same_pos?(other)
      x == other.x && y == other.y
    end

    def screen_x
      $game_map.adjust_x(x) * 32 + 16
    end

    def screen_y
      $game_map.adjust_y(y) * 32 + 32
    end
  end
end