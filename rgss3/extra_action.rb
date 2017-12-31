# @taroxd metadata 1.0
# @id extra_action
# @require taroxd_core
# @display 额外战斗行动
# @help
#
#    在战斗公式或事件指令-脚本中输入
#      battler.extra_skill(skill_id, target_index)
#    即可产生一次额外的行动（对应 skill_id 的技能）。
#    target_index 省略时，目标默认为 battler 上次的目标。
#
#    battler.extra_item(item_id, target_index)
#      与 extra_skill 相同。行动内容为对应 item_id 的物品。
#
#    battler.extra_action(skill_id, target_index)
#      与 extra_skill 相同。
#
#    注意，额外的行动也是有消耗的（包括 MP、物品等）
#    当消耗不满足，或者因为其他原因无法行动时，额外行动无效。


class Taroxd::ExtraAction < Game_Action

  # 默认目标。-2: 上次目标, -1: 随机
  DEFAULT_TARGET_INDEX = -2

  class << self

    def new(_, _)
      super.tap { |action| @actions.push action }
    end

    # 获取最后生成的 action 对象并移除这个对象。
    # 如果没有 action，返回 nil。
    def current!
      @actions.pop
    end

    def clear
      @actions = []
    end
  end

  def initialize(subject, target_index)
    super(subject)
    @target_index = target_index
  end

  def make_targets
    @target_index = @subject.last_target_index if @target_index == -2
    super
  end
end

class Game_Battler < Game_BattlerBase
  
  ExtraAction = Taroxd::ExtraAction

  def extra_skill(id, target_index = ExtraAction::DEFAULT_TARGET_INDEX)
    ExtraAction.new(self, target_index).set_skill(id)
  end

  alias_method :extra_action, :extra_skill

  def extra_item(id, target_index = ExtraAction::DEFAULT_TARGET_INDEX)
    ExtraAction.new(self, target_index).set_item(id)
  end
end

class Scene_Battle < Scene_Base

  def_before :battle_start, Taroxd::ExtraAction.method(:clear)

  def_before :process_forced_action do
    action = Taroxd::ExtraAction.current!
    return unless action
    last_subject = @subject
    @subject = action.subject
    @subject.actions.unshift(action)
    process_action
    @subject = last_subject
  end
end
