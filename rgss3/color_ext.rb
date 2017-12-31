# @taroxd metadata 1.0
# @require taroxd_core
# @id color_ext
# @display 颜色扩展
# @help
#
#  扩展了 \C 控制符的功能。大小写不敏感。
#  可用的颜色名称可以在下面长长的列表中找到，当然也可以自定义。
#  自定义时，注意使用小写字母。
#
#  使用范例：
#    \C[1]这是普通的蓝色，\C[Blue]这也是。
#    \C[66CCFF]这是洛天依的蓝色，\C[6CF]这也是。
#    \C[66CCFF7F]这是有半透明效果的洛天依的蓝色。
#
#  Taroxd::ColorExt 模块
#
#    常量：COLORS
#      哈希表，键为小写字母的 symbol，值为对应的颜色。
#      :"66ccff" 这样的键也是可以接受的。
#      :"1" 到 :"31" 之间的符号返回窗口皮肤中的颜色。
#      找不到值时，返回 Color.new
#
#    模块方法：hex_code(code)
#      接受一个字符串为参数，返回对应的颜色。
#      code 可以是 "66ccff" 这样的
#
#    模块方法：text_color，normal_color 等等
#      与 Window_Base 的对应方法相同。
#      可以让 Sprite 类包含这个模块，使这些方法在 Sprite 类中也可用。


module Taroxd::ColorExt
  COLORS = {
    aliceblue:            Color.new(240, 248, 255),
    antiquewhite:         Color.new(250, 235, 215),
    aqua:                 Color.new(0, 255, 255),
    aquamarine:           Color.new(127, 255, 212),
    azure:                Color.new(240, 255, 255),
    beige:                Color.new(245, 245, 220),
    bisque:               Color.new(255, 228, 196),
    black:                Color.new(0, 0, 0),
    blanchedalmond:       Color.new(255, 235, 205),
    blue:                 Color.new(0, 0, 255),
    blueviolet:           Color.new(138, 43, 226),
    brown:                Color.new(165, 42, 42),
    burlywood:            Color.new(222, 184, 135),
    cadetblue:            Color.new(95, 158, 160),
    chartreuse:           Color.new(127, 255, 0),
    chocolate:            Color.new(210, 105, 30),
    coral:                Color.new(255, 127, 80),
    cornflowerblue:       Color.new(100, 149, 237),
    cornsilk:             Color.new(255, 248, 220),
    crimson:              Color.new(220, 20, 60),
    cyan:                 Color.new(0, 255, 255),
    darkblue:             Color.new(0, 0, 139),
    darkcyan:             Color.new(0, 139, 139),
    darkgoldenrod:        Color.new(184, 134, 11),
    darkgray:             Color.new(169, 169, 169),
    darkgreen:            Color.new(0, 100, 0),
    darkkhaki:            Color.new(189, 183, 107),
    darkmagenta:          Color.new(139, 0, 139),
    darkolivegreen:       Color.new(85, 107, 47),
    darkorange:           Color.new(255, 140, 0),
    darkorchid:           Color.new(153, 50, 204),
    darkred:              Color.new(139, 0, 0),
    darksalmon:           Color.new(233, 150, 122),
    darkseagreen:         Color.new(143, 188, 143),
    darkslateblue:        Color.new(72, 61, 139),
    darkslategray:        Color.new(47, 79, 79),
    darkturquoise:        Color.new(0, 206, 209),
    darkviolet:           Color.new(148, 0, 211),
    deeppink:             Color.new(255, 20, 147),
    deepskyblue:          Color.new(0, 191, 255),
    dimgray:              Color.new(105, 105, 105),
    dodgerblue:           Color.new(30, 144, 255),
    firebrick:            Color.new(178, 34, 34),
    floralwhite:          Color.new(255, 250, 240),
    forestgreen:          Color.new(34, 139, 34),
    fuchsia:              Color.new(255, 0, 255),
    gainsboro:            Color.new(220, 220, 220),
    ghostwhite:           Color.new(248, 248, 255),
    gold:                 Color.new(255, 215, 0),
    goldenrod:            Color.new(218, 165, 32),
    gray:                 Color.new(128, 128, 128),
    green:                Color.new(0, 128, 0),
    greenyellow:          Color.new(173, 255, 47),
    honeydew:             Color.new(240, 255, 240),
    hotpink:              Color.new(255, 105, 180),
    indianred:            Color.new(205, 92, 92),
    indigo:               Color.new(75, 0, 130),
    ivory:                Color.new(255, 255, 240),
    khaki:                Color.new(240, 230, 140),
    lavender:             Color.new(230, 230, 250),
    lavenderblush:        Color.new(255, 240, 245),
    lawngreen:            Color.new(124, 252, 0),
    lemonchiffon:         Color.new(255, 250, 205),
    lightblue:            Color.new(173, 216, 230),
    lightcoral:           Color.new(240, 128, 128),
    lightcyan:            Color.new(224, 255, 255),
    lightgoldenrodyellow: Color.new(250, 250, 210),
    lightgreen:           Color.new(144, 238, 144),
    lightgrey:            Color.new(211, 211, 211),
    lightpink:            Color.new(255, 182, 193),
    lightsalmon:          Color.new(255, 160, 122),
    lightseagreen:        Color.new(32, 178, 170),
    lightskyblue:         Color.new(135, 206, 250),
    lightslategray:       Color.new(119, 136, 153),
    lightsteelblue:       Color.new(176, 196, 222),
    lightyellow:          Color.new(255, 255, 224),
    lime:                 Color.new(0, 255, 0),
    limegreen:            Color.new(50, 205, 50),
    linen:                Color.new(250, 240, 230),
    magenta:              Color.new(255, 0, 255),
    maroon:               Color.new(128, 0, 0),
    mediumaquamarine:     Color.new(102, 205, 170),
    mediumblue:           Color.new(0, 0, 205),
    mediumorchid:         Color.new(186, 85, 211),
    mediumpurple:         Color.new(147, 112, 219),
    mediumseagreen:       Color.new(60, 179, 113),
    mediumslateblue:      Color.new(123, 104, 238),
    mediumspringgreen:    Color.new(0, 250, 154),
    mediumturquoise:      Color.new(72, 209, 204),
    mediumvioletred:      Color.new(199, 21, 133),
    midnightblue:         Color.new(25, 25, 112),
    mintcream:            Color.new(245, 255, 250),
    mistyrose:            Color.new(255, 228, 225),
    moccasin:             Color.new(255, 228, 181),
    navajowhite:          Color.new(255, 222, 173),
    navy:                 Color.new(0, 0, 128),
    oldlace:              Color.new(253, 245, 230),
    olive:                Color.new(128, 128, 0),
    olivedrab:            Color.new(107, 142, 35),
    orange:               Color.new(255, 165, 0),
    orangered:            Color.new(255, 69, 0),
    orchid:               Color.new(218, 112, 214),
    palegoldenrod:        Color.new(238, 232, 170),
    palegreen:            Color.new(152, 251, 152),
    paleturquoise:        Color.new(175, 238, 238),
    palevioletred:        Color.new(219, 112, 147),
    papayawhip:           Color.new(255, 239, 213),
    peachpuff:            Color.new(255, 218, 185),
    peru:                 Color.new(205, 133, 63),
    pink:                 Color.new(255, 192, 203),
    plum:                 Color.new(221, 160, 221),
    powderblue:           Color.new(176, 224, 230),
    purple:               Color.new(128, 0, 128),
    red:                  Color.new(255, 0, 0),
    rosybrown:            Color.new(188, 143, 143),
    royalblue:            Color.new(65, 105, 225),
    saddlebrown:          Color.new(139, 69, 19),
    salmon:               Color.new(250, 128, 114),
    sandybrown:           Color.new(244, 164, 96),
    seagreen:             Color.new(46, 139, 87),
    seashell:             Color.new(255, 245, 238),
    sienna:               Color.new(160, 82, 45),
    silver:               Color.new(192, 192, 192),
    skyblue:              Color.new(135, 206, 235),
    slateblue:            Color.new(106, 90, 205),
    slategray:            Color.new(112, 128, 144),
    snow:                 Color.new(255, 250, 250),
    springgreen:          Color.new(0, 255, 127),
    steelblue:            Color.new(70, 130, 180),
    tan:                  Color.new(210, 180, 140),
    teal:                 Color.new(0, 128, 128),
    thistle:              Color.new(216, 191, 216),
    tomato:               Color.new(255, 99, 71),
    turquoise:            Color.new(64, 224, 208),
    violet:               Color.new(238, 130, 238),
    wheat:                Color.new(245, 222, 179),
    white:                Color.new(255, 255, 255),
    whitesmoke:           Color.new(245, 245, 245),
    yellow:               Color.new(255, 255, 0),
    yellowgreen:          Color.new(154, 205, 50),
  }
  COLORS.default_proc = -> h, k { h[k] = hex_code(k.to_s) || Color.new }

  module_function

  # 用颜色代码获取颜色
  def hex_code(code)
    case code.size
    when 3, 4
      Color.new(*code.each_char.map { |c| c.hex * 0x11 })
    when 6, 8
      Color.new(*code.scan(/../).map(&:hex))
    end
  end

  def windowskin
    Cache.system("Window")
  end

  def text_color(n)
    windowskin.get_pixel(64 + (n % 8) * 8, 96 + (n / 8) * 8)
  end

  def normal_color;      text_color(0);   end;
  def system_color;      text_color(16);  end;
  def crisis_color;      text_color(17);  end;
  def knockout_color;    text_color(18);  end;
  def gauge_back_color;  text_color(19);  end;
  def hp_gauge_color1;   text_color(20);  end;
  def hp_gauge_color2;   text_color(21);  end;
  def mp_gauge_color1;   text_color(22);  end;
  def mp_gauge_color2;   text_color(23);  end;
  def mp_cost_color;     text_color(23);  end;
  def power_up_color;    text_color(24);  end;
  def power_down_color;  text_color(25);  end;
  def tp_gauge_color1;   text_color(28);  end;
  def tp_gauge_color2;   text_color(29);  end;
  def tp_cost_color;     text_color(29);  end;
  32.times { |i| COLORS[:"#{i}"] = text_color(i) }
end

class Window_Base
  def_chain :process_escape_character do |old, code, text, pos|
    if code.casecmp('C').zero?
      sym = text.slice!(/^\[\w+]/i)[1..-2].downcase.to_sym
      change_color Taroxd::ColorExt::COLORS[sym]
    else
      old.call(code, text, pos)
    end
  end
end