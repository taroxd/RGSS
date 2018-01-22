# @taroxd metadata 1.0
# @require taroxd_core
# @require point
# @id event_screen_offset
# @display 调整事件位置
# @help
#   事件名称中填写 <offset x y>，可将事件在屏幕上的位置偏移 (x, y)

module Taroxd
  EventScreenOffset = /<offset\s*(\d+)\s+(\d+)/i
end

class RPG::Event
  def screen_offset
    return @screen_offset unless @screen_offset.nil?
    if name =~ Taroxd::EventScreenOffset
      @screen_offset = Taroxd::Point[$1.to_i, $2.to_i]
    else
      @screen_offset = false
    end
  end
end

class Game_Event < Game_Character
  def_with :screen_x do |old|
    @event.screen_offset ? old + @event.screen_offset.x : old
  end

  def_with :screen_y do |old|
    @event.screen_offset ? old + @event.screen_offset.y : old
  end
end