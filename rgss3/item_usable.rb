# @taroxd metadata 1.0
# @id item_usable
# @display 物品禁用
# @require taroxd_core
# @help
#   使用方法：技能/道具备注以下内容
#    <unusable x> 或 <usable -x> ：当 x 号开关开启时，技能/道具禁止使用
#    <usable x> 或 <unusable -x> ：当 x 号开关关闭时，技能/道具禁止使用

Taroxd::ItemUsable = true

class RPG::UsableItem < RPG::BaseItem
  # 获取开关 ID 构成的数组
  def unusable_switches
    @unusable_switches ||=
    @note.scan(/<(UN)?USABLE\s+(-*\d+)>/i).map { |(un, id)|
      un ? id.to_i : -id.to_i
    }.uniq
  end
end

class Game_BattlerBase
  id_ok = -> id { (id > 0) ^ $game_switches[id.abs] }
  ok = -> item { item.unusable_switches.all?(&id_ok) }
  def_and :usable_item_conditions_met?, ok
end