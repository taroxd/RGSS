# @taroxd metadata 1.0
# @id param_ex
# @display 新建属性值

module Taroxd end

module Taroxd::ParamEx

  # 大写属性名 = {
  #  特性 => 数值，数组，哈希或接受一个参数的 Proc。详见下面的范例,
  # }
  #
  # 角色将会根据 角色->职业->武器->护甲->状态 的顺序计算属性值
  # 初始的属性值等于角色的等级。
  # 遇到一个设置是数值时，属性值会加上这个数值。
  # 遇到一个 proc 或哈希或数组时，会以属性值为参数/下标来获取新的属性值。
  #
  # 敌人将会根据 敌人->状态 的顺序计算属性值。
  # 初始的属性值为 0，计算方法同上。
  #
  # 至于状态窗口的修改，不在本脚本的范围之内。请按需自行修改。
  #
  # 一般来说，建议在 actor 设置里面用等级索引属性值
  #
  # 下面是示例：

  STRENGTH = {
    # 角色
    actor: {
      1 => [nil,1,1,2,3,5,8,13,21,34,55],
      2 => {1=>1,2=>1,3=>2,4=>3,5=>5,6=>8,7=>13,8=>21,9=>34,10=>55},
      3 => Hash.new{|h,k|h[k]=h[k-1]+h[k-2]}.tap{|h|h[1]=h[2]=1},
      4 => ->lv{i,j=1,1;(lv-2).times{|k|i,j=j,i+j};j},
    },
    # 敌人
    enemy: {
      1 => 5,
      2 => 6,
      3 => 8,
    },
    # 职业
    class: {
      1 => 10,
    },
    # 武器
    weapons: {
      1 => 5,
      2 => -> old { old * 1.05 },
    },
    # 护甲
    armors: {
      # 无设置
    },
    states: {
      1 => Proc.new { 0 },
    },
  }

  # strength 设置完成。此后就可以在技能公式里调用 a.strength 了。

end

class Game_BattlerBase
  # 获取属性值。param: 基础值 features: 特性列表, const: 设置的常量
  def taroxd_paramex(param, features, const)
    features.each do |type|
      list = const[type]
      next unless list
      [*send(type)].each do |item|
        settings = list[item.id]
        if settings.respond_to?(:coerce)
          param += settings
        elsif settings.respond_to?(:[])
          param = settings[param] || param
        end
      end
    end
    param.to_i
  end
end

# 定义所有设置的属性
actor_features = [:actor, :class, :weapons, :armors, :states]
enemy_features = [:enemy, :states]

Taroxd::ParamEx.constants(false).each do |name|
  const = Taroxd::ParamEx.const_get name
  name = name.downcase
  Game_Actor.send :define_method, name do
    taroxd_paramex(@level, actor_features, const)
  end
  Game_Enemy.send :define_method, name do
    taroxd_paramex(0, enemy_features, const)
  end
end
