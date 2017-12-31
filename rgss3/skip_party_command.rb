# @taroxd metadata 1.0
# @id skip_party_command
# @display 跳过撤退指令
# @help 不可撤退时，跳过“战斗/撤退”指令的选择

module Taroxd
  module SkipPartyCommand
    # 满足此条件时，不跳过指令选择
    def self.disabled?
      BattleManager.can_escape?
    end
  end
end

# 是否存在上一个指令。无副作用。
def BattleManager.prior_command?
  actors = $game_party.battle_members.first(@actor_index + 1)
  actor = actors.pop
  actor && (actor.prior_command? || actors.any?(&:inputable?))
end

class Game_Actor < Game_Battler
  # 是否已经输入过指令
  def prior_command?
    @action_input_index > 0
  end
end

class Scene_Battle < Scene_Base

  def start_party_command_selection
    return if scene_changing?
    refresh_status
    @status_window.unselect
    @status_window.open
    if BattleManager.input_start
      if Taroxd::SkipPartyCommand.disabled?
        @actor_command_window.close
        @party_command_window.setup
      else
        command_fight
      end
    else
      @party_command_window.deactivate
      turn_start
    end
  end

end

class Window_ActorCommand < Window_Command
  def cancel_enabled?
    Taroxd::SkipPartyCommand.disabled? || BattleManager.prior_command?
  end
end