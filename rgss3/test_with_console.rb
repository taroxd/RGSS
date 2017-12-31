# @taroxd metadata 1.0
# @display 非测试游戏的控制台
# @id test_with_console
# @help 在直接使用 Game.exe 打开游戏时，同时打开控制台

unless $TEST
  Win32API.new('kernel32', 'AllocConsole', 'v', 'v').call
  $stdout = File.open('CONOUT$', 'w')
  $stdin  = File.open('CONIN$')
end