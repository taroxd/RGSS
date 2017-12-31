# @taroxd metadata 1.0
# @require taroxd_core
# @display 全键盘脚本
# @id keyboard

module Keyboard

  Taroxd::Keyboard = self

  BUTTON_L  = 0x01        # left mouse button
  BUTTON_R  = 0x02        # right mouse button
  BUTTON_M  = 0x04        # middle mouse button
  BUTTON_4  = 0x05        # 4th mouse button
  BUTTON_5  = 0x06        # 5th mouse button

  BACK      = 0x08        # BACKSPACE key
  TAB       = 0x09        # TAB key
  ENTER     = 0x0D        # ENTER key
  SHIFT     = 0x10        # SHIFT key
  CTLR      = 0x11        # CTLR key
  ALT       = 0x12        # ALT key
  PAUSE     = 0x13        # PAUSE key
  CAPS      = 0x14        # CAPS LOCK key
  ESC       = 0x1B        # ESC key
  SPACE     = 0x20        # SPACEBAR
  PRIOR     = 0x21        # PAGE UP key
  NEXT      = 0x22        # PAGE DOWN key
  self::END = 0x23        # END key
  HOME      = 0x24        # HOME key
  LEFT      = 0x25        # LEFT ARROW key
  UP        = 0x26        # UP ARROW key
  RIGHT     = 0x27        # RIGHT ARROW key
  DOWN      = 0x28        # DOWN ARROW key
  SELECT    = 0x29        # SELECT key
  PRINT     = 0x2A        # PRINT key
  BB        = 0x2B        # SELECT key
  SNAPSHOT  = 0x2C        # PRINT SCREEN key
  INSERT    = 0x2D        # INS key
  DELETE    = 0x2E        # DEL key

  NUM0      = 0x30        # 0 key
  NUM1      = 0x31        # 1 key
  NUM2      = 0x32        # 2 key
  NUM3      = 0x33        # 3 key
  NUM4      = 0x34        # 4 key
  NUM5      = 0x35        # 5 key
  NUM6      = 0x36        # 6 key
  NUM7      = 0x37        # 7 key
  NUM8      = 0x38        # 8 key
  NUM9      = 0x39        # 9 key
  A         = 0x41        # A key
  B         = 0x42        # B key
  C         = 0x43        # C key
  D         = 0x44        # D key
  E         = 0x45        # E key
  F         = 0x46        # F key
  G         = 0x47        # G key
  H         = 0x48        # H key
  I         = 0x49        # I key
  J         = 0x4A        # J key
  K         = 0x4B        # K key
  L         = 0x4C        # L key
  M         = 0x4D        # M key
  N         = 0x4E        # N key
  O         = 0x4F        # O key
  P         = 0x50        # P key
  Q         = 0x51        # Q key
  R         = 0x52        # R key
  S         = 0x53        # S key
  T         = 0x54        # T key
  U         = 0x55        # U key
  V         = 0x56        # V key
  W         = 0x57        # W key
  X         = 0x58        # X key
  Y         = 0x59        # Y key
  Z         = 0x5A        # Z key

  LWIN      = 0x5B        # Left Windows key (Microsoft Natural keyboard)
  RWIN      = 0x5C        # Right Windows key (Natural keyboard)
  APPS      = 0x5D        # Applications key (Natural keyboard)

  NUMPAD0   = 0x60        # Numeric keypad 0 key
  NUMPAD1   = 0x61        # Numeric keypad 1 key
  NUMPAD2   = 0x62        # Numeric keypad 2 key
  NUMPAD3   = 0x63        # Numeric keypad 3 key
  NUMPAD4   = 0x64        # Numeric keypad 4 key
  NUMPAD5   = 0x65        # Numeric keypad 5 key
  NUMPAD6   = 0x66        # Numeric keypad 6 key
  NUMPAD7   = 0x67        # Numeric keypad 7 key
  NUMPAD8   = 0x68        # Numeric keypad 8 key
  NUMPAD9   = 0x69        # Numeric keypad 9 key
  MULTIPLY  = 0x6A        # Multiply key (*)
  ADD       = 0x6B        # Add key (+)
  SEPARATOR = 0x6C        # Separator key
  SUBTRACT  = 0x6D        # Subtract key (-)
  DECIMAL   = 0x6E        # Decimal key
  DIVIDE    = 0x6F        # Divide key (/)

  F1        = 0x70        # F1 key
  F2        = 0x71        # F2 key
  F3        = 0x72        # F3 key
  F4        = 0x73        # F4 key
  F5        = 0x74        # F5 key
  F6        = 0x75        # F6 key
  F7        = 0x76        # F7 key
  F8        = 0x77        # F8 key
  F9        = 0x78        # F9 key
  F10       = 0x79        # F10 key
  F11       = 0x7A        # F11 key
  F12       = 0x7B        # F12 key

  NUMLOCK   = 0x90        # NUM LOCK key
  SCROLL    = 0x91        # SCROLL LOCK key

  LSHIFT    = 0xA0        # Left SHIFT key
  RSHIFT    = 0xA1        # Right SHIFT key
  LCONTROL  = 0xA2        # Left CONTROL key
  RCONTROL  = 0xA3        # Right CONTROL key
  L_ALT     = 0xA4        # Left ALT key
  R_ALT     = 0xA5        # Right ALT key

  SEP       = 0xBC        # , key
  DASH      = 0xBD        # - key
  DOTT      = 0xBE        # . Key

  API = Win32API.new('user32', 'GetAsyncKeyState', 'I', 'I')

  # 以按键码为键，连续按下的帧数为值的 hash
  @states = Hash.new { |h, k| h[k] = 0 }

  def self.update
    @states.each_key do |key|
      @states[key] = press?(key) ? @states[key] + 1 : 0
    end
  end

  def self.clear
    @states.clear
  end

  def self.press?(key)
    API.call(key) < 0
  end

  def self.trigger?(key)
    @states[key] == 1
  end

  def self.repeat?(key)
    times = @states[key]
    times == 1 || times > 23 && times % 6 == 0
  end
end

Scene_Base.send :def_before, :post_start, Keyboard.method(:clear)
Input.singleton_def_after :update, Keyboard.method(:update)