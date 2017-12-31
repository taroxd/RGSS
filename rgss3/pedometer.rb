# @taroxd metadata 1.0
# @id pedometer
# @display 计步器
# @require taroxd_core
# @help 
#   事件脚本
#      start_pedometer(var_id[, count])
#        变量 var_id 开始计步。若 count 存在，将该变量设为 count。
#
#      stop_pedometer([var_id])
#        变量 var_id 停止计步。若 var_id 不存在，则停止所有计步器。

Taroxd::Pedometer = true

class Game_Party < Game_Unit

  def_after(:initialize) { @pedometer = [] }

  def start_pedometer(var_id, count = nil)
    @pedometer << var_id unless @pedometer.include?(var_id)
    $game_variables[var_id] = count if count
  end

  def stop_pedometer(var_id = nil)
    var_id ? @pedometer.delete(var_id) : @pedometer.clear
  end

  def_after :on_player_walk do
    @pedometer.each { |var_id| $game_variables[var_id] += 1 }
  end
end

class Game_Interpreter

  def start_pedometer(var_id, count = nil)
    $game_party.start_pedometer(var_id, count)
  end

  def stop_pedometer(var_id = nil)
    $game_party.stop_pedometer(var_id)
  end
end