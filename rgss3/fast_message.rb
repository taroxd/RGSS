# @taroxd metadata 1.0
# @id fast_message
# @display 快进对话

module Taroxd
  module FastMessage
    KEY = :CTRL      # 按此键快进对话
    ENABLED = $TEST  # true: 启用; $TEST: 仅测试模式; false: 不启用
    SPEED = 3        # 文字快进速度。可以为小数，但不能小于 1。

    @counter = 0

    # 是否在输出一个字符后等待。show_fast: 是否快进
    def self.wait?(show_fast)
      !show_fast && !Input.press?(KEY) || (@counter += 1) % SPEED < 1
    end

    # 已经进入等待输入的情况下，是否继续等待输入
    def self.keep_pause?
      [:B, :C, KEY].none? { |k| Input.trigger?(k) }
    end

    # 尚未进入等待输入的情况下，是否跳过等待输入
    def self.skip_pause?
      Input.press?(KEY)
    end
  end
end

class Window_Message < Window_Base

  FastMessage = Taroxd::FastMessage

  def input_pause
    return if FastMessage.skip_pause?
    self.pause = true
    wait(10)
    Fiber.yield while FastMessage.keep_pause?
    Input.update
    self.pause = false
  end

  def wait_for_one_character
    update_show_fast
    Fiber.yield if FastMessage.wait?(@show_fast || @line_show_fast)
  end
end if Taroxd::FastMessage::ENABLED
