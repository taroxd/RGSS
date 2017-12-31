# @taroxd metadata 1.0
# @id map_hp
# @display 地图显血
# @require taroxd_core
# @require roll_gauge
# @help 在地图上显示一个简易的血条。

class Sprite_MapHP < Sprite

  Taroxd::MapHP = self

  include Taroxd::DisposeBitmap
  include Taroxd::RollGauge

  # 颜色
  HP_COLOR1 = Color.new(223, 127, 63)
  HP_COLOR2 = Color.new(239, 191, 63)
  BACK_COLOR = Color.new(31, 31, 63)

  # 大小
  WIDTH = 124
  HEIGHT = 100

  def initialize(_)
    super
    self.z = 170
    self.bitmap = Bitmap.new(WIDTH, HEIGHT)
    roll_all_gauge
  end

  def roll_all_gauge
    bitmap.clear
    $game_party.each_with_index do |actor, i|
      rate = gauge_transitions[actor][:hp].value.fdiv(actor.mhp)
      fill_w = (width * rate).to_i
      gauge_y = i * 16 + 12
      bitmap.fill_rect(fill_w, gauge_y, WIDTH - fill_w, 6, BACK_COLOR)
      bitmap.gradient_fill_rect(0, gauge_y, fill_w, 6, HP_COLOR1, HP_COLOR2)
    end
  end
end

Spriteset_Map.use_sprite(Sprite_MapHP) { @viewport2 }
