# @taroxd metadata 1.0
# @display 事件脚本扩展
# @require taroxd_core
# @id event_helper
# @help 偷懒用的事件脚本。
#
#    添加了以下方法：
#
#    Game_Interpreter
#      this_event: 获取本事件。如果事件不在当前地图上，返回 nil。
#      add_battlelog(text): 追加战斗信息。
#      shake_for(power = 5, speed = 5) { block }:
#        震动画面直到 block 执行完毕。没有 block 时，画面会无限震动下去。
#        不要在 block 中 return。
#        如果一定需要的话，记得加上 stop_shake 来停止震动。
#      stop_shake: 停止画面震动。
#      self_switch
#      self_switch(event_id)
#      self_switch(event_id, map_id):
#        返回对应事件的 SelfSwitch 对象。
#      fade_for(duration = 30) { block }:
#        淡出画面，执行 block 后淡入画面。
#
#    SelfSwitch
#      由 Game_Interpreter#self_switch 获取。
#      方法：
#      self[letter]：获取对应独立开关的值。letter: 'A'、'B'、'C'、'D' 之一。
#      self[letter] = value：设置对应独立开关的值。
#      属性 a, b, c, d：分别代表对应的独立开关。
#
#    Game_Switches/Game_Variables/Game_SelfSwitches
#       clear / reset: 清空数据
#
#    Game_CharacterBase
#       zoom_x, zoom_y, angle, mirror, opacity, ox, oy 属性: 控制对应 Sprite 的属性。
#       zoom=: 同时设置 zoom_x 与 zoom_y。
#       force_pattern(pattern):
#         将行走图强制更改为对应的 pattern。
#         pattern 从左到右分别为 0, 1, 2。
#         使用此功能时，建议勾选固定朝向，并且取消步行动画。
#       force_bush_depth(depth = nil):
#         将人物的 bush_depth 属性固定为 depth，不受地形的影响。
#         depth 为 nil 时取消固定
#       lineto(x, y)
#         沿直线移动到 (x, y)。可用 moving? 判断是否正在移动中。
#
#    Game_Character
#       jump_to / jumpto(x, y): 跳跃至 x, y
#
#    Game_Player
#       waiting 属性：设为真值时，禁止玩家移动
#       disable_scroll 属性：设为真值时，禁止地图卷动
#
#    Game_Party
#       +(gold), -(gold): 增加/减少金钱，并返回 self。
#       <<(actor), <<(actor_id): 加入指定队员，并返回 self。

module Taroxd::EventHelper

  # 定义了清除数据的方法
  module ClearData

    Game_Switches.send     :include, self
    Game_Variables.send    :include, self
    Game_SelfSwitches.send :include, self

    def clear
      @data.clear
      on_change
      self
    end

    alias_method :reset, :clear
  end

  # 代表独立开关的对象
  SelfSwitch = Struct.new(:map_id, :event_id) do
    def [](letter)
      $game_self_switches[[map_id, event_id, letter]]
    end

    def []=(letter, value)
      $game_self_switches[[map_id, event_id, letter]] = value
    end

    def a; self['A']; end
    def b; self['B']; end
    def c; self['C']; end
    def d; self['D']; end

    def a=(v); self['A'] = v; end
    def b=(v); self['B'] = v; end
    def c=(v); self['C'] = v; end
    def d=(v); self['D'] = v; end
  end
end


class Game_Interpreter

  include Taroxd::EventHelper

  def this_event
    $game_map.events[@event_id] if same_map?
  end

  def add_battlelog(text)
    if SceneManager.scene_is?(Scene_Battle)
      SceneManager.scene.add_battlelog(text)
    end
  end

  def self_switch(event_id = @event_id, map_id = @map_id)
    SelfSwitch.new(map_id, event_id)
  end

  def stop_shake
    screen.start_shake(0, 0, 0)
  end

  # 为了在事件解释器的 fiber 中使用，因此没有 ensure。
  def shake_for(power = 5, speed = 5)
    screen.start_shake(power, speed, Float::INFINITY)
    return unless block_given?
    yield
    stop_shake
  end

  def fade_for(duration = 30)
    Fiber.yield while $game_message.visible
    screen.start_fadeout(duration)
    wait(duration)
    yield if block_given?
    Fiber.yield while $game_message.visible
    screen.start_fadein(duration)
    wait(duration)
  end
end

class Game_CharacterBase

  attr_accessor :zoom_x, :zoom_y, :angle, :mirror, :opacity, :ox, :oy

  def zoom=(zoom)
    @zoom_x = @zoom_y = zoom
  end

  def force_pattern(pattern)
    @original_pattern = @pattern = pattern
  end

  def force_bush_depth(depth = nil)
    @force_bush_depth = depth
    @bush_depth = depth if depth
  end

  def lineto(tx, ty)
    theta = Math.atan2(ty - y, tx - x)
    d = distance_per_frame
    @x = tx
    @y = ty
    # distance per frame
    @lineto_dpf = Taroxd::Point.new(d * Math.cos(theta), d * Math.sin(theta))
    straighten
  end

  def update_lineto
    @real_x = [@real_x - @lineto_dpf.x, @x].max if @x < @real_x
    @real_x = [@real_x + @lineto_dpf.x, @x].min if @x > @real_x
    @real_y = [@real_y - @lineto_dpf.y, @y].max if @y < @real_y
    @real_y = [@real_y + @lineto_dpf.y, @y].min if @y > @real_y
    if !moving?
      @lineto_dpf = nil
      update_bush_depth
    end
  end

  def_unless(:update_bush_depth) { @force_bush_depth }
  def_after(:update_move) { update_lineto if @lineto_dpf }
end

class Game_Character
  def jumpto(tx, ty)
    jump(tx - x, ty - y)
  end

  alias_method :jump_to, :jumpto
end


class Game_Player < Game_Character

  attr_accessor :waiting, :disable_scroll

  def_unless :movable?, :waiting
  def_unless(:update_scroll) { |_, _| @disable_scroll }
end

class Game_Party < Game_Unit

  def +(gold)
    gain_gold(gold)
    self
  end

  def -(gold)
    lose_gold(gold)
    self
  end

  def <<(actor)
    add_actor(actor.id)
    self
  end
end

class Sprite_Character < Sprite_Base

  # 更新对应属性
  def_after :update_other do
    self.ox     = @character.ox     if @character.ox
    self.oy     = @character.oy     if @character.oy
    self.zoom_x = @character.zoom_x if @character.zoom_x
    self.zoom_y = @character.zoom_y if @character.zoom_y
    self.angle  = @character.angle  if @character.angle
    self.mirror = @character.mirror unless @character.mirror.nil?
  end
end

class Scene_Battle < Scene_Base

  def add_battlelog(text)
    @log_window.add_text(text)
  end
end
