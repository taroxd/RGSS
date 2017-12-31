# @taroxd metadata 1.0
# @display 全局变量存档
# @require taroxd_core
# @help 将 Taroxd::Global 哈希表中的对象写入存档。
# @id global

Taroxd::Global = {}
symbol = :taroxd_global

on_new_game = Taroxd::Global.method(:clear)

on_save = lambda do |contents|
  contents[symbol] = Taroxd::Global
  contents
end

on_load = lambda do |contents|
  data = contents[symbol]
  Taroxd::Global.replace(data) if data
end

DataManager.singleton_def_before :setup_new_game,        on_new_game
DataManager.singleton_def_with   :make_save_contents,    on_save
DataManager.singleton_def_after  :extract_save_contents, on_load
