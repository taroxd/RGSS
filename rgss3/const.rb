# @taroxd metadata 1.0
# @display 游戏常数设置
# @require taroxd_core
# @id const

module Taroxd::Const

  # 游戏常数设置区域（如果要用默认值，可以设置为 false 或直接删除）

  SAVEFILE_MAX = 16               # 存档文件的最大个数
  ESCAPE_RATIO_UP = 0.1           # 撤退失败后，撤退成功率提升值
  MAX_TP = 100                    # TP 的最大值
  ATTACK_SKILL_ID = 1             # 默认攻击技能 ID
  GUARD_SKILL_ID = 2              # 默认防御技能 ID
  DEATH_STATE_ID = 1              # 默认死亡状态 ID
  PARAM_LIMIT = 999999            # 能力值的最大值
  PRESERVE_TP = false             # 是否永远特技专注
  LUK_EFFECT_RATE = 0.001         # 幸运值影响程度
  CRITICAL_RATE = 3               # 关键一击伤害倍率
  STEPS_FOR_RUN = 20              # 地图上多少步等于一回合
  BASIC_FLOOR_DAMAGE = 10         # 地形伤害的基础值
  MAX_BATTLE_MEMBERS = 4          # 参战角色的最大数
  MAX_GOLD = 99999999             # 持有金钱的最大值
  MAX_ITEM_NUMBER = 99            # 物品的最大持有数
  BUSH_DEPTH = 8                  # 流体地形的深度
  BUSH_OPACITY = 128              # 流体地形的不透明度
  PLAYER_INITIAL_DIRECTION = 2    # 角色初始朝向
  SUBSTITUTE_HP_RATE = 0.25       # HP 比率达到多少以下会触发保护弱者
  Font.default_name = 'nsimsun'   # 默认字体名称
  Font.default_size = 24          # 默认字体大小

  def self.[](sym)
    const_defined?(sym, false) && const_get(sym)
  end
end

def DataManager.savefile_max
  Taroxd::Const::SAVEFILE_MAX
end if Taroxd::Const[:SAVEFILE_MAX]

def BattleManager.process_escape
  $game_message.add(sprintf(Vocab::EscapeStart, $game_party.name))
  success = @preemptive ? true : (rand < @escape_ratio)
  Sound.play_escape
  if success
    process_abort
  else
    @escape_ratio += Taroxd::Const::ESCAPE_RATIO_UP
    $game_message.add('\.' + Vocab::EscapeFailure)
    $game_party.clear_actions
  end
  wait_for_message
  success
end if Taroxd::Const[:ESCAPE_RATIO_UP]

class Game_BattlerBase

  def max_tp
    Taroxd::Const::MAX_TP
  end if Taroxd::Const[:MAX_TP]

  def attack_skill_id
    Taroxd::Const::ATTACK_SKILL_ID
  end if Taroxd::Const[:ATTACK_SKILL_ID]

  def guard_skill_id
    Taroxd::Const::GUARD_SKILL_ID
  end if Taroxd::Const[:GUARD_SKILL_ID]

  def death_state_id
    Taroxd::Const::DEATH_STATE_ID
  end if Taroxd::Const[:DEATH_STATE_ID]

  def param_min(_)
    0
  end if Taroxd::Const[:PARAM_LIMIT]

  def param_max(_)
    Taroxd::Const::PARAM_LIMIT
  end if Taroxd::Const[:PARAM_LIMIT]

  def preserve_tp?
    true
  end if Taroxd::Const[:PRESERVE_TP]
end

class Game_Battler < Game_BattlerBase

  def luk_effect_rate(user)
    [1.0 + (user.luk - luk) * Taroxd::Const::LUK_EFFECT_RATE, 0.0].max
  end if Taroxd::Const[:LUK_EFFECT_RATE]

  def apply_critical(damage)
    damage * Taroxd::Const::CRITICAL_RATE
  end if Taroxd::Const[:CRITICAL_RATE]
end

class Game_Actor < Game_Battler

  remove_method :param_max if Taroxd::Const[:PARAM_LIMIT]

  def steps_for_turn
    Taroxd::Const::STEPS_FOR_RUN
  end if Taroxd::Const[:STEPS_FOR_RUN]

  def basic_floor_damage
    Taroxd::Const::BASIC_FLOOR_DAMAGE
  end if Taroxd::Const[:BASIC_FLOOR_DAMAGE]
end

class Game_Party < Game_Unit

  def max_battle_members
    Taroxd::Const::MAX_BATTLE_MEMBERS
  end if Taroxd::Const[:MAX_BATTLE_MEMBERS]

  def max_gold
    Taroxd::Const::MAX_GOLD
  end if Taroxd::Const[:MAX_GOLD]

  def max_item_number(_)
    Taroxd::Const::MAX_ITEM_NUMBER
  end if Taroxd::Const[:MAX_ITEM_NUMBER]
end

class Game_CharacterBase

  def update_bush_depth
    if normal_priority? && !object_character? && bush? && !jumping?
      @bush_depth = Taroxd::Const::BUSH_DEPTH unless moving?
    else
      @bush_depth = 0
    end
  end if Taroxd::Const[:BUSH_DEPTH]
end

class Sprite_Character < Sprite_Base

  def_after :initialize do |_, _ = nil|
    self.bush_opacity = Taroxd::Const::BUSH_OPACITY
  end if Taroxd::Const[:BUSH_OPACITY]
end

class Game_Player < Game_Character

  def_after :initialize do
    @direction = Taroxd::Const::PLAYER_INITIAL_DIRECTION
  end if Taroxd::Const[:PLAYER_INITIAL_DIRECTION]
end

class Scene_Battle < Scene_Base

  def check_substitute(target, item)
    target.hp_rate < Taroxd::Const::SUBSTITUTE_HP_RATE &&
      (!item || !item.certain?)
  end if Taroxd::Const[:SUBSTITUTE_HP_RATE]
end