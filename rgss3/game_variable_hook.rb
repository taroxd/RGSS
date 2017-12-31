# @taroxd metadata 1.0
# @id game_variable_hook
# @display 开关变量钩子
# @help
#   该脚本可将开关/变量固定为一个游戏数据。
#   可以用于事件页的出现条件，
#   可以用于其他以开关作为条件的脚本。
#
#   设置区域在下方，设置范例：
#
#   变量1 固定为队伍的金钱
#     variable(1) { $game_party.gold }
#
#   变量2 固定为队伍中第i+1号队员的体力值，其中i为变量2原本的值
#     variable(2) do |i|
#       actor = $game_party.members[i]
#       actor ? actor.hp : 0
#     end
#
#   开关1 取反
#     switch(1, &:!)

module Taroxd end

module Taroxd::GameVariableHook

  # 是否更改F9调试窗口的显示。如无冲突建议为 true。
  DEBUG_WINDOW = true

  @list = {}  # 保存了监控设置的哈希表

  # 获取变量的值
  def self.operate(id, value)
    proc = @list[id]
    proc ? proc.call(value) : value
  end

  # 增加开关监控（不存档）
  def self.switch(id, &proc)
    @list[-id] = proc
  end

  # 增加变量监控（不存档）
  def self.variable(id, &proc)
    @list[id] = proc
  end

  # 是否正在监控。若列表不存在对应的项或值为 nil，则返回 nil。
  def self.include?(id)
    @list[id]
  end

  # --- 设置区域在此 ---

  # --- 设置区域结束 ---
end

class Game_Switches
  alias_method :value_without_hook, :[]
  def [](id)
    Taroxd::GameVariableHook.operate(-id, value_without_hook(id))
  end
end

class Game_Variables
  alias_method :value_without_hook, :[]
  def [](id)
    Taroxd::GameVariableHook.operate(id, value_without_hook(id))
  end
end

class Game_Interpreter
  def operate_variable(id, type, value)
    $game_variables[id] = case type
    when 0  # 代入
      value
    when 1  # 加法
      $game_variables.value_without_hook(id) + value
    when 2  # 减法
      $game_variables.value_without_hook(id) - value
    when 3  # 乘法
      $game_variables.value_without_hook(id) * value
    when 4  # 除法
      value.zero? ? 0 : $game_variables.value_without_hook(id) / value
    when 5  # 取余
      value.zero? ? 0 : $game_variables.value_without_hook(id) % value
    end
  end
end

class Window_DebugRight < Window_Selectable
  def update_switch_mode
    return unless Input.trigger?(:C)
    id = current_id
    $game_switches[id] = !$game_switches.value_without_hook(id)
    Sound.play_ok
    redraw_current_item
  end

  def update_variable_mode
    id = current_id
    value = $game_variables.value_without_hook(id)
    return unless value.is_a?(Numeric)
    value += 1 if Input.repeat?(:RIGHT)
    value -= 1 if Input.repeat?(:LEFT)
    value += 10 if Input.repeat?(:R)
    value -= 10 if Input.repeat?(:L)
    if $game_variables.value_without_hook(current_id) != value
      $game_variables[id] = value
      Sound.play_cursor
      redraw_current_item
    end
  end

  def draw_item(index)
    data_id = @top_id + index
    id_text = sprintf("%04d:", data_id)
    id_width = text_size(id_text).width
    if @mode == :switch
      name = $data_system.switches[data_id]
      status = $game_switches.value_without_hook(data_id) ? '[ON]' : '[OFF]'
      if Taroxd::GameVariableHook.include?(-data_id)
        status.concat($game_switches[data_id] ? ' ->  [ON]' : ' -> [OFF]')
      end
    else
      name = $data_system.variables[data_id]
      status = $game_variables.value_without_hook(data_id).to_s
      if Taroxd::GameVariableHook.include?(data_id)
        status << ' -> ' << $game_variables[data_id].to_s
      end
    end
    name = "" unless name
    rect = item_rect_for_text(index)
    change_color(normal_color)
    draw_text(rect, id_text)
    rect.x += id_width
    rect.width -= id_width + 60
    draw_text(rect, name)
    rect.width += 60
    draw_text(rect, status, 2)
  end
end if Taroxd::GameVariableHook::DEBUG_WINDOW