# @taroxd metadata 1.0
# @id negative_input
# @display 输入负数数值
# @help 数值输入处理可以输入负数

module Taroxd
  NegativeInput = true
end

class Window_NumberInput < Window_Base

  def start
    @digits_max = $game_message.num_input_digits_max + 1
    num = $game_variables[$game_message.num_input_variable_id]
    max_num = 10**(@digits_max - 1) - 1
    num = [[num, max_num].min, -max_num].max
    @number = sprintf('%+0*d', @digits_max, num)
    @index = 0
    update_placement
    create_contents
    refresh
    open
    activate
  end

  def process_digit_change
    return unless active
    if Input.repeat?(:UP) || Input.repeat?(:DOWN)
      Sound.play_cursor
      if @index == 0
        @number[0] = @number.start_with?('+') ? '-' : '+'
      else
        n = @number[@index].to_i
        @number[@index] = ((n + (Input.repeat?(:UP) ? 1 : -1)) % 10).to_s
      end
      refresh
    end
  end

  def refresh
    contents.clear
    change_color(normal_color)
    @digits_max.times do |i|
      rect = item_rect(i)
      rect.x += 1
      draw_text(rect, @number[i], 1)
    end
  end

  def process_ok
    Sound.play_ok
    $game_variables[$game_message.num_input_variable_id] = @number.to_i
    deactivate
    close
  end
end
