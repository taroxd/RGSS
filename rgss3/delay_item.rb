# @taroxd metadata 1.0
# @require taroxd_core
# @id delay_item
# @display 延迟技能
# @help
#   使用方法：技能备注<delay n>，n 为延迟的回合数，n <= 0 为当前回合结束时发动
#       技能备注<delay message s>，s为技能施放时提示的信息。
#       其中使用者名称用\N代替。

module Taroxd
  DelayItem = '\N'     # 用 \N 代替使用者名称
end

class RPG::UsableItem
  note_i :delay, false
  note_s :delay_message
end

class Window_BattleLog < Window_Selectable

  def display_delay_use_item(subject, item)
    add_text(item.delay_message.gsub(Taroxd::DelayItem, subject.name))
  end
end

class Scene_Battle < Scene_Base

  def_after(:start) { @delay_list = [] }

  def_chain :execute_action do |old|
    item = @subject.current_action.item
    return old.call unless item.delay
    @log_window.display_delay_use_item(@subject, item)
    subject = @subject
    action = @subject.current_action
    @delay_list.push Fiber.new {
      item.delay.times { Fiber.yield }
      subject.actions.unshift(action)
      @subject, subject = subject, @subject
      old.call
      @subject.remove_current_action
      @subject = subject
      true
    }
  end

  def_before(:turn_end) { @delay_list.delete_if(&:resume) }
end