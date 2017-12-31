# @taroxd metadata 1.0
# @display 修复 bug
# @desciption 修复默认系统的一些 bug。详见下方的注释
# @id rgss_bugfix

module Taroxd
  module BugFix
    # Plane#visible 永远返回 true 的 bug。需要主动 include。
    module PlaneVisible

      def initialize(_)
        super
        @__visible = true
      end

      def visible
        @__visible
      end

      def visible=(v)
        @__visible = v
        super
      end
    end
  end
end

class Game_BattlerBase
  # max_tp 不为 100 时，以下两方法返回值错误的 bug
  def tp_rate
    @tp.fdiv(max_tp)
  end

  def regenerate_tp
    self.tp += max_tp * trg
  end
end

class Game_Interpreter
  # 震动画面后等待时间不正确的 bug
  def command_225
    screen.start_shake(@params[0], @params[1], @params[2])
    wait(@params[2]) if @params[3]
  end
end