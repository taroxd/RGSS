# @taroxd metadata 1.0
# @require taroxd_core
# @id eval
# @display 脚本快捷方式
# @deprecated

module Taroxd::Eval

  Game_Character.send   :include, self
  Game_Interpreter.send :include, self
  # 脚本中的简称列表
  SCRIPT_ABBR_LIST = {
    'V' => '$game_variables',
    'S' => '$game_switches',
    'N' => '$game_actors',
    'A' => '$game_actors',
    'P' => '$game_party',
    'G' => '$game_party.gold',
    'E' => '$game_troop'
  }
  # 处理脚本用的正则表达式
  words = SCRIPT_ABBR_LIST.keys.join('|')
  SCRIPT_ABBR_RE = /(?<!::|['"\\\.])\b(?:#{words})\b(?! *[(@$\w'"])/


  module_function

  def process_script(script)
    script.gsub(SCRIPT_ABBR_RE, SCRIPT_ABBR_LIST)
  end

  def eval(script, *args)
    v = $game_variables
    s = $game_switches
    n = $game_actors
    a = $game_actors
    p = $game_party
    g = $game_party.gold
    e = $game_troop
    script = process_script(script)
    if args.empty?
      instance_eval(script, __FILE__, __LINE__)
    else
      Kernel.eval(script, *args)
    end
  end
end

class RPG::UsableItem::Damage
  def eval(a, b, v)
    value = Taroxd::Eval.eval(@formula, b.formula_binding(a, b, v))
    value > 0 ? value * sign : 0
  end
end

class Game_BattlerBase
  def formula_binding(a, b, v)
    s = $game_switches
    n = $game_actors
    p = $game_party
    g = $game_party.gold
    e = $game_troop
    binding
  end
end

class Window_Base < Window
  # 对 #{} 的处理
  process_expression = Proc.new do |old|
    old.gsub(/\e?#(?<brace>\{([^{}]|\g<brace>)*\})/) do |code|
      next code if code.slice!(0) == "\e"
      Taroxd::Eval.eval code[1..-2]
    end
  end
  def_with :convert_escape_characters, process_expression
end
