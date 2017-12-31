# @taroxd metadata 1.0
# @id recover_on_lv_up
# @display 升级时满血满蓝
# @require taroxd_core

Taroxd::RecoverOnLvUP = true

Game_Actor.send :def_after, :level_up, :recover_all