# @taroxd metadata 1.0
# @display 跳过标题画面
# @help 测试游戏时跳过标题画面
# @id skip_title

module Taroxd
  SkipTitle = $TEST && !$BTEST
end

def SceneManager.first_scene_class
  DataManager.setup_new_game
  $game_map.autoplay
  Scene_Map
end if Taroxd::SkipTitle