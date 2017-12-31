# @taroxd metadata 1.0
# @require taroxd_core
# @id target_ext
# @display 使用目标的扩展
# @help 设置技能、物品的使用目标。
#
# 使用方法：
#   在技能/物品的备注栏写下类似于下面例子的备注，设置可选择的全体目标。
#
#   该脚本不影响菜单中使用技能/物品。
#
#   用 a 指代使用者，用 b 或 self 指代目标。
#
#   例1：存活队员中 hp 比例最小者。
#   <target>
#     select: alive?
#     min_by: hp_rate
#   </target>
#
#   例2：所有 hp 大于 50 的队员
#   <target>
#     select: hp > 50
#   </target>
#
#   例3：除自己之外的全体队友
#   <target>
#     select: alive? && b != a
#   </target>
#
#   例4：无视生死
#   <target></target>

module Taroxd::TargetExt

  RE_OUTER = /<target>(.*?)<\/target>/mi # 整体设置
  SEPARATOR = ':'                        # 每一行中的分隔符

  # 实例方法，用于选择目标的窗口中

  # virtual
  # 返回可以选择的所有目标
  def targets_to_select
    []
  end

  # 返回设置的目标
  # 若 actor 未初始化，或没有设置目标，返回 nil
  def selectable_targets
    actor = BattleManager.actor
    return unless actor
    item = actor.input.item
    return unless item
    item.get_targets(actor, targets_to_select)
  end

  # 由于父类可能未定义，不调用 super
  def enable?(battler)
    targets = selectable_targets
    !targets || targets.include?(battler)
  end

  def current_item_enabled?
    super && enable?(targets_to_select[index])
  end

  # 模块方法，用于读取备注

  def self.parse_note(note)
    note =~ RE_OUTER ? parse_settings($1) : false
  end

  private

  # lambda do |battlers, a|
  #   battlers.select { |b| b.instance_eval { alive? && b != a } }
  # end
  def self.parse_settings(settings)
    eval %(
      lambda do |battlers, a|
        battlers#{extract_settings(settings)}
      end
    )
  end

  def self.extract_settings(settings)
    settings.each_line.map { |line|
      method, _, block = line.partition(SEPARATOR).map(&:strip)
      if method.empty?
        ''
      elsif block.empty?
        ".#{method}"
      else
        ".#{method} { |b| b.instance_eval { #{block} } }"
      end
    }.join
  end

end

class RPG::UsableItem < RPG::BaseItem

  # 缓存并返回生成的 lambda。
  # 如果不存在，返回伪值。
  def get_target_lambda
    @get_target = Taroxd::TargetExt.parse_note(@note) if @get_target.nil?
    @get_target
  end

  # 返回目标的数组。a：使用者。
  # 如果没有设置，返回 nil。
  def get_targets(a, battlers = nil)
    return unless get_target_lambda
    battlers ||= (for_friend? ? a.friends_unit : a.opponents_unit).members
    Array(get_target_lambda.call(battlers, a))
  end

end

class Game_Action

  def_chain :targets_for_opponents do |old|
    targets = item.get_targets(@subject)
    if !targets
      old.call
    elsif item.for_random?
      Array.new(item.number_of_targets) { random_target(targets) }
    elsif item.for_one?
      num = 1 + (attack? ? subject.atk_times_add.to_i : 0)
      target = if @target_index < 0
        random_target(targets)
      else
        eval_smooth_target(opponents_unit, @target_index)
      end
      Array.new(num, target)
    else
      targets
    end
  end

  def_chain :targets_for_friends do |old|
    targets = item.get_targets(@subject)
    if !targets
      old.call
    elsif item.for_user?
      [subject]
    else
      if item.for_one?
        if @target_index < 0
          [random_target(targets)]
        else
          [eval_smooth_target(friends_unit, @target_index)]
        end
      else
        targets
      end
    end
  end

  private

  def eval_smooth_target(unit, index)
    unit[index] || unit[0]
  end

  def random_target(targets)
    tgr_rand = rand * targets.sum(&:tgr)
    targets.each do |target|
      tgr_rand -= target.tgr
      return target if tgr_rand < 0
    end
    targets.first
  end
end

class Game_BattlerBase
  # 如果设置了目标，必须存在目标才可使用
  def_and :usable_item_conditions_met? do |item|
    targets = item.get_targets(self)
    !targets || !targets.empty?
  end
end

class Game_Battler < Game_BattlerBase
  # 如果设置了目标，删除是否死亡的测试
  def_chain :item_test do |old, user, item|
    if item.get_target_lambda
      return true if $game_party.in_battle
      return true if item.for_opponent?
      return true if item.damage.recover? && item.damage.to_hp? && hp < mhp
      return true if item.damage.recover? && item.damage.to_mp? && mp < mmp
      return true if item_has_any_valid_effects?(user, item)
      false
    else
      old.call(user, item)
    end
  end
end

class Window_BattleActor < Window_BattleStatus

  include Taroxd::TargetExt

  def targets_to_select
    $game_party.battle_members
  end

  def draw_actor_name(actor, x, y, width = 112)
    change_color(hp_color(actor), enable?(actor))
    draw_text(x, y, width, line_height, actor.name)
  end
end

class Window_BattleEnemy < Window_Selectable

  include Taroxd::TargetExt

  def targets_to_select
    $game_troop.alive_members
  end

  def draw_item(index)
    enemy = $game_troop.alive_members[index]
    change_color(normal_color, enable?(enemy))
    name = enemy.name
    draw_text(item_rect_for_text(index), name)
  end
end