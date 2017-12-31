# @taroxd metadata 1.0
# @id inherit
# @display 继承存档
# @require taroxd_core

module Taroxd::Inherit

  Game_Interpreter.send :include, self

  module_function

  def save_inherit_data(filename, flag = true)
    save_data({actors: $game_actors, party: $game_party, flag: flag},
      filename)
  end

  def load_inherit_data(filename)
    contents     = load_data(filename)
    $game_actors = contents[:actors]
    $game_party  = contents[:party]
    contents[:flag]
  end
end