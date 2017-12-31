# @taroxd metadata 1.0
# @id shift_reverse
# @require taroxd_core
# @display Shift 功能反转

module Taroxd
  ShiftReverse = true
end

class Game_Player < Game_Character

  def dash?
    !@move_route_forcing && !$game_map.disable_dash? &&
      !vehicle && !Input.press?(:A)
  end

end