# @taroxd metadata 1.0
# @id const_rg
# @display 定值再生
# @require taroxd_core
# @help 备注<hrg x>，表示每回合回复 x 点 HP。
#       备注<mrg x>，表示每回合回复 x 点 MP。
#       备注<trg x>，表示每回合回复 x 点 TP。
#       其中 x 可以为负数

Taroxd::ConstRG = true

%w(h m t).each do |type|
  name = "#{type}rg"
  RPG::BaseItem.note_f name
  Game_BattlerBase.class_eval %{
    def_with :#{name} do |old|
      max = m#{type}p
      max == 0 ? old : feature_objects.sum(old) { |obj| obj.#{name} / max }
    end
  }
end