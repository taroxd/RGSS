# @taroxd metadata 1.0
# @id static_character
# @display 静止行走图
# @require taroxd_core
# @help
#    静止的人物行走图。
#    图片文件名以 $$ 开头时，该图片将被视为一个唯一朝向的人物。

# 文件名满足的条件
Taroxd::StaticCharacter = -> name { name.start_with?('$$') }

class Sprite_Character < Sprite_Base

  def static?
    Taroxd::StaticCharacter.call(@character_name)
  end

  def_chain :set_character_bitmap do |old|
    return old.call unless static?
    self.bitmap = Cache.character(@character_name)
    self.ox = bitmap.width / 2
    self.oy = bitmap.height
  end

  def_unless :update_src_rect, :static?
end