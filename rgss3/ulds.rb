# @taroxd metadata 1.0
# @require taroxd_core
# @display 无限图层显示系统
# @id ulds
# @help
#
#  使用方法：导入此脚本后，在地图上备注如下内容。
#
#  <ulds=filename>
#    x: X坐标
#      公式，默认为 0
#    y: Y坐标
#      公式，默认为 0
#    z: Z坐标
#      公式，只计算一次，默认为 10，可以设置为 -100 来当作远景图使用
#    zoom: 缩放倍率
#      公式，默认为 1。缩放的原点为画面左上角。
#    zoom_x: 横向缩放倍率
#      公式，默认为 zoom
#    zoom_y: 纵向缩放倍率
#      公式，默认为 zoom
#    opacity: 不透明度
#      公式，默认为 255
#    blend_type: 合成方式
#      公式，只计算一次。默认为 0 （0：正常、1：加法、2：减法）
#    scroll: 图像跟随地图卷动的速度
#      实数，默认为 32
#    scroll_x: 图像跟随地图横向卷动的速度
#      实数，默认为 scroll
#    scroll_y：图像跟随地图纵向卷动的速度
#      实数，默认为 scroll
#    loop: 循环
#      冒号后面不需要填写任何东西。
#    visible: 图像是否显示
#      公式，默认为 true
#    path: 图像的路径名
#      默认为 Parallaxes
#    color: 合成的颜色
#      公式，只计算一次。默认为 Color.new(0, 0, 0, 0)
#    tone: 色调
#      公式，只计算一次。默认为 Tone.new(0, 0, 0, 0)
#    eval: 初始化后，以 sprite 或 plane 为 self 执行的代码。
#      公式，默认为空
#    update: 图片显示时，每帧执行的更新代码
#      公式，默认为 t += 1
#    dispose: 图片释放前执行的代码
#      公式，默认为空
#  </ulds>
#
#  其中 filename 是图片文件名（无需扩展名），放入 Parallaxes 文件夹内
#  这个文件夹可以通过 path 设置更改
#
#  在 <ulds=filename> 和 </ulds> 中间的部分均为选填。不填则自动设为默认值。
#  每一个设置项只能写一行。（地图备注没有单行长度限制）
#  每一行只能写一个设置项。
#  一般来说，正常使用时大部分都是不需要设置的。
#
#  设置项目中的“公式”表示，这一个设置项可以像技能的伤害公式一样填写。
#  “只计算一次”表示，该公式只会在刚刚进入地图时计算一次，之后不会更新。
#  可用 t 表示当前已经显示的帧数，s[n], v[n] 分别表示 n 号开关和 n 号变量。
#  width 表示图片宽度，height 表示图片高度。
#
#  例：
#   <ulds=BlueSky>
#     x: t
#     scroll_x: 16
#     scroll_y: 64
#     loop:
#   </ulds>
#
#  需要多行公式时，可以重复备注。
#  例：
#   <ulds=Slime>
#     path: Battlers
#     x: width / 2
#     y: height / 2
#     eval: self.ox = width / 2
#     eval: self.oy = height / 2
#     eval: self.angle = 180
#   </ulds>


module Taroxd::ULDS

  DEFAULT_PATH = 'Parallaxes'                    # 图片文件的默认路径
  DEFAULT_Z = 10                                 # 默认的 z 值
  RE_OUTER = /<ulds[= ]?(.*?)>(.*?)<\/ulds>/mi  # 读取备注用的正则表达式
  RE_INNER = /(\w+) *: *(.*)/                    # 读取设置用的正则表达式

  module Base
    include Math

    attr_accessor :scroll_x, :scroll_y

    def dispose
      bitmap.dispose if bitmap
      super
    end

    def adjust_x(x)
      return x if !@scroll_x || @scroll_x.abs < Float::EPSILON
      $game_map.adjust_x(x.fdiv(@scroll_x)) * @scroll_x
    end

    def adjust_y(y)
      return y if !@scroll_y || @scroll_y.abs < Float::EPSILON
      $game_map.adjust_y(y.fdiv(@scroll_y)) * @scroll_y
    end
  end

  class Sprite < ::Sprite
    include Base

    def x=(x)
      super(adjust_x(x))
    end

    def y=(y)
      super(adjust_y(y))
    end
  end

  class Plane < ::Plane
    include Base

    attr_reader :visible

    def initialize(_)
      super
      @visible = true
    end

    def x=(x)
      self.ox = -adjust_x(x)
    end

    def y=(y)
      self.oy = -adjust_y(y)
    end

    def visible=(visible)
      super
      @visible = visible
    end

    def width
      bitmap.width
    end

    def height
      bitmap.height
    end
  end

  class << self

    # 从备注中读取设置，并生成数组
    def from_note(note, viewport)
      note.scan(RE_OUTER).map do |name, contents|
        settings = {nil => name}
        contents.scan(RE_INNER) do |key, value|
          (settings[key] ||= '') << value << "\n"
        end
        new(settings, viewport)
      end
    end

    # 返回一个 ULDS::Sprite 或 ULDS::Plane 的实例
    def new(settings, viewport)
      @settings = settings
      container(viewport)
    end

    private

    def container(viewport)
      (extract('loop') ? Plane : Sprite).new(viewport).tap do |container|
        container.bitmap = make_bitmap
        container.instance_eval(init_container_code, __FILE__, __LINE__)
      end
    end

    # 在一个 sprite 或 plane 的上下文中执行的代码。
    # 如果难以理解，请尝试输出这段代码来查看。
    def init_container_code
      "#{binding_code}
      #{init_attr_code}
      #{define_update_code}
      #{define_dispose_code}
      #{extract 'eval'}"
    end

    # 定义变量的代码
    def binding_code
      's = $game_switches
      v = $game_variables
      t = 0'
    end

    # 只计算一次的初始化代码
    def init_attr_code
      "#{set_attr_code 'z', DEFAULT_Z}
      #{set_attr_code 'scroll_x', 32}
      #{set_attr_code 'scroll_y', 32}
      #{set_attr_code 'blend_type'}
      #{set_attr_code 'color'}
      #{set_attr_code 'tone'}"
    end

    # 更新的代码
    def define_update_code
      %{
        define_singleton_method :update do
          #{set_attr_code 'visible'}
          return unless visible
          #{set_attr_code 'zoom_x'}
          #{set_attr_code 'zoom_y'}
          #{set_attr_code 'opacity'}
          #{set_attr_code 'x', 0}
          #{set_attr_code 'y', 0}
          #{set_t_code}
        end
      }
    end

    def define_dispose_code
      code = extract('dispose')
      !code ? "" : %{
        define_singleton_method :dispose do
          #{code}
          super()
        end
      }
    end

    # 设置属性的代码
    def set_attr_code(key, default = nil)
      formula = extract(key, default)
      formula && "self.#{key} = (#{formula})"
    end

    # 设置时间的代码
    def set_t_code
      extract('update', 't += 1')
    end

    # 获得位图
    def make_bitmap
      basename = extract(nil)
      if !basename.empty?
        folder_name = "Graphics/#{extract('path', DEFAULT_PATH).chomp}"
        Bitmap.new("#{folder_name}/#{basename}")
      else
        nil
      end
    end

    # 获取备注中的设定值
    def extract(key, default = nil)
      @settings[key] || /(.+)_[xy]\Z/ =~ key && @settings[$1] || default
    end
  end
end

class Spriteset_Map

  private

  def create_ulds
    @ulds = Taroxd::ULDS.from_note($game_map.note, @viewport1)
    @ulds_map_id = $game_map.map_id
  end

  def refresh_ulds
    dispose_ulds
    create_ulds
  end

  def update_ulds
    refresh_ulds if @ulds_map_id != $game_map.map_id
    @ulds.each(&:update)
  end

  def dispose_ulds
    @ulds.each(&:dispose)
  end

  def_before :create_parallax,  :create_ulds
  def_before :update_parallax,  :update_ulds
  def_before :dispose_parallax, :dispose_ulds
end
