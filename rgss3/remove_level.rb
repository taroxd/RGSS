# @taroxd metadata 1.0
# @id remove_level
# @display 删除等级功能
# @help 移除所有有关等级和经验值的功能

module Taroxd
  # 试图访问角色等级时执行。参数即为方法的参数。
  RemoveLevel = -> * { 0 }
end

class Game_Actor < Game_Battler

  # 等级视为初始等级。仅用于计算属性
  def level
    actor.initial_level
  end

  %W(level_up level_down init_exp exp exp_for_level
    current_level_exp next_level_exp max_level? max_level
    change_exp display_level_up gain_exp final_exp_rate
    reserve_members_exp_rate change_level).each do |name|
    define_method name, Taroxd::RemoveLevel
  end
end

Window_Base.send :define_method, :draw_actor_level, Taroxd::RemoveLevel
Window_Status.send :define_method, :draw_exp_info, Taroxd::RemoveLevel