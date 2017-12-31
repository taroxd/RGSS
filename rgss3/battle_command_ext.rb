# @taroxd metadata 1.0
# @require taroxd_core
# @display 战斗指令优化
# @id battle_command_ext
# @help
#   效果：
#     攻击指令无需选择目标时，跳过目标选择。
#     防御指令需要选择目标时，添加目标选择。
#     攻击、防御的指令名变为对应的技能名。（“用语”中的设置将会无效）

Taroxd::BattleCommandExt = true

class Scene_Battle < Scene_Base

  # 普通攻击无需选择目标的情况
  def_chain :command_attack do |old|
    skill = $data_skills[BattleManager.actor.attack_skill_id]
    if !skill.need_selection?
      BattleManager.actor.input.set_attack
      next_command
    elsif skill.for_opponent?
      old.call
    else
      BattleManager.actor.input.set_attack
      select_actor_selection
    end
  end

  # 防御需要选择目标的情况
  def_chain :command_guard do |old|
    skill = $data_skills[BattleManager.actor.guard_skill_id]
    if skill.need_selection?
      BattleManager.actor.input.set_guard
      skill.for_opponent? ? select_enemy_selection : select_actor_selection
    else
      old.call
    end
  end
end

class Window_ActorCommand < Window_Command

  # 更改攻击指令名称
  def add_attack_command
    name = $data_skills[@actor.attack_skill_id].name
    add_command(name, :attack, @actor.attack_usable?)
  end

  # 更改防御指令名称
  def add_guard_command
    name = $data_skills[@actor.guard_skill_id].name
    add_command(name, :guard, @actor.guard_usable?)
  end
end
