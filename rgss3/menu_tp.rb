# @taroxd metadata 1.0
# @id menu_tp
# @require taroxd_core
# @display 菜单中显示 TP

Taroxd::MenuTP = true

class Window_Base < Window
  def_chain :draw_actor_simple_status do |old, actor, x, y|
    if actor.preserve_tp?
      draw_actor_name(actor, x, y)
      draw_actor_level(actor, x, y + line_height)
      draw_actor_icons(actor, x, y + line_height * 2)
      draw_actor_class(actor, x + 120, y)
      draw_actor_hp(actor, x + 120, y + line_height)
      draw_actor_mp(actor, x + 120, y + line_height * 2, 60)
      draw_actor_tp(actor, x + 184, y + line_height * 2, 60)
    else
      old.(actor, x, y)
    end
  end
end

class Window_Status < Window_Selectable
  def_chain :draw_basic_info do |old, x, y|
    if @actor.preserve_tp?
      draw_actor_level(@actor, x, y)
      draw_actor_icons(@actor, x, y + line_height)
      draw_actor_hp(@actor, x, y + line_height * 2)
      draw_actor_mp(@actor, x, y + line_height * 3, 60)
      draw_actor_tp(@actor, x + 64, y + line_height * 3, 60)
    else
      old.(x, y)
    end
  end
end