# @taroxd metadata 1.0
# @display 自定义经验公式
# @id exp_formula
# @help
#    在职业上备注以下内容
#    <exp>
#      升级到等级 lv 所需要的总经验值公式
#    </exp>
#    可以使用的参数：
#      lv:    等级
#      basis：基础值
#      extra：修正值
#      acc_a：增加度 a
#      acc_b：增加度 b
#
#    例（默认公式）：
#    <exp>
#      basis*((lv-1)**(0.9+acc_a/250))*
#      lv*(lv+1)/(6+lv**2/50/acc_b)+
#      (lv-1)*extra
#    </exp>
#
#    注意事项：
#      如果需要使用转职功能，则 lv 为 1 时的经验值请不要大于 0 ！

module Taroxd
  EXPFormula = /<exp>\s*(.+)\s*<\/exp>/mi
end

class RPG::Class < RPG::BaseItem

  include Math

  original_formula = instance_method(:exp_for_level)
  define_method :exp_for_level do |level|
    @exp_formula ||= if @note =~ Taroxd::EXPFormula
      basis, extra, acc_a, acc_b = @exp_params.map(&:to_f)
      eval("->lv{lv=lv.to_f;(#{$1}).round}")
    else
      original_formula.bind(self)
    end
    @exp_formula.call(level)
  end
end