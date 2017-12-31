# @taroxd metadata 1.0
# @id item_repeat
# @display 随机连续次数
# @require taroxd_core
# @help 在技能/道具上备注 <repeats x y z...>
#       则连续次数将会随机在 x, y, z... 中选择。
#    例：备注 <repeats 1 1 2> 那么该道具将会有 1/3 的几率连续发动 2 次。

module Taroxd
  ItemRepeat = /<repeats((?:\s+\d+)+)>/i
end

RPG::UsableItem.send :def_chain, :repeats do |old|
  @note =~ Taroxd::ItemRepeat ? $1.split(' ').sample.to_i : old.call
end