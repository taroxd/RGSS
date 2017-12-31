# @taroxd metadata 1.0
# @id astar
# @display Astar 寻路
# @help AStar Core v1.01 by 禾西 on 2012.01.02

module Taroxd end

class Taroxd::AStar

  def self.path(character, tx, ty)
    new(character, tx, ty).do_search
  end

  def self.path_to_player(character)
    path(character, $game_player.x, $game_player.y)
  end

  def initialize(character, tx, ty)
    @map_width  = $game_map.width
    @map_height = $game_map.height
    @g_data = Table.new(@map_width, @map_height)
    @f_data = Table.new(@map_width, @map_height)
    @p_data = Table.new(@map_width, @map_height)
    @character = character
    @ox = character.x
    @oy = character.y
    @tx = tx
    @ty = ty
    @open_list = []
    @g = 0
    @search_done = false
  end

  def do_search
    x = @ox
    y = @oy
    @g_data[x, y] = 2
    @f_data[x, y] = 1
    @open_list << [x, y]
    t = 0
    begin
      t += 1
      point = @open_list.shift
      return [] if point.nil?
      check_4dir(point[0], point[1])
    end until @search_done
    if @g_data[@tx, @ty] == 1
      @tx = point[0]
      @ty = point[1]
    end
    make_path
    @path
  end

  private

  # 检查四方向
  def check_4dir(x, y)
    @g = @g_data[x, y] + 1
    mark_point(x, y - 1, 8)
    mark_point(x, y + 1, 2)
    mark_point(x - 1, y, 4)
    mark_point(x + 1, y, 6)
  end

  # 检查单点
  def mark_point(x, y, dir)
    return if over_map?(x, y)
    return if @g_data[x, y] > 1
    if check_passage(x, y, dir)
      @g_data[x, y] = @g
      @f_data[x, y] = f = _f(x, y)
      point = @open_list[0]
      if point.nil? || f > @f_data[point[0], point[1]]
        @open_list.push [x, y]
      else
        @open_list.unshift [x, y]
      end
    else
      @g_data[x, y] = 1
      @f_data[x, y] = _f(x, y)
    end
    @search_done = true if x == @tx && y == @ty
  end

  def make_path
    x = @tx
    y = @ty
    @path = []
    while x != @ox || y != @oy
      @g = @g_data[x, y]
      @best_f = 0
      dir = 0
      dir = make_step(x, y - 1, 2) || dir
      dir = make_step(x, y + 1, 8) || dir
      dir = make_step(x - 1, y, 6) || dir
      dir = make_step(x + 1, y, 4) || dir
      @path.unshift(dir)
      case dir
      when 2 then y -= 1
      when 8 then y += 1
      when 6 then x -= 1
      when 4 then x += 1
      end
      @p_data[x, y] = 1
    end
  end

  # 生成单步
  def make_step(x, y, dir)
    return if @g_data[x, y].nil? || @p_data[x, y] == 1
    if @g - @g_data[x, y] == 1 || @g == 1
      f = @f_data[x, y]
      if f > 0 && (@best_f == 0 || f < @best_f)
        @best_f = f
        dir
      end
    end
  end
  # 检查地图通行度
  def check_passage(x, y, dir)
    case dir
    when 2 then y -= 1
    when 8 then y += 1
    when 4 then x += 1
    when 6 then x -= 1
    end
    @character.passable?(x, y, dir)
  end

  # 检查地图是否越界
  def over_map?(x, y)
    x | y | (@map_width - x - 1) | (@map_height - y - 1) < 0
  end

  # f 值算法
  def _f(x, y)
    (x - @tx).abs + (y - @ty).abs + @g
  end
end
