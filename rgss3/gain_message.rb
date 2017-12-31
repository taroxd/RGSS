# @taroxd metadata 1.0
# @id gain_message
# @require taroxd_core
# @display 得失物品提示

module Taroxd::GainMessage

  # 信息格式

  # 转义符：
  # \name    代表物品名称 / 金钱单位
  # \value   代表获得 / 失去的物品 / 金钱数量
  # \icon    绘制物品 / 金钱的图标
  # \action  代表“获得”或者“失去”。可在下面修改。
  # 支持“显示文字”中的所有转义符。
  ITEM_FORMAT  = '\action了 \name * \value'
  GOLD_FORMAT  = '\action了 \value \name'
  ACTION_GAIN  = '获得'
  ACTION_LOSE  = '失去'
  GOLD_ICON_INDEX = 361           # 金钱图标的索引

  BACKGROUND   = 1                # 窗口背景（0/1/2）
  POSITION     = 1                # 显示位置（0/1/2）

  # 音效（不需要的话可以直接删去对应的行）
  GAIN_GOLD_SE = 'Shop'           # 获得金钱
  LOSE_GOLD_SE = 'Blow2'          # 失去金钱
  GAIN_ITEM_SE = 'Item1'          # 获得物品
  LOSE_ITEM_SE = LOSE_GOLD_SE     # 失去物品

  # 功能是否启用。
  def self.enabled?
    true
  end

  # 显示提示信息。获得金钱时将 item 设为 nil。
  def self.show(value, item)
    @item = item
    @value = value
    $game_message.background = BACKGROUND
    $game_message.position = POSITION
    $game_message.add(message)
    play_se
  end

  private

  # 获取提示的消息
  def self.message
    if @item
      format = ITEM_FORMAT
      icon_index = @item.icon_index
      name = @item.name
    else
      format = GOLD_FORMAT
      icon_index = GOLD_ICON_INDEX
      name = Vocab.currency_unit
    end

    gsub = {
      '\action' => @value > 0 ? ACTION_GAIN : ACTION_LOSE,
      '\value'  => @value.abs,
      '\icon'   => "\\I[#{icon_index}]",
      '\name'   => name
    }

    format.gsub(Regexp.union(gsub.keys), gsub)
  end

  def self.play_se
    const = :"#{@value > 0 ? 'GAIN' : 'LOSE'}_#{@item ? 'ITEM' : 'GOLD'}_SE"
    se = const_defined?(const) && const_get(const)
    Audio.se_play('Audio/SE/' + se) if se
  end
end

class Game_Party < Game_Unit
  # 获取道具总数（包括装备）
  def item_number_with_equip(item)
    members.inject(item_number(item)) { |a, e| a + e.equips.count(item) }
  end
end

class Game_Interpreter

  GainMessage = Taroxd::GainMessage

  # 显示提示窗口
  def show_gain_message(value, item = nil)
    return if value.zero?
    GainMessage.show(value, item)
    wait_for_message
  end

  # 增减金钱
  def_chain :command_125 do |old|
    return old.call unless GainMessage.enabled?
    last_gold = $game_party.gold
    old.call
    show_gain_message($game_party.gold - last_gold)
  end

  # 增减物品
  def_chain :command_126 do |old|
    return old.call unless GainMessage.enabled?
    item = $data_items[@params[0]]
    last_num = $game_party.item_number(item)
    old.call
    show_gain_message($game_party.item_number(item) - last_num, item)
  end

  # 增减武器
  def_chain :command_127 do |old|
    return old.call unless GainMessage.enabled?
    item = $data_weapons[@params[0]]
    last_num = $game_party.item_number_with_equip(item)
    old.call
    value = $game_party.item_number_with_equip(item) - last_num
    show_gain_message(value, item)
  end

  # 增减护甲
  def_chain :command_128 do |old|
    return old.call unless GainMessage.enabled?
    item = $data_armors[@params[0]]
    last_num = $game_party.item_number_with_equip(item)
    old.call
    value = $game_party.item_number_with_equip(item) - last_num
    show_gain_message(value, item)
  end
end

class Taroxd::EventTranscompiler
  def command_125
    value = operate_value(@params[1], @params[2], @params[3])
    "if GainMessage.enabled?
      @params = $game_party.item_number(item)
      $game_party.gain_gold(#{value})
      show_gain_message($game_party.gold - @params)
    else
      $game_party.gain_gold(#{value})
    end"
  end

  # database: :items, :weapons, :equips
  def show_message_gain_item(database)
    item_number = database == :item ? :item_number : :item_number_with_equip
    value = operate_value(@params[1], @params[2], @params[3])
    item = "$data_#{database}[#{@params[0]}]"
    "if GainMessage.enabled?
      @params = $game_party.#{item_number}(#{item})
      $game_party.gain_item(#{item}, #{value}, #{@params[4]})
      show_gain_message($game_party.#{item_number}(#{item}) - @params, #{item})
    else
      $game_party.gain_item(#{item}, #{value}, #{@params[4]})
    end"
  end

  def command_126
    show_message_gain_item(:items)
  end

  def command_127
    show_message_gain_item(:weapons)
  end

  def command_128
    show_message_gain_item(:armors)
  end
end if Taroxd.const_defined?(:EventTranscompiler)
