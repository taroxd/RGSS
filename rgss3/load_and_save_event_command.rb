# @taroxd metadata 1.0
# @id load_and_save_event_command
# @display 迭代所有事件指令
# @help 迭代整个游戏的每个事件指令，并保存所做的修改。

module Taroxd
  module LoadAndSaveEventCommand

    module_function

    # 迭代所有地图事件的事件指令
    def of_map(&block)
      return to_enum(__method__) unless block
      load_data('Data/MapInfos.rvdata2').each_key do |map_id|
        load_and_save(sprintf('Data/Map%03d.rvdata2', map_id)) do |map|
          map.events.each_value do |event|
            event.pages.flat_map(&:list).each(&block)
          end
        end
      end
    end

    # 迭代所有公共事件的事件指令
    def of_common_event(&block)
      return to_enum(__method__) unless block
      load_and_save('Data/CommonEvents.rvdata2') do |events|
        events.each { |event| event.list.each(&block) if event }
      end
    end

    # 迭代所有敌群事件的事件指令
    def of_troop(&block)
      return to_enum(__method__) unless block
      load_and_save('Data/Troops.rvdata2') do |troops|
        troops.each do |troop|
          troop.pages.flat_map(&:list).each(&block) if troop
        end
      end
    end

    # 迭代上述所有事件指令
    def all(&block)
      return to_enum(__method__) unless block
      of_map(&block)
      of_common_event(&block)
      of_troop(&block)
    end

    # 读取文件，执行 block 并保存到原来的文件
    def load_and_save(filename, &block)
      save_data(load_data(filename).tap(&block), filename)
    end
  end
end