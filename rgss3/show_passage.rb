# @taroxd metadata 1.0
# @id show_passage
# @display 显示地图通行度
# @require taroxd_core
# @require rgss_bugfix
# @help 游戏测试中按下F6即可启用，再按一次关闭

class Taroxd::PlanePassage < Plane

  ENABLE = $TEST                       # 是否启用功能
  KEY = :F6                            # 控制显示通行度的按键
  VISIBLE = false                      # 起始时是否可见
  OPACITY = 150                        # 不透明度
  NG = Color.new(255, 0, 0, OPACITY)   # 不可通行的颜色
  OK = Color.new(0, 0, 255, OPACITY)   # 可以通行的颜色
  NG_WIDTH = 4                         # 不可通行方向显示的宽度

  include Taroxd::DisposeBitmap
  include Taroxd::BugFix::PlaneVisible

  def initialize(_)
    super
    self.visible = VISIBLE
    self.z = 200
    refresh
    update
  end

  def update
    self.visible ^= true if Input.trigger?(KEY)
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

  # 绘制地图上的点 (x, y)
  def draw_point(x, y)
    ng_dirs = [2, 4, 6, 8].reject { |d| $game_map.passable?(x, y, d) }
    if ng_dirs.size == 4
      bitmap.fill_rect(x * 32, y * 32, 32, 32, NG)
      return
    end
    bitmap.fill_rect(x * 32, y * 32, 32, 32, OK)
    ng_dirs.each do |d|
      dx = d == 6 ? 32 - NG_WIDTH : 0
      dy = d == 2 ? 32 - NG_WIDTH : 0
      if d == 2 || d == 8
        width  = 32
        height = NG_WIDTH
      else
        width  = NG_WIDTH
        height = 32
      end
      bitmap.fill_rect(x * 32 + dx, y * 32 + dy, width, height, NG)
    end
  end
end

class Spriteset_Map
  def_before :create_parallax do
    @passage_plane = Taroxd::PlanePassage.new(@viewport3)
  end
  def_before(:update_parallax)    { @passage_plane.update  }
  def_before(:refresh_characters) { @passage_plane.refresh }
  def_before(:dispose_parallax)   { @passage_plane.dispose }
end if Taroxd::PlanePassage::ENABLE