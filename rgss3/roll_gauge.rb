# @taroxd metadata 1.0
# @display 动态值槽
# @require taroxd_core
# @id roll_gauge
# @help 给值槽增加动态的滚动效果

class Taroxd::Transition

  # value: 当前值。changing: 当前是否正在变化
  attr_reader :value, :changing

  # get_target.call 获取到变化的数据。可以使用 block 代替 get_target。
  def initialize(duration, get_target = nil, &block)
    @duration = duration
    @get_target = get_target || block
    @value = @target = @get_target.call
    @d = 0
  end

  # 更新值槽的值。如果值槽发生变化，返回 true。
  def update
    @target = @get_target.call
    @changing = @value != @target
    update_transition if @changing
    @changing
  end

  private

  def update_transition
    @d = @duration if @d.zero?
    @d -= 1
    @value = if @d.zero?
      @target
    else
      (@value * @d + @target).fdiv(@d + 1)
    end
  end
end

# include 之后，可用 @gauge_transitions[actor][:hp] 等
# 获取 Taroxd::Transition 的实例。
module Taroxd::RollGauge

  Transition = Taroxd::Transition

  def initialize(*)
    @gauge_transitions = make_gauge_transitions
    @gauge_roll_count = 0
    super
  end

  def update
    super
    if (@gauge_roll_count += 1) >= gauge_roll_interval
      roll_all_gauge if update_gauge_transitions && visible
      @gauge_roll_count = 0
    end
  end

  def draw_actor_hp(actor, x, y, width = 124)
    hp = @gauge_transitions[actor][:hp].value
    rate = hp.fdiv(actor.mhp)
    draw_gauge(x, y, width, rate, hp_gauge_color1, hp_gauge_color2)
    change_color(system_color)
    draw_text(x, y, 30, line_height, Vocab::hp_a)
    draw_current_and_max_values(x, y, width, hp.to_i, actor.mhp,
      hp_color(actor), normal_color)
  end

  def draw_actor_mp(actor, x, y, width = 124)
    mp = @gauge_transitions[actor][:mp].value
    mmp = actor.mmp
    rate = mmp.zero? ? 0 : mp.fdiv(actor.mmp)
    draw_gauge(x, y, width, rate, mp_gauge_color1, mp_gauge_color2)
    change_color(system_color)
    draw_text(x, y, 30, line_height, Vocab::mp_a)
    draw_current_and_max_values(x, y, width, mp.to_i, actor.mmp,
      mp_color(actor), normal_color)
  end

  def draw_actor_tp(actor, x, y, width = 124)
    tp = @gauge_transitions[actor][:tp].value
    rate = tp.fdiv(actor.max_tp)
    draw_gauge(x, y, width, rate, tp_gauge_color1, tp_gauge_color2)
    change_color(system_color)
    draw_text(x, y, 30, line_height, Vocab::tp_a)
    change_color(tp_color(actor))
    draw_text(x + width - 42, y, 42, line_height, tp.to_i, 2)
  end

  private

  # 获取 make_gauge_transitions 生成的对象
  attr_reader :gauge_transitions

  # 值槽滚动所需的帧数
  def gauge_roll_frame
    30
  end

  # 每隔多少帧更新一次值槽
  def gauge_roll_interval
    1
  end

  # 生成值槽变化的数据。可在子类重定义。
  # 默认的定义中，可以通过 gauge_transitions[actor][:hp] 等方式获取数据。
  def make_gauge_transitions
    Hash.new { |hash, actor|
      hash[actor] = Hash.new do |h, k|
        h[k] = Transition.new(gauge_roll_times, actor.method(k))
      end
    }.compare_by_identity
  end

  # 更新渐变的值。
  # 返回真值则触发一次刷新。
  # 每 gauge_roll_interval 帧调用一次。
  def update_gauge_transitions
    need_roll = false
    gauge_transitions.each_value do |hash|
      hash.each_value do |t|
        need_roll = true if t.update
      end
    end
    need_roll
  end

  # 值槽滚动所需的次数。
  def gauge_roll_times
    gauge_roll_frame / gauge_roll_interval
  end

  # 滚动所有值槽。可在子类重定义。
  def roll_all_gauge
    refresh
  end
end

class Window_BattleStatus
  include Taroxd::RollGauge
end

class Window_MenuStatus < Window_Selectable

  include Taroxd::RollGauge

  def roll_all_gauge
    item_max.times do |i|
      actor = $game_party.members[i]
      rect = item_rect(i)
      rect.x += 108
      rect.y += line_height / 2
      contents.clear_rect(rect)
      draw_actor_simple_status(actor, rect.x, rect.y)
    end
  end
end
