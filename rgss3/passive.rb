# @taroxd metadata 1.0
# @id passive
# @display 被动技能状态
# @require taroxd_core
# @help 
#   在技能/状态上备注<passive x>，
#   表示习得该技能/获得该状态等同于装备了x号武器。

Taroxd::Passive = true

RPG::Skill.note_i :passive
RPG::State.note_i :passive

class Game_Actor < Game_Battler

  # 带有被动技能效果的所有实例
  def passive_objects
    @skills.map { |id| $data_skills[id] } + states
  end
  # 特性表和能力中加上被动武器
  def_with(:feature_objects) { |old| old + passive_weapons }

  def_with :param_plus do |old, param_id|
    passive_weapons.sum(old) { |item| item.params[param_id] }
  end

  # 被动技能/状态对应的武器实例构成的数组
  def passive_weapons
    passive_objects.map { |obj| $data_weapons[obj.passive] }.compact
  end
end
