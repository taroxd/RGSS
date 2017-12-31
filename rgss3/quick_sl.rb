# @taroxd metadata 1.0
# @require taroxd_core
# @require keyboard
# @id quick_sl
# @display 快速存读档
# @help
#    快速存档读档
#
#    使用方法：按下下方设置的按键可以快速存档读档。
#    事件脚本中调用：
#      quick_save 快速存档
#      quick_load 快速读档
#      quick_save_quiet 存档（无音效）

module Taroxd::QuickSL

  module_function

  # 存档位置
  def quick_save_index
    0
  end

  # 是否按下了存档键
  def trigger_save?
    Keyboard.trigger?(Keyboard::S)
  end

  # 是否按下了读档键
  def trigger_load?
    Keyboard.trigger?(Keyboard::L)
  end

  def quick_save_quiet
    DataManager.save_game(quick_save_index)
  end

  def quick_save
    quick_save_quiet ? Sound.play_save : Sound.play_buzzer
  end

  def quick_load
    if DataManager.load_game(quick_save_index)
      Sound.play_load
      SceneManager.scene.fadeout_all
      $game_system.on_after_load
      SceneManager.goto(Scene_Map)
    else
      Sound.play_buzzer
    end
  end

  def update_call_quick_save
    quick_save if !$game_system.save_disabled && trigger_save?
  end

  def update_call_quick_load
    quick_load if trigger_load?
  end

  def update_call_quickSL
    update_call_quick_save
    update_call_quick_load
  end
end

class Scene_Map < Scene_Base
  include Taroxd::QuickSL
  def_after(:update_scene) { update_call_quickSL unless scene_changing? }
end

class Scene_Title < Scene_Base
  include Taroxd::QuickSL
  def_after(:update) { update_call_quick_load unless scene_changing? }
end

class Game_Interpreter
  include Taroxd::QuickSL
end