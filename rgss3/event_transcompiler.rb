# @taroxd metadata 1.0
# @display 事件转译器
# @id event_transcompiler

module Taroxd end

class Taroxd::EventTranscompiler

  # 字符串中嵌入脚本的格式：<%= code %>
  EMBED_RE = /<%=(.+?)%>/m

  # 翻译事件指令代码。
  # 代理给实例的 transcompile 方法。
  def self.transcompile(*args)
    new(*args).transcompile
  end

  # list：事件指令列表
  def initialize(list, map_id, event_id)
    @list = list
    @map_id = map_id
    @event_id = event_id
    @index = -1
  end

  # 翻译事件指令代码，并放入 lambda 中，以便于 return 返回。
  # lambda 的参数为当前执行事件指令的 interpreter。
  # 该 lambda 应该由 interpreter.instance_eval 执行。
  def transcompile
    "lambda do |_|
      #{transcompile_code}
    end"
  end

  protected

  # 将事件指令翻译成代码
  def transcompile_code
    ret = ''
    ret << transcompile_command << "\n" while next_command!
    ret
  end

  private

  def transcompile_command(command = @command)
    @params = command.parameters
    sym = :"command_#{@command.code}"
    respond_to?(sym, true) && send(sym) || ''
  end

  # 分支。
  # 方法开始时，@index 应位于分支开始之前的位置
  # 方法结束后，@index 将位于分支结束之后的位置
  def transcompile_branch
    indent = current_indent
    ret = ''
    until next_command!.indent == indent
      ret << transcompile_command << "\n"
    end
    ret
  end

  def current_command
    @list[@index]
  end

  def current_params
    current_command.parameters
  end

  def current_indent
    current_command.indent
  end

  def current_code
    current_command.code
  end

  def next_command
    @list[@index + 1]
  end

  def next_command!
    @index += 1
    @command = @list[@index]
  end

  def next_params!
    next_command!.parameters
  end

  def next_code
    next_command.code
  end

  # 返回脚本中的表达形式。obj 可以为字符串或数组。
  def escape(obj)
    obj.kind_of?(String) ? escape_str(obj) : obj.inspect
  end

  # 字符串中的 <%= code %> 会被替换为 #{code}
  # 脚本内容不会被 escape。
  def escape_str(str)
    codes = str.scan(EMBED_RE)  # 原来的脚本
    index = -1
    str.inspect.gsub(EMBED_RE) { "\#{#{codes[index += 1][0]}}" }
  end

  # helper

  # 在战斗中不执行
  def only_map(code)
    "unless $game_party.in_battle
      #{code}
    end\n"
  end

  def same_map?
    "$game_map.map_id == #{@map_id}"
  end

  def setup_choices(params)
    ret = ''
    params[0].each do |s|
      ret << "$game_message.choices.push(#{escape s})\n"
    end
    ret << "$game_message.choice_cancel_type = #{params[1]}
    $game_message.choice_proc = Proc.new { |n| @params = n }
    Fiber.yield while $game_message.choice?
    case @params
    "
    next_command!
    until current_code == 404 # 选项结束
      # 取消的场合为 4，否则为对应选项
      n = current_code == 403 ? 4 : current_params[0]
      ret << "when #{n}\n" << transcompile_branch << "\n"
    end
    ret << "end" # end case
  end

  def setup_num_input(params)
    "$game_message.num_input_variable_id = #{params[0]}
    $game_message.num_input_digits_max = #{params[1]}"
  end

  def setup_item_choice(params)
    "$game_message.item_choice_variable_id = #{params[0]}"
  end

  def wait(duration)
    "#{duration}.times { Fiber.yield }"
  end

  def wait_for_message
    'Fiber.yield while $game_message.busy?'
  end

  def operate_value(operation, operand_type, operand)
    value = operand_type == 0 ? operand : "$game_variables[#{operand}]"
    "#{'-' if operation == 1}#{value}"
  end

  def iter_actor_id(param)
    if param.equal?(0)
      "$game_party.members.each do |actor|
        #{yield 'actor'}
      end"
    else
      "$game_actors[#{param}].tap do |actor|
        if actor
          #{yield 'actor'}
        end
      end"
    end
  end

  def iter_actor_var(param1, param2, &block)
    if param1 == 0
      iter_actor_id(param2, &block)
    else
      iter_actor_id("$game_variables[#{param2}]", &block)
    end
  end

  def iter_enemy_index(param)
    if param < 0
      "$game_troop.members.each do |enemy|
        #{yield 'enemy'}
      end"
    else
      "$game_troop.members[#{param}].tap do |enemy|
        if enemy
          #{yield 'enemy'}
        end
      end"
    end
  end

  def iter_battler(param1, param2, &block)
    "if $game_party.in_battle
      #{
        if param1 == 0
          iter_enemy_index(param2, &block)
        else
          iter_actor_id(param2, &block)
        end
      }
    end"
  end

  # 指令
  # 请对照 Game_Interpreter 的定义阅读。

  # 空指令
  def command_0
    'nil'
  end

  # 显示文字
  def command_101
    ret = "
    #{wait_for_message}
    $game_message.face_name = #{escape @params[0]}
    $game_message.face_index = #{@params[1]}
    $game_message.background = #{@params[2]}
    $game_message.position = #{@params[3]}
    "
    while next_code == 401 # 文字数据
      ret << "$game_message.add(#{escape next_params![0]})\n"
    end
    ret << case next_code
    when 102  # 显示选项
      setup_choices(next_params!)
    when 103  # 数值输入的处理
      "#{setup_num_input(next_params!)}
      Fiber.yield while $game_message.num_input?"
    when 104  # 物品选择的处理
      "#{setup_item_choice(next_params!)}
      Fiber.yield while $game_message.item_choice?"
    else
      wait_for_message
    end
  end

  # 显示选项
  def command_102
    "#{wait_for_message}
    #{setup_choices(@params)}"
  end

  # 数值输入的处理
  def command_103
    "#{wait_for_message}
    #{setup_num_input(@params)}
    Fiber.yield while $game_message.num_input?"
  end

  # 物品选择的处理
  def command_104
    "#{wait_for_message}
    #{setup_item_choice(@params)}
    Fiber.yield while $game_message.item_choice?"
  end

  # 显示滚动文字
  def command_105
    ret = "
    Fiber.yield while $game_message.visible
    $game_message.scroll_mode = true
    $game_message.scroll_speed = #{@params[0]}
    $game_message.scroll_no_fast = #{@params[1]}
    "
    while next_code == 405
      ret << "$game_message.add(#{escape next_params![0]})\n"
    end
    ret << wait_for_message
  end

  # 分支条件
  def command_111
    result = case @params[0]
    when 0  # 开关
      "#{'!' if @params[2] == 1}$game_switches[#{@params[1]}]"
    when 1  # 变量
      value1 = "$game_variables[#{@params[1]}]"
      value2 = if @params[2] == 0
        @params[3]
      else
        "$game_variables[#{@params[3]}]"
      end
      op = case @params[4]
      when 0 then '==' # 等于
      when 1 then '>=' # 以上
      when 2 then '<=' # 以下
      when 3 then '>'  # 大于
      when 4 then '<'  # 小于
      when 5 then '!=' # 不等于
      end
      "#{value1} #{op} #{value2}"
    when 2  # 独立开关
      if @event_id > 0
        "#{'!' if @params[2] != 0}"\
        "$game_self_switches[[#{@map_id}, #{@event_id}, "\
        "#{escape @params[1]}]]"
      else
        'false'
      end
    when 3  # 计时器
      op = @params[2] == 0 ? '>=' : '<='
      "$game_timer.working? && $game_timer.sec #{op} #{@params[1]}"
    when 4  # 角色
      "begin
        @params = $game_actors[#{@params[1]}]
        if @params
      " << case @params[2]
      when 0  # 在队伍时
        '$game_party.members.include?(@params)'
      when 1  # 名字
        "@params.name == #{escape @params[3]}"
      when 2  # 职业
        "@params.class_id == #{@params[3]}"
      when 3  # 技能
        "@params.skill_learn?($data_skills[#{@params[3]}])"
      when 4  # 武器
        "@params.weapons.include?($data_weapons[#{@params[3]}])"
      when 5  # 护甲
        "@params.armors.include?($data_armors[#{@params[3]}])"
      when 6  # 状态
        "@params.state?(#{@params[3]})"
      end << "\nend\nend" # if @params; begin
    when 5  # 敌人
      "begin
        @params = $game_troop.members[#{@params[1]}]
        if @params
      " << case @params[2]
      when 0  # 出现
        '@params.alive?'
      when 1  # 状态
        "@params.state?(#{@params[3]})"
      end << "\nend\nend" # if @params; begin
    when 6  # 事件
      "begin
        @params = get_character(#{@params[1]})
        if @params
          @params.direction == #{@params[2]}
        end
      end"
    when 7  # 金钱
      op = case @params[2]
      when 0 then '>=' # 以上
      when 1 then '<=' # 以下
      when 2 then '<'  # 低于
      end
      "$game_party.gold #{op} #{@params[1]}"
    when 8   # 物品
      "$game_party.has_item?($data_items[#{@params[1]}])"
    when 9   # 武器
      "$game_party.has_item?($data_weapons[#{@params[1]}], #{@params[2]})"
    when 10  # 护甲
      "$game_party.has_item?($data_armors[#{@params[1]}], #{@params[2]})"
    when 11  # 按下按钮
      "Input.press?(#{@params[1]})"
    when 12  # 脚本
      "begin
        #{@params[1]}
      end"
    when 13  # 载具
      "$game_player.vehicle == $game_map.vehicles[#{@params[1]}]"
    end
    "if #{result}\n"
  end

  # 否则
  def command_411
    'else'
  end

  # 分支结束
  def command_412
    'end'
  end

  # 循环
  def command_112
    'while true'
  end

  # 重复
  def command_413
    'end'
  end

  # 跳出循环
  def command_113
    'break'
  end

  # 中止事件处理
  def command_115
    'return'
  end

  # 公共事件
  def command_117
    event = $data_common_events[@params[0]]
    self.class.new(event.list, @map_id, @event_id).transcompile_code if event
  end

  # 转至标签
  def command_119
    raise NotImplementedError
  end

  # 开关操作
  def command_121
    "#{@params[0]}.upto(#{@params[1]}) do |i|
      $game_switches[i] = #{@params[2] == 0}
    end"
  end

  # 变量操作
  def command_122
    value = case @params[3]  # 操作方式
    when 0  # 常量
      @params[4]
    when 1  # 变量
    "$game_variables[#{@params[4]}]"
    when 2  # 随机数
      "#{@params[4]} + rand(#{@params[5] - @params[4] + 1})"
    when 3  # 游戏数据
      "game_data_operand(#{@params[4]}, #{@params[5]}, #{@params[6]})"
    when 4  # 脚本
      "begin
        #{@params[4]}
      end"
    end
    "#{@params[0]}.upto(#{@params[1]}) do |i|
      operate_variable(i, #{@params[2]}, #{value})
    end"
  end

  # 独立开关操作
  def command_123
    return if @event_id <= 0
    "$game_self_switches[[#{@map_id}, #{@event_id}, "\
    "#{escape @params[0]}]] = #{@params[1] == 0}"
  end

  # 计时器操作
  def command_124
    if @params[0] == 0  # 开始
      "$game_timer.start(#{@params[1] * Graphics.frame_rate})"
    else                # 停止
      '$game_timer.stop'
    end
  end

  # 增减金钱
  def command_125
    value = operate_value(@params[0], @params[1], @params[2])
    "$game_party.gain_gold(#{value})"
  end

  # 增减物品
  def command_126
    value = operate_value(@params[1], @params[2], @params[3])
    "$game_party.gain_item($data_items[#{@params[0]}], #{value})"
  end

  # 增减武器
  def command_127
    value = operate_value(@params[1], @params[2], @params[3])
    "$game_party.gain_item($data_weapons[#{@params[0]}], "\
    "#{value}, #{@params[4]})"
  end

  # 增减护甲
  def command_128
    value = operate_value(@params[1], @params[2], @params[3])
    "$game_party.gain_item($data_armors[#{@params[0]}], "\
    "#{value}, #{@params[4]})"
  end

  # 队伍管理
  def command_129
    return unless $game_actors[@params[0]]
    ret = ''
    if @params[1] == 0    # 入队
      if @params[2] == 1  # 初始化
        ret << "$game_actors[#{@params[0]}].setup(#{@params[0]})\n"
      end
      ret << "$game_party.add_actor(#{@params[0]})"
    else                  # 离队
      ret << "$game_party.remove_actor(#{@params[0]})"
    end
  end

  # 设置禁用存档
  def command_134
    "$game_system.menu_disabled = #{@params[0] == 0}"
  end

  # 设置禁用菜单
  def command_135
    "$game_system.menu_disabled = #{@params[0] == 0}"
  end

  # 设置禁用遇敌
  def command_136
    "$game_system.encounter_disabled = #{@params[0] == 0}
    $game_player.make_encounter_count"
  end

  # 设置禁用整队
  def command_137
    "$game_system.formation_disabled = #{@params[0] == 0}"
  end

  # 场所移动
  def command_201
    if @params[0] == 0                      # 直接指定
      map_id = @params[1]
      x = @params[2]
      y = @params[3]
    else                                    # 变量指定
      map_id = "$game_variables[#{@params[1]}]"
      x = "$game_variables[#{@params[2]}]"
      y = "$game_variables[#{@params[3]}]"
    end
    only_map "
      Fiber.yield while $game_player.transfer? || $game_message.visible
      $game_player.reserve_transfer(#{map_id}, #{x}, #{y}, #{@params[4]})
      $game_temp.fade_type = #{@params[5]}
      Fiber.yield while $game_player.transfer?"
  end

  # 设置载具位置
  def command_202
    if @params[1] == 0                      # 直接指定
      map_id = @params[2]
      x = @params[3]
      y = @params[4]
    else                                    # 变量指定
      map_id = "$game_variables[#{@params[2]}]"
      x = "$game_variables[#{@params[3]}]"
      y = "$game_variables[#{@params[4]}]"
    end
    "@params = $game_map.vehicles[#{@params[0]}]
    @params.set_location(#{map_id}, #{x}, #{y}) if @params"
  end

  # 设置事件位置
  def command_203
    case @params[1]
    when 0
      "@params = get_character(#{@params[0]})
      @params.moveto(#{@params[2]}, #{@params[3]}) if @params
      #{"@params.set_direction(#{@params[4]})" if @params[4] > 0}"
    when 1
      "@params = get_character(#{@params[0]})
      @params.moveto("\
      "$game_variables[#{@params[2]}], "\
      "$game_variables[#{@params[3]}])
      #{"@params.set_direction(#{@params[4]})" if @params[4] > 0}"
    when 2
      "@params = [get_character(#{@params[0]}), "\
      "get_character(#{@params[2]})]
      @params.first.swap(@params.last) if @params.all?
      #{"@params.first.set_direction(#{@params[4]})" if @params[4] > 0}"
    end
  end

  # 地图卷动
  def command_204
    only_map "
      Fiber.yield while $game_map.scrolling?
      $game_map.start_scroll(#{@params[0]}, #{@params[1]}, #{@params[2]})
    "
  end

  # 载具乘降
  def command_206
    '$game_player.get_on_off_vehicle'
  end

  # 更改透明状态
  def command_211
    "$game_player.transparent = #{@params[0] == 0}"
  end

  # 显示动画
  def command_212
    "@params = get_character(#{@params[0]})
    if @params
      @params.animation_id = #{@params[1]}
      #{'Fiber.yield while @params.animation_id > 0' if @params[2]}
    end"
  end

  # 显示心情图标
  def command_213
    "@params = get_character(#{@params[0]})
    if @params
      @params.balloon_id = #{@params[1]}
      #{'Fiber.yield while @params.balloon_id > 0' if @params[2]}
    end"
  end

  # 暂时消除事件
  def command_214
    return if @event_id <= 0
    "$game_map.events[#{@event_id}].erase if #{same_map?}"
  end

  # 更改队列前进
  def command_216
    "$game_player.followers.visible = #{@params[0] == 0}
    $game_player.refresh"
  end

  # 集合队伍成员
  def command_217
    only_map '$game_player.followers.gather
    Fiber.yield until $game_player.followers.gather?'
  end

  # 淡出画面
  def command_221
    "Fiber.yield while $game_message.visible
    screen.start_fadeout(30)
    #{wait(30)}"
  end

  # 淡入画面
  def command_222
    "Fiber.yield while $game_message.visible
    screen.start_fadein(30)
    #{wait(30)}"
  end

  # 画面震动
  def command_225
    "screen.start_shake(#{@params[0]}, #{@params[1]}, #{@params[2]})
    #{wait(@params[2]) if @params[3]}"
  end

  # 等待
  def command_230
    wait(@params[0])
  end

  # 显示图片
  def command_231
    if @params[3] == 0    # 直接指定
      x = @params[4]
      y = @params[5]
    else                  # 变量指定
      x = "$game_variables[#{@params[4]}]"
      y = "$game_variables[#{@params[5]}]"
    end
    "screen.pictures[#{@params[0]}].show(#{escape @params[1]}, "\
    "#{@params[2]}, #{x}, #{y}, #{@params[6]}, #{@params[7]}, "\
    "#{@params[8]}, #{@params[9]})"
  end

  # 移动图片
  def command_232
    if @params[3] == 0    # 直接指定
      x = @params[4]
      y = @params[5]
    else                  # 变量指定
      x = "$game_variables[#{@params[4]}]"
      y = "$game_variables[#{@params[5]}]"
    end
    "screen.pictures[#{@params[0]}].move(#{@params[2]}, #{x}, #{y}, "\
    "#{@params[6]}, #{@params[7]}, #{@params[8]}, "\
    "#{@params[9]}, #{@params[10]})
    #{wait(@params[10]) if @params[11]}"
  end

  # 旋转图片
  def command_233
    "screen.pictures[#{@params[0]}].rotate(#{@params[1]})"
  end

  # 消除图片
  def command_235
    "screen.pictures[#{@params[0]}].erase"
  end

  # 设置天气
  def command_236
    only_map "
      screen.change_weather(:#{@params[0]}, #{@params[1]}, #{@params[2]})
      #{wait(@params[2]) if @params[3]}"
  end

  # 淡出 BGM
  def command_242
    "RPG::BGM.fade(#{@params[0] * 1000})"
  end

  # 记忆 BGM
  def command_243
    '$game_system.save_bgm'
  end

  # 恢复 BGM
  def command_244
    '$game_system.replay_bgm'
  end

  # 淡出 BGS
  def command_246
    "RPG::BGS.fade(#{@params[0] * 1000})"
  end

  # 停止 SE
  def command_251
    RPG::SE.stop
  end

  # 播放影像
  def command_261
    name = @params[0]
    return if name.empty?
    name = escape('Movies/' + name)
    "Fiber.yield while $game_message.visible
    Fiber.yield
    Graphics.play_movie(#{name})"
  end

  # 更改地图名称显示
  def command_281
    "$game_map.name_display = #{@params[0] == 0}"
  end

  # 更改图块组
  def command_282
    "$game_map.change_tileset(#{@params[0]})"
  end

  # 更改战场背景
  def command_283
    name = "#{escape(@params[0])}, #{escape(@params[1])}"
    "$game_map.change_battleback(#{name})"
  end

  # 更改远景
  def command_284
    "$game_map.change_parallax(#{escape @params[0]}, "\
    "#{@params[1]}, #{@params[2]}, #{@params[3]}, #{@params[4]})"
  end

  # 获取指定位置的信息
  def command_285
    if @params[2] == 0      # 直接指定
      x = @params[3]
      y = @params[4]
    else                    # 变量指定
      x = "$game_variables[#{@params[3]}]"
      y = "$game_variables[#{@params[4]}]"
    end
    value =
    case @params[1]
    when 0      # 地形标志
      "$game_map.terrain_tag(#{x}, #{y})"
    when 1      # 事件 ID
      "$game_map.event_id_xy(#{x}, #{y})"
    when 2..4   # 图块 ID
      "$game_map.tile_id(#{x}, #{y}, #{@params[1] - 2})"
    else        # 区域 ID
      "$game_map.region_id(#{x}, #{y})"
    end
    "$game_variables[#{@params[0]}] = #{value}"
  end

  # 战斗的处理
  def command_301
    troop_id = if @params[0] == 0             # 直接指定
      @params[1]
    elsif @params[0] == 1                     # 变量指定
      "$game_variables[#{@params[1]}]"
    else                                      # 地图指定的敌群
      '$game_player.make_encounter_troop_id'
    end
    ret = "
    if $data_troops[#{troop_id}]
      BattleManager.setup(#{troop_id}, #{@params[2]}, #{@params[3]})
      BattleManager.event_proc = Proc.new { |n| @params = n }
      $game_player.make_encounter_count
      SceneManager.call(Scene_Battle)
    end
    Fiber.yield
    "
    if next_code == 601 # 存在分支
      next_command!
      ret << "case @params\n"
      until current_code == 604 # 分支结束
        ret << "when #{current_code - 601}\n" << transcompile_branch << "\n"
      end
      ret << "end"
    end
    only_map ret
  end

  # 商店的处理
  def command_302
    goods = [@params]
    while next_code == 605
      goods.push(next_params!)
    end
    only_map "
      SceneManager.call(Scene_Shop)
      SceneManager.scene.prepare(#{escape goods}, #{@params[4]})
      Fiber.yield"
  end

  # 名字输入的处理
  def command_303
    return '' unless $data_actors[@params[0]]
    only_map "
      SceneManager.call(Scene_Name)
      SceneManager.scene.prepare(#{@params[0]}, #{@params[1]})
      Fiber.yield"
  end

  # 增减 HP
  def command_311
    value = operate_value(@params[2], @params[3], @params[4])
    iter_actor_var(@params[0], @params[1]) do |actor|
      "next if #{actor}.dead?
      #{actor}.change_hp(#{value}, #{@params[5]})
      #{actor}.perform_collapse_effect if #{actor}.dead?"
    end << '
      SceneManager.goto(Scene_Gameover) if $game_party.all_dead?'
  end

  # 增减 MP
  def command_312
    value = operate_value(@params[2], @params[3], @params[4])
    iter_actor_var(@params[0], @params[1]) do |actor|
      "#{actor}.mp += #{value}"
    end
  end

  # 更改状态
  def command_313
    action = @params[2] == 0 ? 'add_state' : 'remove_state'
    iter_actor_var(@params[0], @params[1]) do |actor|
      "@params = actor.dead?
      #{actor}.#{action}(#{@params[3]})
      #{actor}.perform_collapse_effect if #{actor}.dead? && !@params"
    end
  end

  # 完全恢复
  def command_314
    iter_actor_var(@params[0], @params[1]) do |actor|
      "#{actor}.recover_all"
    end
  end

  # 增减经验值
  def command_315
    value = operate_value(@params[2], @params[3], @params[4])
    iter_actor_var(@params[0], @params[1]) do |actor|
      "#{actor}.change_exp(#{actor}.exp + #{value}, #{@params[5]})"
    end
  end

  # 增减等级
  def command_316
    value = operate_value(@params[2], @params[3], @params[4])
    iter_actor_var(@params[0], @params[1]) do |actor|
      "#{actor}.change_level(#{actor}.level + #{value}, #{@params[5]})"
    end
  end

  # 增减能力值
  def command_317
    value = operate_value(@params[3], @params[4], @params[5])
    iter_actor_var(@params[0], @params[1]) do |actor|
      "#{actor}.add_param(#{@params[2]}, #{value})"
    end
  end

  # 增减技能
  def command_318
    action = @params[2] == 0 ? 'learn_skill' : 'forget_skill'
    iter_actor_var(@params[0], @params[1]) do |actor|
      "#{actor}.#{action}(#{@params[3]})"
    end
  end

  # 更换装备
  def command_319
    "@params = $game_actors[#{@params[0]}]
    @params.change_equip_by_id(#{@params[1]}, #{@params[2]}) if @params"
  end

  # 更改名字
  def command_320
    "@params = $game_actors[#{@params[0]}]
    @params.name = #{escape @params[1]} if @params"
  end

  # 更改职业
  def command_321
    return '' unless $data_classes[@params[1]]
    "@params = $game_actors[#{@params[0]}]
    @params.change_class(#{@params[1]}) if @params"
  end

  # 更改角色图像
  def command_322
    return unless $game_actors[@params[0]]
    "$game_actors[#{@params[0]}].set_graphic("\
    "#{escape @params[1]}, #{@params[2]}, "\
    "#{escape @params[3]}, #{@params[4]})
    $game_player.refresh"
  end

  # 更改载具的图像
  def command_323
    "@params = $game_map.vehicles[#{@params[0]}]
    @params.set_graphic(#{escape @params[1]}, #{@params[2]}) if @params"
  end

  # 更改称号
  def command_324
    "@params = $game_actors[#{@params[0]}]
    @params.nickname = #{escape @params[1]} if @params"
  end

  # 增减敌人 HP
  def command_331
    value = operate_value(@params[1], @params[2], @params[3])
    iter_enemy_index(@params[0]) do |enemy|
      "unless #{enemy}.dead?
        #{enemy}.change_hp(#{value}, #{@params[4]})
        #{enemy}.perform_collapse_effect if #{enemy}.dead?
      end"
    end
  end

  # 增减敌人的 MP
  def command_332
    value = operate_value(@params[1], @params[2], @params[3])
    iter_enemy_index(@params[0]) do |enemy|
      "#{enemy}.mp += #{value}"
    end
  end

  # 更改敌人的状态
  def command_333
    action = @params[1] == 0 ? 'add_state' : 'remove_state'
    iter_enemy_index(@params[0]) do |enemy|
      "@params = #{enemy}.dead?
      #{enemy}.#{action}(#{@params[2]})
      #{enemy}.perform_collapse_effect if #{enemy}.dead? && !@params"
    end
  end

  # 敌人完全恢复
  def command_334
    iter_enemy_index(@params[0]) do |enemy|
      "#{enemy}.recover_all"
    end
  end

  # 敌人出现
  def command_335
    iter_enemy_index(@params[0]) do |enemy|
      "#{enemy}.appear
      $game_troop.make_unique_names"
    end
  end

  # 敌人变身
  def command_336
    iter_enemy_index(@params[0]) do |enemy|
      "#{enemy}.transform(#{@params[1]})
      $game_troop.make_unique_names"
    end
  end

  # 显示战斗动画
  def command_337
    iter_enemy_index(@params[0]) do |enemy|
      "#{enemy}.animation_id = #{@params[1]} if #{enemy}.alive?"
    end
  end

  # 强制战斗行动
  def command_339
    iter_battler(@params[0], @params[1]) do |battler|
      "next if #{battler}.death_state?
      #{battler}.force_action(#{@params[2]}, #{@params[3]})
      BattleManager.force_action(#{battler})
      Fiber.yield while BattleManager.action_forced?"
    end
  end

  # 中止战斗
  def command_340
    'BattleManager.abort
    Fiber.yield'
  end

  # 打开菜单画面
  def command_351
    only_map 'SceneManager.call(Scene_Menu)
    Window_MenuCommand.init_command_position
    Fiber.yield'
  end

  # 打开存档画面
  def command_352
    only_map 'SceneManager.call(Scene_Save)
    Fiber.yield'
  end

  # 游戏结束
  def command_353
    'SceneManager.goto(Scene_Gameover)
    Fiber.yield'
  end

  # 返回标题画面
  def command_354
    'SceneManager.goto(Scene_Title)
    Fiber.yield'
  end

  # 脚本
  def command_355
    @params[0]
  end

  # 脚本数据
  alias_method :command_655, :command_355


  # 生成代码，将 command 直接代理给 Game_Interpreter#command_xxx
  delegate_command = lambda do |code|
    # def command_233
    #   "@params = ObjectSpace._id2ref(#{@params.__id__})
    #   command_233"
    # end
    set_params = '@params = ObjectSpace._id2ref(#{@params.__id__})'
    %{
      def command_#{code}
        "#{set_params}
        command_#{code}"
      end
    }
  end

  class_eval [
    132,      # 更改战斗 BGM
    133,      # 更改战斗结束 ME
    138,      # 更改窗口色调
    205,      # 设置移动路径
    223,      # 更改画面色调
    224,      # 画面闪烁
    234,      # 更改图片的色调
    241,      # 播放 BGM
    245,      # 播放 BGS
    249,      # 播放 ME
    250       # 播放 SE
  ].map(&delegate_command).join

end
