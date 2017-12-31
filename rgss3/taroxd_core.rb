# @taroxd metadata 1.0
# @display Taroxd 基础设置
# @id taroxd_core
# @help
# 定义了一些经常会用到的方法。
#
# 模块或类
#   方法名(参数) { block } / 别名 -> 返回值的类型或介绍
#     方法的介绍。
#     如果返回值没有给出，表明返回值无意义或没有确定的类型。
#
# Module
#   get_access_control(method_name) -> Symbol or nil
#     获取方法的访问控制。返回 :public, :protected, :private 或 nil（未定义）
#     method_name 为字符串或符号（Symbol），下同。
#
#   def_after(method_name) { |args| block } -> method_name
#   def_after(method_name, hook) -> method_name
#     重定义方法 method_name。
#     第一种形式中，将 block 定义为方法，在原方法之后调用。
#     第二种形式中，
#     * 如果 hook 为符号或字符串，那么会在原方法之后调用对应的方法。
#     * 如果 hook 可以响应方法 call，那么会在原方法之后调用 call。
#     * 如果 hook 是 UnboundMethod，那么会将 hook 绑定到对象后调用。
#
#     不改变原方法的返回值和访问控制。
#     无论哪种调用，参数都和原来的参数相同。
#     以下 def_* 的所有方法均有这两种形式。为了方便起见只写出第一种。
#
#     例：
#     class Game_Actor < Game_Battler
#       def_after :initialize do |actor_id|
#         @my_attribute = actor_id
#       end
#     end
#
#   def_after!(method_name) { |args| block } -> method_name
#     与 def_after 类似，但改变原方法的返回值。
#
#   def_before(method_name) { |args| block } -> method_name
#     与 def_after 类似，但在原方法之前调用。
#
#   def_with(method_name) { |old, args| block } -> method_name
#     与 def_after! 类似，但参数不同。old 参数是原方法的返回值。
#
#   def_chain(method_name) { |old, args| block } -> method_name
#     与 def_with 类似，但 old 参数为对应原方法的一个 Method 对象。
#
#   def_and(method_name) { |args| block } -> method_name
#     与 def_after 类似，但仅当原方法的返回值为真时调用。
#     仅当原方法的返回值为真时，才会改变原方法的返回值。
#
#   def_or(method_name) { |args| block } -> method_name
#     与 def_after 类似，但仅当原方法的返回值为伪时调用。
#     仅当原方法的返回值为假时，才会改变原方法的返回值。
#
#   def_if(method_name) { |args| block } -> method_name
#     与 def_before 类似，但仅当调用结果为真时调用原方法。
#     仅当调用的结果为假时，改变原方法的返回值为 nil。
#
#   def_unless(method_name) { |args| block } -> method_name
#     与 def_before 类似，但仅当调用结果为假时调用原方法。
#     仅当调用的结果为真时，改变原方法的返回值为 nil。
#
# Taroxd::ReadNote
#   该模块由以下类 extend。
#   RPG::BaseItem
#   RPG::Map
#   RPG::Event（将事件名称作为备注）
#   RPG::Tileset
#   RPG::Class::Learning
#
#   note_i(method_name, default = 0)
#     定义方法 method_name，读取备注中 <method_name x> 形式的内容。其中 x 为整数。
#     读取到的话，定义的方法会返回读取到的整数值，否则返回 default。
#
#   例：RPG::UsableItem.note_i :item_cost
#
#   note_f(method_name, default = 0.0)
#     与 note_i 类似，但读取的是实数。
#
#   note_s(method_name, default = '')
#     与 note_i 类似，但读取的是字符串。
#
#   note_bool(method_name)
#     定义 method_name 方法，判断备注中是否存在 <method_name> 子字符串。
#     特别地，若 method_name 以问号或感叹号结尾，读取内容中不需要包含问号、感叹号。
#     （上面几个方法也是一样）
#
# Taroxd::DisposeBitmap
#   dispose
#     释放位图后调用父类的 dispose 方法。
#
# Spriteset_Map / Spriteset_Battle
#   self.use_sprite(SpriteClass)
#   self.use_sprite(SpriteClass) { block }
#     在 Spriteset 中使用一个 SpriteClass 的精灵。
#     如果给出 block，则生成精灵使用的参数是 block 在 Spriteset 的上下文中执行后的返回值。
#     自动管理精灵的生成、更新、释放。
#
#    例：Spriteset_Map.use_sprite(Sprite_OnMap) { @viewport1 }
#
# Fixnum
#   id -> self
#     返回 self。这使得之后一些方法的参数既可以用数据库的数据，也可以用整数。
#
# Enumerable
#   sum(base = 0) { |element| block }
#     对所有元素 yield 后求和。base 为初始值。
#     没有 block 参数时，对所有元素求和。
#
#   例：
#   class Game_Unit
#     def tgr_sum
#       alive_members.sum(&:tgr)
#     end
#   end
#
#   pi(base = 1) { |element| block }
#     与 sum 类似，但对所有元素求积。
#
# Game_BaseItem
#   id / item_id -> Fixnum
#     返回物品 id。
#
# Game_BattlerBase
#   mtp -> Numeric
#     返回 max_tp。
#
#   initialized? -> true
#     返回 true。
#
# Game_Battler
#   note_objects -> Enumerator
#   note_objects { |obj| ... } -> self
#     迭代战斗者拥有的所有带有备注的对象。
#    （角色、职业、装备、技能、敌人、状态等）
#     没有 block 给出时，返回 Enumerator 对象。
#
#   note -> String
#     返回数据库对象的备注。
#
#   equips / weapons / armors -> []
#     返回空数组。
#
#   skill?(skill) -> true / false
#     判断是否拥有技能。skill 可以为技能 ID，也可以为 RPG::Skill 的实例。
#
#   skill_learn?(skill) -> true / false
#     判断是否习得技能。skill 可以为技能 ID，也可以为 RPG::Skill 的实例。
#
# Game_Actor
#   data_object -> RPG::Actor
#     返回数据库对象，等价于 actor。
#
#   weapon?(item) / armor?(item) -> true / false
#     检测是否装备对应的物品。item 可以为装备 ID，也可以为 RPG::EquipItem 的实例。
#
#   initialized? -> true / false
#     判断角色是否已经初始化。
#
# Game_Enemy
#   id -> Fixnum
#     返回敌人 id。
#
#   data_object -> RPG::Enemy
#     返回数据库对象，等价于 enemy。
#
#   skills -> Array
#     返回敌人的所有技能实例的数组。
#     skill? 方法判断是否拥有技能与该数组有关。
#
#   basic_skills -> Array
#     返回敌人行动列表中的技能 ID 的数组（元素可以重复）。
#     skill_learn? 方法判断是否学会技能与该数组有关。
#
# Game_Actors
#   include Enumerable
#
#   each -> Enumerator
#   each { |actor| block } -> self
#     迭代已经初始化的每个角色。
#     如果没有给出 block，返回一个 Enumerator 对象。
#
#   include?(actor)
#     角色是否已经初始化。actor 可以为 Game_Actor / RPG::Actor 的对象或 ID。
#
# Game_Unit
#   include Enumerable
#
#   each -> Enumerator
#   each { |battler| block } -> self
#     迭代队伍中的每个成员。
#     如果没有给出 block，返回一个 Enumerator 对象。
#     等价于 members.each。
#
#   each_member -> Enumerator / self
#     each 的别名。
#
#   self[*args] / slice(*args) -> Game_Actor / Array / nil
#     等价于 members[*args]
#
#   empty? -> true / false
#     判断队伍是否为空。
#
#   size / length -> Integer
#     返回队伍人数。
#
# Game_Party
#   include?(actor) -> true / false
#     队伍中是否存在角色。actor 可以为 Game_Actor / RPG::Actor 的对象或 ID。
#
# Game_Map
#   id -> Fixnum
#     返回地图 ID。
#
#   data_object -> RPG::Map
#     返回数据库对象。
#
#   note -> String
#     返回备注内容。
#
# Game_CharacterBase
#   same_pos?(character) -> true / false
#     判定是否处在相同位置。
#     character 是任意能够响应方法 x 和 y 的对象。
#     仅作为点(x, y)进行比较，不考虑 Game_Vehicle 的地图 ID 等问题。

module Taroxd end

module Taroxd::Def

  Singleton = Module.new { Object.send :include, self }
  Module.send :include, self

  def get_access_control(sym)
    return :public    if public_method_defined?    sym
    return :protected if protected_method_defined? sym
    return :private   if private_method_defined?   sym
    nil
  end

  template = lambda do |singleton|
    if singleton
      klass = 'singleton_class'
      get_method = 'method'
      define = 'define_singleton_method'
    else
      klass = 'self'
      get_method = 'instance_method'
      define = 'define_method'
    end
    %(
      def <name>(sym, hook = nil, &b)
        access = #{klass}.get_access_control sym
        old = #{get_method} sym
        if b
          #{define} sym, &b
          hook = #{get_method} sym
        end
        if hook.respond_to? :to_sym
          hook = hook.to_sym
          #{define} sym do |*args, &block|
            <pattern_sym>
          end
        elsif hook.respond_to? :call
          #{define} sym do |*args, &block|
            <pattern_call>
          end
        elsif hook.kind_of? UnboundMethod
          #{define} sym do |*args, &block|
            <pattern_unbound>
          end
        end
        #{klass}.__send__ access, sym
        sym
      end
    )
  end

  # 保存模板和替换 'hook(' 字符串的字符
  template = {false => template.call(false), true => template.call(true)}

  # 替换掉 pattern 中的语法
  gsub_pattern = lambda do |pattern, singleton|
    old = singleton ? 'old' : 'old.bind(self)'
    pattern.gsub('*', '*args, &block')
           .gsub(/old(\()?/) { $1 ? "#{old}.call(" : old }
  end

  # 存入代替 "hook(" 的字符串
  template['sym']     = '__send__(hook, '
  template['call']    = 'hook.call('
  template['unbound'] = 'hook.bind(self).call('

  # 获取定义方法内容的字符串
  # 得到的代码较长，请输出查看
  code = lambda do |name, pattern, singleton|
    pattern = gsub_pattern.call(pattern, singleton)
    template[singleton]
      .sub('<name>', name)
      .gsub(/<pattern_(\w+?)>/) { pattern.gsub('hook(', template[$1]) }
  end

  main = TOPLEVEL_BINDING.eval('self')

  # 定义 def_ 系列方法的方法
  define_singleton_method :def_ do |name, pattern|
    name = "#{__method__}#{name}"
    module_eval code.call(name, pattern, false)
    Singleton.module_eval code.call("singleton_#{name}", pattern, true)
    main.define_singleton_method name, &Kernel.method(name)
  end

  # 实际定义 def_ 系列的方法
  def_ :after,  'ret = old(*); hook(*); ret'
  def_ :after!, 'old(*); hook(*)'
  def_ :before, 'hook(*); old(*)'
  def_ :with,   'hook(old(*), *)'
  def_ :chain,  'hook(old, *)'
  def_ :and,    'old(*) && hook(*)'
  def_ :or,     'old(*) || hook(*)'
  def_ :if,     'old(*) if hook(*)'
  def_ :unless, 'old(*) unless hook(*)'
end

module Taroxd::ReadNote

  include RPG
  BaseItem.extend        self
  Map.extend             self
  Event.extend           self
  Tileset.extend         self
  Class::Learning.extend self

  # 获取 note 的方法
  def note_method
    :note
  end

  # 事件名称作为备注
  def Event.note_method
    :name
  end

  # 备注模板
  def note_any(name, default, re, capture)
    name = name.to_s
    mark = name.slice!(/[?!]\Z/)
    re = re.source if re.kind_of?(Regexp)
    re = "/<#{name.gsub('_', '\s*')}#{re}>/i"
    default = default.inspect
    class_eval %{
      def #{name}
        return @#{name} if instance_variable_defined? :@#{name}
        @#{name} = #{note_method} =~ #{re} ? (#{capture}) : (#{default})
      end
    }, __FILE__, __LINE__
    alias_method name + mark, name if mark
  end

  def note_i(name, default = 0)
    note_any(name, default, '\s*(-?\d+)', '$1.to_i')
  end

  def note_f(name, default = 0.0)
    note_any(name, default, '\s*(-?\d+(?:\.\d+)?)', '$1.to_f')
  end

  def note_s(name, default = '')
    note_any(name, default, '\s*(\S.*)', '$1')
  end

  def note_bool(name)
    note_any(name, false, '', 'true')
  end
end

module Taroxd::DisposeBitmap
  def dispose
    bitmap.dispose if bitmap
    super
  end
end

module Taroxd::SpritesetDSL

  # 方法名
  CREATE_METHOD_NAME  = :create_taroxd_sprites
  UPDATE_METHOD_NAME  = :update_taroxd_sprites
  DISPOSE_METHOD_NAME = :dispose_taroxd_sprites

  # 定义管理精灵的方法
  def self.extended(klass)
    klass.class_eval do
      sprites = nil

      define_method CREATE_METHOD_NAME do
        sprites = klass.sprite_list.map do |sprite_class, get_args|
          if get_args
            sprite_class.new(*instance_eval(&get_args))
          else
            sprite_class.new
          end
        end
      end

      define_method(UPDATE_METHOD_NAME)  { sprites.each(&:update)  }
      define_method(DISPOSE_METHOD_NAME) { sprites.each(&:dispose) }
    end
  end

  def use_sprite(klass, &get_args)
    sprite_list.push [klass, get_args]
  end

  def sprite_list
    @_taroxd_use_sprite ||= []
  end

  # 在一系列方法上触发钩子
  def sprite_method_hook(name)
    def_after :"create_#{name}",  CREATE_METHOD_NAME
    def_after :"update_#{name}",  UPDATE_METHOD_NAME
    def_after :"dispose_#{name}", DISPOSE_METHOD_NAME
  end
end

class Fixnum < Integer
  alias_method :id, :to_int
end

module Enumerable
  def sum(base = 0)
    block_given? ? inject(base) { |a, e| a + yield(e) } : inject(base, :+)
  end

  def pi(base = 1)
    block_given? ? inject(base) { |a, e| a * yield(e) } : inject(base, :*)
  end
end

class Game_BaseItem
  attr_reader :item_id
  alias_method :id, :item_id
end

class Game_BattlerBase

  def initialized?
    true
  end

  def mtp
    max_tp
  end
end

class Game_Battler < Game_BattlerBase

  # 迭代拥有备注的对象
  def note_objects
    return to_enum(__method__) unless block_given?
    states.each { |e| yield e }
    equips.each { |e| yield e if e }
    skills.each { |e| yield e }
    yield data_object
    yield self.class if actor?
  end

  def regenerate_tp
    self.tp += max_tp * trg
  end

  def data_object
    raise NotImplementedError
  end

  def note
    data_object.note
  end

  def id
    data_object.id
  end

  def skills
    (basic_skills | added_skills).sort.map { |id| $data_skills[id] }
  end

  def equips
    []
  end
  alias_method :weapons, :equips
  alias_method :armors,  :equips
  alias_method :basic_skills, :equips

  def skill?(skill)
    basic_skills.include?(skill.id) || added_skills.include?(skill.id)
  end

  def skill_learn?(skill)
    basic_skills.include?(skill.id)
  end
end

class Game_Actor < Game_Battler

  alias_method :data_object, :actor

  def weapon?(weapon)
    @equips.any? { |item| item.id == weapon.id && item.is_weapon? }
  end

  def armor?(armor)
    @equips.any? { |item| item.id == armor.id && item.is_armor? }
  end

  def initialized?
    $game_actors.include?(self)
  end

  private

  def basic_skills
    @skills
  end
end

class Game_Enemy < Game_Battler

  alias_method :data_object, :enemy
  alias_method :id, :enemy_id

  def basic_skills
    enemy.actions.map(&:skill_id)
  end
end

class Game_Actors

  include Enumerable

  def each
    return to_enum(__method__) unless block_given?
    @data.each { |actor| yield actor if actor }
    self
  end

  def include?(actor)
    @data[actor.id]
  end
end

class Game_Unit

  include Enumerable

  def to_a
    members
  end

  def each
    return to_enum(__method__) unless block_given?
    members.each { |battler| yield battler }
    self
  end
  alias_method :each_member, :each

  def [](*args)
    members[*args]
  end
  alias_method :slice, :[]

  def empty?
    members.empty?
  end

  def size
    members.size
  end
  alias_method :length, :size
end

class Game_Party < Game_Unit
  def include?(actor)
    @actors.include?(actor.id)
  end
end

class Game_Map

  alias_method :id, :map_id

  def data_object
    @map
  end

  def note
    @map.note
  end
end

class Game_CharacterBase
  def same_pos?(character)
    @x == character.x && @y == character.y
  end
end

class Spriteset_Map
  extend Taroxd::SpritesetDSL
  sprite_method_hook :timer
end

class Spriteset_Battle
  extend Taroxd::SpritesetDSL
  sprite_method_hook :timer
end