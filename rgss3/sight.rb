# @taroxd metadata 1.0
# @id sight
# @display 视野限制
# @require taroxd_core
# @require bitmap_ext
# @help
#
#  使用方法：在地图上备注 <sight x>，则该地图限制视野。x 为无补正时的可见半径
#  在角色、职业、装备、状态上备注 <sight x>，则可以设置角色周围 x 的视野补正
#  在事件名称上备注 <sight x> 则可以在事件周围设置 x 的视野补正
#
#  可以设置 $game_map.sight 属性来调整视野范围。
#  该值默认为地图上备注的数字或 nil（无备注，不限制视野）

module Taroxd::Sight
  DARKNESS = 32    # 视野限制时可见区域的暗度。

  # 阴影的位图。纯白色，越靠近中间透明度越大。
  def self.shadow
    return @shadow if @shadow && !@shadow.disposed?
    @shadow = Bitmap.new(128, 128)
    @shadow.fill_rect(@shadow.rect, Color.new(255, 255, 255, 0))
    @shadow.width.times do |x|
      @shadow.height.times do |y|
        bright = 4096 - (x - 64)**2 - (y - 64)**2
        next if bright <= 0
        @shadow.set_pixel(x, y, Color.new(255, 255, 255, bright / DARKNESS))
      end
    end
    @shadow
  end
end

RPG::Map.note_i :sight, nil
RPG::BaseItem.note_i :sight
RPG::Event.note_i :sight

class Game_Map
  attr_accessor :sight
  def_after(:setup) { |_| @sight = @map.sight }
end

class Game_Actor < Game_Battler
  def sight
    note_objects.sum(&:sight)
  end
end

class Game_CharacterBase
  def sight
    0
  end
end

class Game_Event < Game_Character
  def sight
    @event.sight
  end
end

class Game_Player < Game_Character
  def sight
    return 0 unless $game_map.sight
    $game_party.sum($game_map.sight, &:sight)
  end
end

class Sprite_SightShadow < Sprite_Base

  # sprites: Sprite_Character 实例的数组
  def initialize(viewport, sprites)
    super(viewport)
    @sprites = sprites
    self.z = 160
    self.bitmap = Bitmap.new(Graphics.width, Graphics.height)
  end

  def dispose
    bitmap.dispose
    super
  end

  def update
    self.visible = $game_map.sight
    refresh if visible
  end

  private

  def refresh
    bitmap.fill_rect(bitmap.rect, Color.new(255, 255, 255, 0))
    @sprites.each { |s| draw_shadow(s) }
    bitmap.xor!(0xFFFFFFFF)
  end

  def draw_shadow(sprite)
    r = sprite.character.sight
    x = sprite.x - sprite.ox + sprite.width / 2 - r
    y = sprite.y - sprite.oy + sprite.height / 2 - r
    bitmap.stretch_blt(Rect.new(x, y, r * 2, r * 2), shadow, shadow.rect)
  end

  def shadow
    Taroxd::Sight.shadow
  end
end

class Spriteset_Map

  def create_sight_shadow
    sprites = @character_sprites.select { |s| s.character.sight > 0 }
    @sight_shadow = Sprite_SightShadow.new(@viewport2, sprites)
  end

  def dispose_sight_shadow
    @sight_shadow.dispose
  end

  def update_sight_shadow
    @sight_shadow.update
  end

  def refresh_sight_shadow
    dispose_sight_shadow
    create_sight_shadow
  end

  %w(create dispose update refresh).each do |prefix|
    def_after :"#{prefix}_characters", :"#{prefix}_sight_shadow"
  end
end