# @taroxd metadata 1.0
# @display 选择地图上的点
# @require taroxd_core
# @require point
# @require rgss_bugfix
# @id map_select
# @help
#    事件脚本 select_point(x, y)
#    开始选择，并将光标指定在 x, y 处。注意 x, y 不可以在地图之外。
#    若不指定参数，默认 x, y 为玩家所在的位置。
#    一直等待，直到玩家选择或取消。
#    返回 Taroxd::Point 的实例或 nil（取消）
#
#    可以选择的区域默认为可以通行的区域。该设置可在下方修改。

module Taroxd::MapSelect

  # 颜色设置
  OPACITY = 150
  NG_COLOR = Color.new(255, 0, 0, OPACITY)
  OK_COLOR = Color.new(0, 0, 255, OPACITY)

  class << self

    attr_reader :point
    attr_reader :selecting

    def x
      @point.x
    end

    def y
      @point.y
    end

    # 是否允许选择点 (x, y)（该方法可以自定义）
    def can_select?(x, y)
      $game_player.passable?(x, y, 10 - $game_player.direction)
    end

    def start(x, y)
      @point = Taroxd::Point[x, y]
      @selecting = true
    end

    def select
      if can_select?(*@point)
        Sound.play_ok
        @selecting = false
      else
        Sound.play_buzzer
      end
    end

    def cancel
      @point = nil
      @selecting = false
    end

    def update
      move_right if Input.repeat?(:RIGHT)
      move_left  if Input.repeat?(:LEFT)
      move_down  if Input.repeat?(:DOWN)
      move_up    if Input.repeat?(:UP)
      select     if Input.trigger?(:C)
      cancel     if Input.trigger?(:B)
    end

    def move_right
      return if screen_x > Graphics.width - 48
      @point.x += 1
      Sound.play_cursor
    end

    def move_left
      return if screen_x < 16
      @point.x -= 1
      Sound.play_cursor
    end

    def move_up
      return if screen_y < 16
      @point.y -= 1
      Sound.play_cursor
    end

    def move_down
      return if screen_y > Graphics.height - 48
      @point.y += 1
      Sound.play_cursor
    end

    def screen_x
      @point.screen_x - 16
    end

    def screen_y
      @point.screen_y - 32
    end
  end

  class Cursor < Sprite
    include Taroxd::DisposeBitmap

    # 光标的位图缓存。该方法可以自定义。
    def self.bitmap
      return @bitmap if @bitmap && !@bitmap.disposed?
      @bitmap = Bitmap.new(32, 32)
      skin = Cache.system('Window')
      @bitmap.stretch_blt(@bitmap.rect, skin, Rect.new(64, 0, 64, 64))
      @bitmap
    end

    def initialize(_)
      super
      self.bitmap = self.class.bitmap
      self.z = 205
    end

    def update
      self.visible = Taroxd::MapSelect.selecting
      return unless visible
      self.x = Taroxd::MapSelect.screen_x
      self.y = Taroxd::MapSelect.screen_y
    end
  end

  class Status < Plane
    include Taroxd::DisposeBitmap
    include Taroxd::BugFix::PlaneVisible

    def initialize(_)
      super
      self.z = 200
    end

    def update
      was_visible = visible
      self.visible = Taroxd::MapSelect.selecting
      return unless visible
      refresh unless was_visible
      self.ox = $game_map.display_x * 32
      self.oy = $game_map.display_y * 32
    end

    def refresh
      bitmap.dispose if bitmap
      self.bitmap = Bitmap.new($game_map.width * 32, $game_map.height * 32)
      $game_map.width.times do |x|
        $game_map.height.times do |y|
          draw_point(x, y)
        end
      end
    end

    def draw_point(x, y)
      color = Taroxd::MapSelect.can_select?(x, y) ? OK_COLOR : NG_COLOR
      bitmap.fill_rect(x * 32, y * 32, 32, 32, color)
    end
  end

  # F12 guard
  DataManager.singleton_def_before(:init, method(:cancel))
end

class Game_Interpreter

  MapSelect = Taroxd::MapSelect

  def select_point(x = $game_player.x, y = $game_player.y)
    MapSelect.start(x, y)
    while MapSelect.selecting
      MapSelect.update
      Fiber.yield
    end
    MapSelect.point
  end
end

class Spriteset_Map
  use_sprite(Taroxd::MapSelect::Cursor) { @viewport2 }
  use_sprite(Taroxd::MapSelect::Status) { @viewport2 }
end
