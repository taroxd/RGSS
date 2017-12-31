# @taroxd metadata 1.0
# @require taroxd_core
# @display 设置地图通行度
# @id set_passage
# @help
#  使用方法1：见下方“设置区域通行度”。
#
#  使用方法2：** require 显示地图通行度 **
#
#    测试模式下，把 EDIT_MODE 设为 true，
#    然后在地图上按下确定键即可改变当前位置的通行度。
#    该模式下，角色可以自由穿透。
#
#    △表示不改变，○表示可以通行，×表示不可通行。颜色表示最终的通行度。
#
#    需要清空设置的话，删除设置文件（见 FILE 常量）即可。
#
#    需要重置一张地图的设置的话，可以调用如下脚本：
#      Taroxd::Passage.clear(map_id)
#    其中 map_id 为地图 ID。若要清除当前地图的通行度，map_id 可以不填。
#    注意，清除后，通行度的显示并不会立即改变。重新打开游戏即可看到效果。

module Taroxd::Passage

  # 地图通行度信息会保存到这个文件。建议每次编辑前备份该文件。
  FILE = 'Data/MapPassage.rvdata2'

  # 是否打开编辑模式。需要前置脚本“显示地图通行度”才可打开。
  EDIT_MODE = false

  # 编辑方式（可整合鼠标脚本）
  EDIT_TRIGGER = -> { Input.trigger?(:C) }
  EDIT_POINT   = -> { [$game_player.x, $game_player.y] }

  # 常量，不建议改动
  DEFAULT    = 0
  PASSABLE   = 1
  IMPASSABLE = 2
  TEXTS = ['△', '○', '×']

  SIZE = TEXTS.size

  # 设置区域通行度。一个以区域ID为键的哈希表。(未设置的区域，ID为0)
  # 哈希表值的意义如下
  # PASSABLE / true：该区域强制可以通行。
  # IMPASSABLE / false：该区域强制不可通行。
  # [区域ID1, 区域ID2, ...]：该区域只能通行至指定的区域。

  # 设置例：
  # REGIONS = {
  #   1 => PASSABLE,
  #   2 => false,
  #   3 => [3, 4],         # 只有通过4号区域才能出入3号区域
  #   5 => [*0..63] - [6]  # 5号区域与6号区域的边界线不可通行
  # }
  REGIONS = {}

  # 通行度的哈希表。以地图ID为键，以通行度的二维 Table 为值。
  @data = File.exist?(FILE) ? load_data(FILE) : {}

  class << self

    # 获取 x, y 坐标处的 d 方向通行度设定。（DEFAULT/PASSABLE/IMPASSABLE）
    def [](x, y, d)
      data[x, y] == DEFAULT ? region_passable(x, y, d) : data[x, y]
    end

    # 更新，编辑模式下应每帧调用一次
    def update
      return unless EDIT_TRIGGER.call
      x, y = EDIT_POINT.call
      data[x, y] = (data[x, y] + 1) % SIZE
      save
    end

    # 获取当前地图的数据
    def data
      table = @data[map_id] ||= Table.new(width, height)
      if table.xsize < width || table.ysize < height
        update_table(table)
      else
        table
      end
    end

    # 清除一个地图的设置
    def clear(map_id = $game_map.map_id)
      @data.delete(map_id)
      save
    end

    private

    # 区域设置中能否通行（DEFAULT/PASSABLE/IMPASSABLE）
    def region_passable(x, y, d)
      settings = REGIONS[$game_map.region_id(x, y)]
      case settings
      when true, PASSABLE then PASSABLE
      when false, IMPASSABLE then IMPASSABLE
      when Enumerable
        x2 = $game_map.round_x_with_direction(x, d)
        y2 = $game_map.round_y_with_direction(y, d)
        settings.include?($game_map.region_id(x2, y2)) ? DEFAULT : IMPASSABLE
      else DEFAULT
      end
    end

    # 如果表格不够大，那么重新建立表格
    def update_table(table)
      @data[map_id] = new_table = Table.new(width, height)
      table.xsize.times do |x|
        table.ysize.times do |y|
          new_table[x, y] = table[x, y]
        end
      end
      new_table
    end

    # 将所有数据保存到文件
    def save
      save_data(@data, FILE)
    end

    # 获取当前地图信息
    def map_id
      $game_map.map_id
    end

    def width
      $game_map.width
    end

    def height
      $game_map.height
    end
  end
end

class Game_Map
  psg = Taroxd::Passage

  def_chain :passable? do |old, x, y, d|
    case psg[x, y, d]
    when psg::DEFAULT    then old.call(x, y, d)
    when psg::PASSABLE   then true
    when psg::IMPASSABLE then false
    end
  end
end

if $TEST && Taroxd::Passage::EDIT_MODE

  class Game_Player < Game_Character

    # 每帧调用一次 Taroxd::Passage.update
    def_after :update, Taroxd::Passage.method(:update)

    def debug_through?
      true
    end
  end

  class Taroxd::PlanePassage < Plane

    TEXT_RECT = Rect.new(0, 0, 32, 32)
    const_set :VISIBLE, true
    psg = Taroxd::Passage
    include psg

    # 通行度文字的位图缓存
    def text_bitmaps
      @text_bitmap_cache ||= TEXTS.map do |text|
        bitmap = Bitmap.new(TEXT_RECT.width, TEXT_RECT.height)
        bitmap.draw_text(TEXT_RECT, text, 1)
        bitmap
      end
    end

    # 绘制通行度的设置情况
    def_after :draw_point do |x, y|
      bitmap.blt(x * 32, y * 32, text_bitmaps[psg.data[x, y]], TEXT_RECT)
    end

    # 更新通行度的变化
    def_after :update do
      return unless EDIT_TRIGGER.call
      x, y = EDIT_POINT.call
      bitmap.clear_rect(x * 32, y * 32, 32, 32)
      draw_point(x, y)
    end

    def_before :dispose do
      @text_bitmaps_cache.each(&:dispose) if @text_bitmaps
    end
  end
end