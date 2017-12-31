# @taroxd metadata 1.0
# @id task
# @require taroxd_core
# @display 简单任务系统

class Taroxd::Task

  LIST = [
    # 在此设置任务的内容。设置方式请参考 Taroxd::Task 的定义。
  ]
  COMPLETED_PREFIX = '\I[125]'      # 任务完成时的前缀，不需要可设置为 ''
  ONGOING_PRIFIX   = '\I[126]'      # 任务进行中的前缀，不需要可设置为 ''
  COMMAND          = '任务'         # 菜单上的指令名，不需要可设置为 nil

  def initialize(id, name, description = '', goal = 1)
    @id, @name, @description, @goal = id, name, description, goal
  end
  attr_reader :description

  def name
    (completed? ? COMPLETED_PREFIX : ONGOING_PRIFIX) + @name
  end

  def started?
    $game_switches[@id]
  end

  def completed?
    $game_variables[@id] >= @goal
  end

  # 设置任务列表
  LIST.map! { |args| new(*args) }

  def self.list
    LIST.select(&:started?)
  end
end

class Window_TaskList < Window_Selectable

  Task = Taroxd::Task

  def initialize(y)
    super(0, y, Graphics.width, Graphics.height - y)
    select Task.list.index { |task| !task.completed? }
    refresh
  end

  def col_max
    2
  end

  def item_max
    Task.list.size
  end

  def draw_item(index)
    rect = item_rect_for_text(index)
    draw_text_ex(rect.x, rect.y, Task.list[index].name)
  end

  def update_help
    @help_window.set_text(Task.list[index].description)
  end
end

class Scene_Task < Scene_MenuBase

  def start
    super
    create_help_window
    create_list_window
  end
  # 任务列表窗口
  def create_list_window
    @list_window = Window_TaskList.new(@help_window.height)
    @list_window.help_window = @help_window
    @list_window.set_handler(:cancel, method(:return_scene))
    @list_window.activate
  end
end

if Taroxd::Task::COMMAND
  class Window_MenuCommand < Window_Command
    task = Taroxd::Task
    # 指令“任务”
    def_after :add_original_commands do
      add_command(task::COMMAND, :task, !task.list.empty?)
    end
  end

  class Scene_Menu < Scene_MenuBase

    def_after :create_command_window do
      @command_window.set_handler(:task, method(:command_task))
    end

    # 指令“任务”
    def command_task
      SceneManager.call(Scene_Task)
    end
  end
end