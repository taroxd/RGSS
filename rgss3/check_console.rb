# @taroxd metadata 1.0
# @display 检查控制台是否打开
# @id check_console

if $TEST && Win32API.new('Kernel32.dll', 'GetConsoleWindow', '', 'L').call == 0
  msgbox "Warning: Console window is not displayed"
end
