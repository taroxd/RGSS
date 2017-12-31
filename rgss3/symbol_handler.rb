# @taroxd metadata 1.0
# @display 简化 handler 设置
# @id symbol_handler
# @help 简化命令窗口的 handler 设置

module Taroxd

  # Window_Command 的子类 include 后，会自动对场景调用 symbol 对应的
  # command_symbol 方法，无需再 set_handler。
  module SymbolHandler

    def handle?(symbol)
      super || symbol_to_command(symbol)
    end

    def call_handler(symbol)
      @handler[symbol].call if @handler.key?(symbol)
      command = symbol_to_command(symbol)
      receiver.send(command) if command
    end

    private

    # 以下方法可由子类覆盖。

    # 调用者。默认为当前场景。
    def receiver
      SceneManager.scene
    end

    def command_prefix
      'command_'
    end

    # 返回符号对应的场景方法名。
    # 场景不能响应 command_symbol 时，返回 nil。
    def symbol_to_command(symbol)
      sym = :"#{command_prefix}#{symbol}"
      sym if receiver.respond_to?(sym)
    end
  end
end