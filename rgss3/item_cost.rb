# @taroxd metadata 1.0
# @display 技能消耗物品
# @id item_cost
# @require taroxd_core
# @help   制作消耗物品的技能
#
#  使用方法：
#    技能备注 <itemcost item_id number>
#       item_id 为消耗的物品 id，number 为消耗的物品个数。
#       number 可不填，默认为 1（即 <itemcost item_id>）。
#    技能备注 <itemneed item_id number>
#       item_id 为需要的物品 id（不消耗），number 为消耗的物品个数。
#       number 可不填，默认为 1

Taroxd::ItemCost = Struct.new(:item, :number, :cost) do
  MP_ICON = 188
  TP_ICON = 189

  RE = /<item\s*(cost|need)\s+(\d+)(\s+\d+)?>/i

  def self.parse_note(note)
    note.scan(RE).map do |cost, item_id, number|
      new($data_items[item_id.to_i],
        (number ? number.to_i : 1),
        cost == 'cost')
    end
  end

  def meet?
    $game_party.item_number(item) >= number
  end

  def pay
    $game_party.lose_item(item, number) if cost
  end
end

class RPG::Skill < RPG::UsableItem
  def item_costs
    @item_costs ||= Taroxd::ItemCost.parse_note(@note)
  end
end

class Game_BattlerBase

  def_and :skill_cost_payable? do |skill|
    skill.item_costs.all?(&:meet?)
  end

  def_after :pay_skill_cost do |skill|
    skill.item_costs.each(&:pay)
  end
end


class Window_SkillList < Window_Selectable

  def draw_skill_cost(rect, skill)
    contents.font.size -= 6
    change_color(tp_cost_color, enable?(skill))
    draw_skill_cost_icon(rect, skill,
      @actor.skill_tp_cost(skill), Taroxd::ItemCost::TP_ICON)
    change_color(mp_cost_color, enable?(skill))
    draw_skill_cost_icon(rect, skill,
      @actor.skill_mp_cost(skill), Taroxd::ItemCost::MP_ICON)
    skill.item_costs.each do |item_cost|
      draw_skill_cost_icon(rect, skill,
        item_cost.number, item_cost.item.icon_index)
    end
    contents.font.size += 6
  end

  def draw_skill_cost_icon(rect, skill, cost, icon_index)
    return if cost == 0
    x = rect.x + rect.width - 24
    draw_icon(icon_index, x, rect.y, enable?(skill))
    draw_text(x, rect.y + 8, 24, 16, cost, 2) unless cost == 1
    rect.width -= 24
  end
end
