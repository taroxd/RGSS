# @taroxd metadata 1.0
# @id fast_forward
# @display 快进游戏
# @help
#    Taroxd::FastForward.call(frame, *keys)
#      跳过 frame 帧。keys 为这 frame 帧按下的按键。
#      每一帧都视为重新按下按键。
#
#    示例：
#      Taroxd::FastForward.call(999, :C)
#        跳过 999 帧。每帧都视为重新按下确定键。

module Taroxd

  dirs = {DOWN: 2, LEFT: 4, RIGHT: 6, UP: 8}

  # 获取 dir4, dir8。
  dir_4_8 = lambda do |keys|
    dir8 = dirs.inject(5) do |dir, (key, value)|
      keys.include?(key) ? dir + value - 5 : dir
    end

    return 0, 0 if dir8 == 5
    return dir8, dir8 if [2, 4, 6, 8].include?(dir8)
    keys.reverse_each { |key| return dirs[key], dir8 if dirs[key] }
    [0, 0] # 理论上不会执行
  end

  FastForward = lambda do |frame, *keys|
    # 保留原方法的哈希表
    # 方法名（Symbol）为键，method 对象为值
    graphics_methods = {}
    input_methods = {}

    # 重定义 Graphics 的方法
    define_graphics_method = lambda do |name, &block|
      graphics_methods[name] = Graphics.method(name)
      Graphics.define_singleton_method(name, block)
    end

    # 重定义 Input 的方法
    define_input_method = lambda do |name, &block|
      input_methods[name] = Input.method(name)
      Input.define_singleton_method(name, block)
    end

    # 将方法恢复到原先的状态
    restore = lambda do
      input_methods.each do |name, method|
        Input.define_singleton_method(name, method)
      end
      graphics_methods.each do |name, method|
        Graphics.define_singleton_method(name, method)
      end
    end

    # 重定义 dir4, dir8 方法。value：方法的返回值
    define_dir_method = lambda do |name, value|
      define_input_method.call(name) { value } unless value == 5
    end

    # 重定义持续一段时间的 Graphics 模块方法。effect：该方法的副作用
    define_duration_method = lambda do |name, &effect|
      define_graphics_method.call name do |*args|
        duration = args.first || 1
        if frame < duration
          restore.call
          send name, *args
        else
          frame -= duration
          effect.call(*args) if effect
          nil
        end
      end
    end

    unless keys.empty?
      [:trigger?, :press?, :repeat?].each do |name|
        define_input_method.call(name) { |key| keys.include?(key) }
      end
    end

    dir4, dir8 = dir_4_8.call(keys)
    define_dir_method.call(:dir4, dir4)
    define_dir_method.call(:dir8, dir8)
    define_graphics_method.call(:freeze) {}
    define_duration_method.call :update
    define_duration_method.call :wait
    define_duration_method.call(:fadeout) { self.brightness = 0 }
    define_duration_method.call(:fadein) { self.brightness = 255 }
    define_duration_method.call :transition do
      graphics_methods[:transition].call(0)
    end
  end
end
