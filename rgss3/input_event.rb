# @taroxd metadata 1.0
# @require taroxd_core
# @display 按键事件
# @id input_event

class << Taroxd::InputEvent = Module.new
  attr_accessor :event # 当前事件，作用类似于全局变量
end

class Taroxd::InputEvent::Base
  # 各属性与默认值列表
  @options = {}
  @option_blocks = {}

  # 事件是否成功
  attr_accessor :result

  # 建立简单的事件，返回事件的结果
  def self.main(*args)
    Taroxd::InputEvent.event = event = new(*args)
    event.main
    Taroxd::InputEvent.event = nil
    event.result
  end

  # option opt1: default1, opt2: default2, ...
  # option(:opt) { |option_name| value }
  #
  # 定义属性。
  # 该属性会在实例生成时定义一个名称对应的实例变量，值为默认的值。
  # 在调用可以通过 InputEvent.new(option: value) 的形式进行覆盖。
  # 该方法包含了 attr_reader 的效果。
  def self.option(name_pair, &block)
    if block
      attr_reader name_pair
      option_blocks[name_pair] = block
    else
      attr_reader(*name_pair.keys)
      options.merge!(name_pair)
    end
  end

  # 获取属性列表（默认值）
  def self.options
    @options ||= superclass.options.dup
  end

  # 获取属性列表（default_proc）
  def self.option_blocks
    @option_blocks ||= superclass.option_blocks
  end

  # 要按下的键
  option key: :C

  # 值槽被填充的比例
  option rate: 0

  # 是否显示
  option visible: true

  # 显示位置（当然，你一定想要重定义）
  option x: 0, y: 0, z: 0, width: Graphics.width, height: Graphics.height

  # 值槽方向
  option vertical: false

  # 填充颜色
  option color: Color.new(255, 255, 255)

  # InputEventClass.new([opt1: value1, opt2: value2, ... ]) -> event
  #
  # 生成实例。可选的 options 参数可以覆盖默认的设置。
  def initialize(options = {})
    self.class.options.each do |name, default|
      instance_variable_set :"@#{name}", options.fetch(name, default)
    end

    self.class.option_blocks.each do |name, default|
      instance_variable_set :"@#{name}", options.fetch(name, &default)
    end
  end

  # 暂时以该事件的主逻辑代替场景
  def main
    update_scene while update
  end

  # 更新事件。如果事件结束，返回 false，否则返回 true。
  def update
    hit? ? on_hit : on_not_hit
    update_common
    @result.nil?
  end

  private

  # 事件调用 main 时，更新场景的方式。
  def update_scene
    SceneManager.scene.update_for_input_event
  end

  # 是否按下按键。
  def hit?
    Input.trigger?(key)
  end

  # 更新方式。在子类定义。
  def on_hit; end
  alias_method :on_not_hit, :on_hit
  alias_method :update_common, :on_hit

  # 终止事件，并返回结果。
  alias_method :terminate, :result=
end

class Taroxd::InputEvent::Sprite < Sprite

  include Taroxd::DisposeBitmap

  # 更新
  def update
    update_event_change
    update_property if @event
  end

  private

  # 获取当前事件
  def event
    Taroxd::InputEvent.event
  end

  # 判断事件改变
  def update_event_change
    return if @event.equal?(event)
    @event = event
    update_bitmap
  end

  # 事件改变时的刷新
  def update_bitmap
    bitmap.dispose if bitmap
    return unless @event
    self.bitmap = Bitmap.new(width, height)
    bitmap.fill_rect(0, 0, width, height, @event.color)
  end

  # 更新属性
  def update_property
    self.visible = @event.visible
    update_position
    update_src_rect
  end

  # 更新位置
  def update_position
    self.x = @event.x
    self.y = @event.y
    self.z = @event.z
  end

  # 更新值槽
  def update_src_rect
    if @event.vertical
      src_rect.y = height * (1 - rate)
      src_rect.height = height * rate
    else
      src_rect.width = width * rate
    end
  end

  # 总宽度。覆盖了父类的方法！
  def width
    @event.width
  end

  # 总高度
  def height
    @event.height
  end

  # 值槽填充程度
  def rate
    @event.rate
  end
end

class Scene_Base
  # 对事件调用 main 时，场景的更新方式
  def update_for_input_event
    update_basic
  end
end

class Scene_Map < Scene_Base
  # 对事件调用 main 时，场景的更新方式
  def update_for_input_event
    update_basic
    @spriteset.update
  end
end

# 导入 Spriteset_Map
Spriteset_Map.use_sprite(Taroxd::InputEvent::Sprite) { @viewport2 }
