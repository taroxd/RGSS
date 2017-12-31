# @taroxd metadata 1.0
# @id disable_key_item
# @display 禁用贵重物品
# @require taroxd_core
# @help 禁用“贵重物品”功能

Taroxd::DisableKeyItem = true

class RPG::Item < RPG::UsableItem
  def key_item?
    false
  end
end

class Window_ItemCategory < Window_HorzCommand
  def col_max
    3
  end

  def make_command_list
    add_command(Vocab::item,   :item)
    add_command(Vocab::weapon, :weapon)
    add_command(Vocab::armor,  :armor)
  end
end

class Window_KeyItem < Window_ItemList

  def_after(:start) { self.category = :item }

  def enable?(item)
    true
  end
end