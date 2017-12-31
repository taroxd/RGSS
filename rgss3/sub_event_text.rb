# @taroxd metadata 1.0
# @id sub_event_text
# @display 事件文本的全局替换

if false

pattern = {
}

re = Regexp.union(pattern.keys)
change_text = -> text { text.gsub!(re, pattern) }

change_page = lambda do |page|
  return unless page
  page.list.each do |command|
    case command.code
    when 401, 405  # 显示文字 / 滚动文字
      change_text.(command.parameters[0])
    when 102  # 显示选项
      command.parameters[0].each(&change_text)
    end
  end
end

change_event = lambda do |event|
  return unless event
  event.pages.each(&change_page)
end

change_each_in_file = lambda do |filename, proc|
  save_data(load_data(filename).each(&proc), filename)
end

# 替换地图上的事件
load_data('Data/MapInfos.rvdata2').each_key do |map_id|
  filename = sprintf('Data/Map%03d.rvdata2', map_id)
  map = load_data(filename)
  map.events.each_value(&change_event)
  save_data(map, filename)
end

change_each_in_file.('Data/CommonEvents.rvdata2', change_page) # 替换公共事件
change_each_in_file.('Data/Troops.rvdata2', change_event) # 替换敌群中的事件

msgbox '全局替换成功！请重启编辑器以查看效果。'
exit

end # if false
