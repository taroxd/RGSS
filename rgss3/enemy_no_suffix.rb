# @taroxd metadata 1.0
# @id enemy_no_suffix
# @display 同名敌人不显示后缀
# @require taroxd_core
# @help 同名的敌人不附加字母后缀

Taroxd::EnemyNoSuffix = false

class Game_Troop < Game_Unit
  def_after(:make_unique_names) { each { |enemy| enemy.letter = '' } }
end