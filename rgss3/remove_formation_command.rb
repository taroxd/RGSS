# @taroxd metadata 1.0
# @id remove_formation_command
# @display 删除整队指令

module Taroxd
  RemoveFormationCommand = true
end

class Window_MenuCommand < Window_Command
  def add_formation_command; end
end