# @taroxd metadata 1.0
# @require taroxd_core
# @display 固定远景
# @id zero_parallax

module Taroxd
  # 判断是否固定远景图
  ZeroParallax =
    proc { true }                          # 永远固定
    # -> name { name.start_with? '!' }     # 文件名以 ! 开头时固定
end

class Game_Map

  def_chain :parallax_ox do |old, bitmap|
    @parallax_zero ? @parallax_x * 32 : old.call(bitmap)
  end

  def_chain :parallax_oy do |old, bitmap|
    @parallax_zero ? @parallax_y * 32 : old.call(bitmap)
  end

  def update_parallax_zero(*)
    @parallax_zero = Taroxd::ZeroParallax.call(@parallax_name)
  end

  def_after :change_parallax, :update_parallax_zero
  def_after :setup_parallax, :update_parallax_zero
end
