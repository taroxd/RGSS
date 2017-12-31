# @taroxd metadata 1.0
# @display 事件转译器嵌入
# @require event_transcompiler
# @id event_transcompiler_integration

class Taroxd::EventTranscompiler

  # 是否需要与旧存档兼容。不是新工程的话填 true。
  SAVEDATA_COMPATIBLE = false

  # 读档时是否重新执行事件。（暂不支持从中断处开始。因此建议不要在事件执行时存档）
  # true 表示读档时从头开始执行事件，false 表示读档时丢弃执行中的事件。
  # 该选项仅当 SAVEDATA_COMPATIBLE 为 false 时有效。
  RUN_ON_LOAD = false

  # 调试模式，开启时会将转译的脚本输出到控制台
  DEBUG = false

  @cache = {}

  class << self
    attr_reader :cache
  end
end

class Game_Interpreter

  EventTranscompiler = Taroxd::EventTranscompiler

  def run
    wait_for_message
    instance_eval(&compile_code)
    Fiber.yield
    @fiber = nil
  end

  unless EventTranscompiler::SAVEDATA_COMPATIBLE

    def marshal_dump
      [@map_id, @event_id, @list]
    end

    def marshal_load(obj)
      @map_id, @event_id, @list = obj
      create_fiber if EventTranscompiler::RUN_ON_LOAD
    end
  end # unless EventTranscompiler::SAVEDATA_COMPATIBLE

  private

  def rb_code
    EventTranscompiler.transcompile(@list, @map_id, @event_id)
  end

  def transcompiler_binding
    binding
  end

  def transcompiler_cache_key
    "#{@map_id}-#{@event_id}-#{@list.__id__}"
  end

  if $TEST && EventTranscompiler::DEBUG

    def compile_code
      proc = EventTranscompiler.cache[transcompiler_cache_key]
      return proc if proc
      code = rb_code
      puts code
      EventTranscompiler.cache[transcompiler_cache_key] =
        eval(code, transcompiler_binding)
    rescue StandardError, SyntaxError => e
      p e
      puts e.backtrace
      rgss_stop
    end

  else

    def compile_code
      EventTranscompiler.cache[transcompiler_cache_key] ||=
        eval(rb_code, transcompiler_binding)
    end

  end # if $TEST && EventTranscompiler::DEBUG
end

# 切换地图时，清除事件页转译代码的缓存

class Game_Map

  alias_method :setup_without_transcompiler, :setup

  def setup(map_id)
    setup_without_transcompiler(map_id)
    Taroxd::EventTranscompiler.cache.clear
  end
end
