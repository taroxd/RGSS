# @taroxd metadata 1.0
# @display 属性修正的扩展
# @require taroxd_core
# @id element_effect
# @help
#   使用方法：在角色/职业/技能/装备/敌人/状态上备注<element id rate>，
#             表示该角色/该职业/习得技能后/装上装备后/该敌人/获得状态后，
#             战斗者使用第 id 号属性的技能时，效果乘以 rate

Taroxd::ElementEffect = true

class RPG::BaseItem
  # 属性效果构成的 hash，属性ID => 效果
  def element_effect
    @element_effect ||= @note.scan(/<ELEMENT\s+(\d+)\s+(\d+(?:\.\d+)?)>/i)
      .each_with_object(Hash.new(1.0)) { |(id, rate), hash|
        hash[id.to_i] *= rate.to_f }
  end
end

class Game_Battler < Game_BattlerBase
  def element_effect
    note_objects.each_with_object(Hash.new(1.0)) do |e, h|
      h.merge!(e.element_effect) { |_, r1, r2| r1 * r2 }
    end
  end

  calc_new_rate = lambda do |old, user, item|
    if item.damage.element_id < 0
      user.atk_elements.pi(old) { |id| user.element_effect[id] }
    else
      old * user.element_effect[item.damage.element_id]
    end
  end
  def_with :item_element_rate, calc_new_rate
end