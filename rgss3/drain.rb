# @taroxd metadata 1.0
# @id drain
# @display 按比例吸血
# @require taroxd_core
# @help 
#   在可以设置“特性”的地方备注 <drain r>。
#   其中 r 为吸血的比例。

Taroxd::Drain = true

RPG::BaseItem.note_f :drain

Game_Battler.send :def_after, :execute_damage do |user|
  if @result.hp_damage > 0
    user.hp += (@result.hp_damage * user.feature_objects.sum(&:drain)).to_i
  end
end
