# @taroxd metadata 1.0
# @display 位图功能扩展
# @id bitmap_ext
# @help 需要将 rgssdll.dll 放入 System 文件夹下。

module Taroxd
  module BitmapExt
    DLL_FILE = 'System/rgssdll'
    XOR = Win32API.new(DLL_FILE, 'bitmap_xor', 'LL', 'L')
    OR  = Win32API.new(DLL_FILE, 'bitmap_or',  'LL', 'L')
    AND = Win32API.new(DLL_FILE, 'bitmap_and', 'LL', 'L')
  end
end

class Bitmap

  include Taroxd::BitmapExt

  # 对位图的每个像素做 xor 运算。
  # color: 0xaarrggbb
  def xor!(color)
    XOR.call(__id__, color)
  end

  # 对位图的每个像素做 or 运算。
  # color: 0xaarrggbb
  def or!(color)
    OR.call(__id__, color)
  end

  # 对位图的每个像素做 and 运算。
  # color: 0xaarrggbb
  def and!(color)
    AND.call(__id__, color)
  end
end