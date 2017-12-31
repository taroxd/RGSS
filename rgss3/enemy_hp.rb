# @taroxd metadata 1.0
# @id enemy_hp
# @display 敌人显血
# @require taroxd_core
# @require roll_gauge
# @help
#    战斗中敌人显示血条
#    如不想显示，可在敌人处备注 <hide hp>
#    可在敌人处备注 <hp width w>、<hp height h>、<hp dxy dx dy> 调整血槽。
#    其中 w 表示宽度、h 表示高度，dx、dy 表示坐标的偏移。

Taroxd::EnemyHP = true

class RPG::Enemy < RPG::BaseItem

  note_any :hp_dxy, [0, 0], /\s+(-?\d+)\s+(-?\d+)/, '[$1.to_i, $2.to_i]'
  note_i :hp_width, 80
  note_i :hp_height, 6
  note_bool :hide_hp?

  # 初始化并获取战斗图的尺寸
  def init_width_height
    bitmap = Bitmap.new("Graphics/Battlers/#{@battler_name}")
    @width = bitmap.width
    @height = bitmap.height
    bitmap.dispose
  end

  def width
    return @width if @width
    init_width_height
    @width
  end

  def height
    return @height if @height
    init_width_height
    @height
  end
end

class Sprite_EnemyHP < Sprite

  include Taroxd::RollGauge
  include Taroxd::DisposeBitmap

  HP_COLOR1 = Color.new(223, 127, 63)
  HP_COLOR2 = Color.new(239, 191, 63)
  BACK_COLOR = Color.new(31, 31, 63)

  def initialize(viewport, enemy)
    @enemy = enemy
    super(viewport)
    data = enemy.enemy
    @width = data.hp_width
    @height = data.hp_height
    self.bitmap = Bitmap.new(@width, @height)
    dx, dy = enemy.enemy.hp_dxy
    self.ox = @width / 2
    self.oy = @height
    self.x = enemy.screen_x + dx
    self.y = enemy.screen_y + dy
    self.z = enemy.screen_z + 10
    refresh
  end

  def make_gauge_transitions
    Transition.new(gauge_roll_times) do
      @enemy.hp.fdiv(@enemy.mhp)
    end
  end

  def update_gauge_transitions
    gauge_transitions.update
  end

  def refresh
    bitmap.clear
    rate = gauge_transitions.value
    return if rate.zero?
    fill_w = (bitmap.width * rate).to_i
    bitmap.fill_rect(fill_w, 0, @width - fill_w, @height, BACK_COLOR)
    bitmap.gradient_fill_rect(0, 0, fill_w, @height, HP_COLOR1, HP_COLOR2)
  end
end

class Spriteset_Battle

  # 导入精灵组
  def_after :create_enemies do
    @enemy_hp_sprites = $game_troop.members.map { |enemy|
      Sprite_EnemyHP.new(@viewport1, enemy) unless enemy.enemy.hide_hp?
    }.compact
  end

  def_after(:update_enemies)  { @enemy_hp_sprites.each(&:update)  }
  def_after(:dispose_enemies) { @enemy_hp_sprites.each(&:dispose) }
end