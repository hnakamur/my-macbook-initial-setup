#!/bin/sh
set -e

install_xcode() {
  /usr/bin/osascript -l JavaScript <<'EOF'
const INSTALL_XCODE_BUTTON_DESC = 'Install, Xcode, Free'
const OPEN_XCODE_BUTTON_DESC = ' Xcode を開く'

function isInvalidIndexError(e) {
  return e.toString() === 'Error: Invalid index.'
}

function waitUntilSuccess(f) {
  var ret
  do {
    delay(1)
    try {
      ret = f()
    } catch (e) {
      if (!isInvalidIndexError(e)) {
        throw e
      }
    }
  } while (!ret)
  return ret
}

function say(message) {
  var app = Application.currentApplication()
  app.includeStandardAdditions = true
  app.say(message)
}

function installXcode() {
  var installed = false
  var storeApp = Application('App Store')
  storeApp.activate()

  var storeProc = Application('System Events').processes.byName('App Store')
  storeProc.frontmost = true
  var win = storeProc.windows.byName('App Store')
  // Search for Xcode
  var textField = waitUntilSuccess(function() {
    return win.toolbars[0].groups[6].textFields[0]
  })
  textField.value = 'Xcode'
  textField.buttons[0].click()

  // Click Xcode in search results
  waitUntilSuccess(function() {
    win.groups[0].groups[0].scrollAreas[0].uiElements[0].groups[1].uiElements.byName('Xcode').click()
    return true
  })

  waitUntilSuccess(function() {
    var desc = getInstallButton(win).description()
    return desc === INSTALL_XCODE_BUTTON_DESC ||
           desc === OPEN_XCODE_BUTTON_DESC
  })

  var installBtn = getInstallButton(win)
  if (installBtn.description() === INSTALL_XCODE_BUTTON_DESC) {
    installBtn.click()
    waitUntilSuccess(function() {
      return installBtn.description() === OPEN_XCODE_BUTTON_DESC
    })
    installed = true
  }

  storeApp.quit()
  return installed
}

function getInstallButton(win) {
  return win.groups[0].groups[0].scrollAreas[0].uiElements[0].groups[0].groups[0].buttons[0]
}

function letUserAgreeToXcodeLicense() {
  var xcodeApp = Application('Xcode')
  xcodeApp.activate()
  say('エックスコードのライセンスに同意してください')
}

function run(argv) {
  if (installXcode()) {
    letUserAgreeToXcodeLicense()
  } else {
    say('エックスコードはすでにインストールされていました')
  }
}
EOF
}

install_xcode_cmdline_tools() {
  xcode-select --install
}

configure_keyboard() {
  /usr/bin/osascript <<'EOF'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preference.keyboard"
end tell

tell application "System Events" to tell process "System Preferences"
	set frontmost to true
	tell tab group 1 of window "キーボード"
		set value of slider "キーのリピート" to 100
		set value of slider "リピート入力認識までの時間" to 100

		set theCheckbox to checkbox "F1、F2 などのすべてのキーを標準のファンクションキーとして使用"
		if not (value of theCheckbox as boolean) then click theCheckbox
	end tell
end tell

tell application "System Preferences" to quit
EOF
}

swap_caps_and_control_keys() {
  /usr/bin/osascript - <<'EOF'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preference.keyboard"
	reveal anchor "keyboardTab_ModifierKeys" of current pane
end tell

tell application "System Events" to tell process "System Preferences"
	set frontmost to true
	delay 1
	set theSheet to sheet 1 of window "キーボード"
	tell theSheet
		set capsBtn to pop up button "Caps Lock（⇪）キー：" of theSheet
		click capsBtn
		click menu item "⌃ Control" of menu of capsBtn

		set ctrlBtn to pop up button "Control（⌃）キー：" of theSheet
		click ctrlBtn
		click menu item "⇪ Caps Lock" of menu of ctrlBtn

		click button "OK"
	end tell
end tell

tell application "System Preferences" to quit
EOF
}

change_next_window_shortcut() {
  /usr/bin/osascript - <<'EOF'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preference.keyboard"
	reveal anchor "shortcutsTab" of current pane
end tell

tell application "System Events" to tell process "System Preferences"
	set frontmost to true
	tell tab group 1 of window "キーボード"
		click radio button "ショートカット"
		delay 0.5
		tell table 1 of scroll area 1 of splitter group 1 to select row 3 -- "キーボード"
		delay 0.5
		tell outline 1 of scroll area 2 of splitter group 1 to select row 8 -- "次のウインドウを操作対象にする"
		delay 0.5
		keystroke tab
		keystroke tab
		keystroke tab
		key code 50 using {command down} -- ⌘`
	end tell
end tell
delay 0.5
tell application "System Preferences" to quit
EOF
}

configure_trackpad() {
  /usr/bin/osascript - <<'EOF'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preference.trackpad"
end tell
tell application "System Events" to tell process "System Preferences"
	set frontmost to true

	tell tab group 1 of window "トラックパッド"
		click radio button "ポイントとクリック"
		-- "タップでクリック"をオン
		set theCheckbox to checkbox 1
		if not value of theCheckbox as boolean then click theCheckbox
		-- "副ボタンのクリック"をオン
		set theCheckbox to checkbox 2
		if not value of theCheckbox as boolean then click theCheckbox
		-- "調べる"をオフ
		set theCheckbox to checkbox 3
		if value of theCheckbox as boolean then click theCheckbox
		-- "3 本指のドラッグ"をオフ
		set theCheckbox to checkbox 4
		if value of theCheckbox as boolean then click theCheckbox
		set value of slider "軌跡の速さ" to 100

		click radio button "スクロールとズーム"
		-- "スクロールの方向： ナチュラル"をオン
		set theCheckbox to checkbox 1
		if not value of theCheckbox as boolean then click theCheckbox
		-- "拡大／縮小"をオフ
		set theCheckbox to checkbox 2
		if value of theCheckbox as boolean then click theCheckbox
		-- "スマートズーム"をオフ
		set theCheckbox to checkbox 3
		if value of theCheckbox as boolean then click theCheckbox
		-- "回転"をオフ
		set theCheckbox to checkbox 4
		if value of theCheckbox as boolean then click theCheckbox

		click radio button "その他のジェスチャ"
		-- "ページ間をスワイプ"をオフ
		set theCheckbox to checkbox 1
		if value of theCheckbox as boolean then click theCheckbox
		-- "フルスクリーンアプリケーション間をスワイプ"をオフ
		set theCheckbox to checkbox 2
		if value of theCheckbox as boolean then click theCheckbox
		-- "通知センター"をオフ
		set theCheckbox to checkbox 3
		if value of theCheckbox as boolean then click theCheckbox
		-- "Mission Control"をオフ
		set theCheckbox to checkbox 4
		if value of theCheckbox as boolean then click theCheckbox
		-- "アプリケーション Exposé"をオフ
		set theCheckbox to checkbox 5
		if value of theCheckbox as boolean then click theCheckbox
		-- "Launchpad"をオフ
		set theCheckbox to checkbox 6
		if value of theCheckbox as boolean then click theCheckbox
		-- "デスクトップを表示"をオフ
		set theCheckbox to checkbox 7
		if value of theCheckbox as boolean then click theCheckbox
	end tell
end tell
delay 0.5
tell application "System Preferences" to quit
EOF
}

enable_trackpad_drag_lock() {
  /usr/bin/osascript - <<'EOF'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preference.universalaccess"
end tell

tell application "System Events" to tell process "System Preferences"
	set frontmost to true
	delay 1
	tell window "アクセシビリティ"
		tell table 1 of scroll area 1 to select row 12 -- マウスとトラックパッド
		click button "トラックパッドオプション..."
		tell sheet 1
			set theCheckbox to checkbox "ドラッグを有効にする"
			if not (value of theCheckbox as boolean) then click theCheckbox
			set theButton to pop up button "ドラッグを有効にする"
			click theButton
			click menu item "ドラッグロックあり" of menu of theButton
			keystroke return
		end tell
	end tell
end tell
delay 0.5
tell application "System Preferences" to quit
EOF
}

setup_homebrew() {
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  brew tap Homebrew/brewdler
  export HOMEBREW_CASK_OPTS="--appdir=/Applications"
  brew install caskroom/cask/brew-cask
  cat <<'EOF' > Brewfile
brew 'python'
tap 'caskroom/cask'
cask 'calibre'
cask 'firefox'
cask 'google-chrome'
cask 'google-japanese-ime'
cask 'grandperspective'
cask 'iterm2'
cask 'java'
cask 'macpass'
cask 'mysqlworkbench'
cask 'spark'
cask 'vagrant'
cask 'virtualbox'
cask 'xquartz'
EOF
  brew brewdle
}

register_macpass_shortcut() {
  /usr/bin/osascript - <<'EOF'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preference.keyboard"
	reveal anchor "shortcutsTab" of current pane
end tell

tell application "System Events" to tell process "System Preferences"
	set frontmost to true
	tell window "キーボード"
		click radio button "ショートカット" of tab group 1
		delay 0.5
		tell table 1 of scroll area 1 of splitter group 1 of tab group 1 to select row 9 -- "アプリケーション"
		delay 0.5

		click button 1 of group 1 of tab group 1 -- plus button
		set theSheet to sheet 1
		tell theSheet
			set theBtn to pop up button "アプリケーション：
" of theSheet
			click theBtn
			delay 1
			key code 119 -- end
			key code 36 -- return
			delay 1
			key code 20 using command down -- ⌘3
			keystroke "/Applications/MacPass.app"
			delay 1
			key code 36 -- return
			delay 1
			key code 36 -- return
			set value of text field "メニュータイトル：" to "Copy Username"
			keystroke tab
			key code 11 using {command down} -- ⌘B
			keystroke return
		end tell

		click button 1 of group 1 of tab group 1 -- plus button
		set theSheet to sheet 1
		tell theSheet
			set theBtn to pop up button "アプリケーション：
" of theSheet
			click theBtn
			delay 1
			key code 119 -- end
			key code 36 -- return
			delay 1
			key code 20 using command down -- ⌘3
			keystroke "/Applications/MacPass.app"
			delay 1
			key code 36 -- return
			delay 1
			key code 36 -- return
			set value of text field "メニュータイトル：" to "Copy Password"
			keystroke tab
			key code 8 using {command down} -- ⌘C
			keystroke return
		end tell

		click button 1 of group 1 of tab group 1 -- plus button
		set theSheet to sheet 1
		tell theSheet
			set theBtn to pop up button "アプリケーション：
" of theSheet
			click theBtn
			delay 1
			key code 119 -- end
			key code 36 -- return
			delay 1
			key code 20 using command down -- ⌘3
			keystroke "/Applications/MacPass.app"
			delay 1
			key code 36 -- return
			delay 1
			key code 36 -- return
			set value of text field "メニュータイトル：" to "Copy URL"
			keystroke tab
			key code 34 using {command down} -- ⌘I
			keystroke return
		end tell
	end tell
end tell
delay 0.5
tell application "System Preferences" to quit
EOF
}

add_spark_app_shortcuts() {
  /usr/bin/osascript -l JavaScript <<'EOF'

const VK_ANSI_A                    = 0x00
const VK_ANSI_S                    = 0x01
const VK_ANSI_D                    = 0x02
const VK_ANSI_F                    = 0x03
const VK_ANSI_H                    = 0x04
const VK_ANSI_G                    = 0x05
const VK_ANSI_Z                    = 0x06
const VK_ANSI_X                    = 0x07
const VK_ANSI_C                    = 0x08
const VK_ANSI_V                    = 0x09
const VK_ANSI_B                    = 0x0B
const VK_ANSI_Q                    = 0x0C
const VK_ANSI_W                    = 0x0D
const VK_ANSI_E                    = 0x0E
const VK_ANSI_R                    = 0x0F
const VK_ANSI_Y                    = 0x10
const VK_ANSI_T                    = 0x11
const VK_ANSI_1                    = 0x12
const VK_ANSI_2                    = 0x13
const VK_ANSI_3                    = 0x14
const VK_ANSI_4                    = 0x15
const VK_ANSI_6                    = 0x16
const VK_ANSI_5                    = 0x17
const VK_ANSI_Equal                = 0x18
const VK_ANSI_9                    = 0x19
const VK_ANSI_7                    = 0x1A
const VK_ANSI_Minus                = 0x1B
const VK_ANSI_8                    = 0x1C
const VK_ANSI_0                    = 0x1D
const VK_ANSI_RightBracket         = 0x1E
const VK_ANSI_O                    = 0x1F
const VK_ANSI_U                    = 0x20
const VK_ANSI_LeftBracket          = 0x21
const VK_ANSI_I                    = 0x22
const VK_ANSI_P                    = 0x23
const VK_ANSI_L                    = 0x25
const VK_ANSI_J                    = 0x26
const VK_ANSI_Quote                = 0x27
const VK_ANSI_K                    = 0x28
const VK_ANSI_Semicolon            = 0x29
const VK_ANSI_Backslash            = 0x2A
const VK_ANSI_Comma                = 0x2B
const VK_ANSI_Slash                = 0x2C
const VK_ANSI_N                    = 0x2D
const VK_ANSI_M                    = 0x2E
const VK_ANSI_Period               = 0x2F
const VK_ANSI_Grave                = 0x32
const VK_ANSI_KeypadDecimal        = 0x41
const VK_ANSI_KeypadMultiply       = 0x43
const VK_ANSI_KeypadPlus           = 0x45
const VK_ANSI_KeypadClear          = 0x47
const VK_ANSI_KeypadDivide         = 0x4B
const VK_ANSI_KeypadEnter          = 0x4C
const VK_ANSI_KeypadMinus          = 0x4E
const VK_ANSI_KeypadEquals         = 0x51
const VK_ANSI_Keypad0              = 0x52
const VK_ANSI_Keypad1              = 0x53
const VK_ANSI_Keypad2              = 0x54
const VK_ANSI_Keypad3              = 0x55
const VK_ANSI_Keypad4              = 0x56
const VK_ANSI_Keypad5              = 0x57
const VK_ANSI_Keypad6              = 0x58
const VK_ANSI_Keypad7              = 0x59
const VK_ANSI_Keypad8              = 0x5B
const VK_ANSI_Keypad9              = 0x5C
const VK_Return                    = 0x24
const VK_Tab                       = 0x30
const VK_Space                     = 0x31
const VK_Delete                    = 0x33
const VK_Escape                    = 0x35
const VK_Command                   = 0x37
const VK_Shift                     = 0x38
const VK_CapsLock                  = 0x39
const VK_Option                    = 0x3A
const VK_Control                   = 0x3B
const VK_RightShift                = 0x3C
const VK_RightOption               = 0x3D
const VK_RightControl              = 0x3E
const VK_Function                  = 0x3F
const VK_F17                       = 0x40
const VK_VolumeUp                  = 0x48
const VK_VolumeDown                = 0x49
const VK_Mute                      = 0x4A
const VK_F18                       = 0x4F
const VK_F19                       = 0x50
const VK_F20                       = 0x5A
const VK_F5                        = 0x60
const VK_F6                        = 0x61
const VK_F7                        = 0x62
const VK_F3                        = 0x63
const VK_F8                        = 0x64
const VK_F9                        = 0x65
const VK_F11                       = 0x67
const VK_F13                       = 0x69
const VK_F16                       = 0x6A
const VK_F14                       = 0x6B
const VK_F10                       = 0x6D
const VK_F12                       = 0x6F
const VK_F15                       = 0x71
const VK_Help                      = 0x72
const VK_Home                      = 0x73
const VK_PageUp                    = 0x74
const VK_ForwardDelete             = 0x75
const VK_F4                        = 0x76
const VK_End                       = 0x77
const VK_F2                        = 0x78
const VK_PageDown                  = 0x79
const VK_F1                        = 0x7A
const VK_LeftArrow                 = 0x7B
const VK_RightArrow                = 0x7C
const VK_DownArrow                 = 0x7D
const VK_UpArrow                   = 0x7E
const VK_ISO_Section               = 0x0A
const VK_JIS_Yen                   = 0x5D
const VK_JIS_Underscore            = 0x5E
const VK_JIS_KeypadComma           = 0x5F
const VK_JIS_Eisu                  = 0x66
const VK_JIS_Kana                  = 0x68

var modifierMap = {
  '⌃': 'control down',
  '⌘': 'command down',
  '⇧':'shift down',
  '⌥': 'option down'
}

var keyCodeMap = {
  "a": VK_ANSI_A,
  "s": VK_ANSI_S,
  "d": VK_ANSI_D,
  "f": VK_ANSI_F,
  "h": VK_ANSI_H,
  "g": VK_ANSI_G,
  "z": VK_ANSI_Z,
  "x": VK_ANSI_X,
  "c": VK_ANSI_C,
  "v": VK_ANSI_V,
  "b": VK_ANSI_B,
  "q": VK_ANSI_Q,
  "w": VK_ANSI_W,
  "e": VK_ANSI_E,
  "r": VK_ANSI_R,
  "y": VK_ANSI_Y,
  "t": VK_ANSI_T,
  "1": VK_ANSI_1,
  "2": VK_ANSI_2,
  "3": VK_ANSI_3,
  "4": VK_ANSI_4,
  "6": VK_ANSI_6,
  "5": VK_ANSI_5,
  "equal": VK_ANSI_Equal,
  "9": VK_ANSI_9,
  "7": VK_ANSI_7,
  "minus": VK_ANSI_Minus,
  "8": VK_ANSI_8,
  "0": VK_ANSI_0,
  "rightbracket": VK_ANSI_RightBracket,
  "o": VK_ANSI_O,
  "u": VK_ANSI_U,
  "leftbracket": VK_ANSI_LeftBracket,
  "i": VK_ANSI_I,
  "p": VK_ANSI_P,
  "l": VK_ANSI_L,
  "j": VK_ANSI_J,
  "quote": VK_ANSI_Quote,
  "k": VK_ANSI_K,
  "semicolon": VK_ANSI_Semicolon,
  "backslash": VK_ANSI_Backslash,
  "comma": VK_ANSI_Comma,
  "slash": VK_ANSI_Slash,
  "n": VK_ANSI_N,
  "m": VK_ANSI_M,
  "period": VK_ANSI_Period,
  "grave": VK_ANSI_Grave,
  "keypaddecimal": VK_ANSI_KeypadDecimal,
  "keypadmultiply": VK_ANSI_KeypadMultiply,
  "keypadplus": VK_ANSI_KeypadPlus,
  "keypadclear": VK_ANSI_KeypadClear,
  "keypaddivide": VK_ANSI_KeypadDivide,
  "keypadenter": VK_ANSI_KeypadEnter,
  "keypadminus": VK_ANSI_KeypadMinus,
  "keypadequals": VK_ANSI_KeypadEquals,
  "keypad0": VK_ANSI_Keypad0,
  "keypad1": VK_ANSI_Keypad1,
  "keypad2": VK_ANSI_Keypad2,
  "keypad3": VK_ANSI_Keypad3,
  "keypad4": VK_ANSI_Keypad4,
  "keypad5": VK_ANSI_Keypad5,
  "keypad6": VK_ANSI_Keypad6,
  "keypad7": VK_ANSI_Keypad7,
  "keypad8": VK_ANSI_Keypad8,
  "keypad9": VK_ANSI_Keypad9,
  "return": VK_Return,
  "tab": VK_Tab,
  "space": VK_Space,
  "delete": VK_Delete,
  "escape": VK_Escape,
  "command": VK_Command,
  "shift": VK_Shift,
  "capslock": VK_CapsLock,
  "option": VK_Option,
  "control": VK_Control,
  "rightshift": VK_RightShift,
  "rightoption": VK_RightOption,
  "rightcontrol": VK_RightControl,
  "function": VK_Function,
  "f17": VK_F17,
  "volumeup": VK_VolumeUp,
  "volumedown": VK_VolumeDown,
  "mute": VK_Mute,
  "f18": VK_F18,
  "f19": VK_F19,
  "f20": VK_F20,
  "f5": VK_F5,
  "f6": VK_F6,
  "f7": VK_F7,
  "f3": VK_F3,
  "f8": VK_F8,
  "f9": VK_F9,
  "f11": VK_F11,
  "f13": VK_F13,
  "f16": VK_F16,
  "f14": VK_F14,
  "f10": VK_F10,
  "f12": VK_F12,
  "f15": VK_F15,
  "help": VK_Help,
  "home": VK_Home,
  "pageup": VK_PageUp,
  "forwarddelete": VK_ForwardDelete,
  "f4": VK_F4,
  "end": VK_End,
  "f2": VK_F2,
  "pagedown": VK_PageDown,
  "f1": VK_F1,
  "leftarrow": VK_LeftArrow,
  "rightarrow": VK_RightArrow,
  "downarrow": VK_DownArrow,
  "uparrow": VK_UpArrow,
  "section": VK_ISO_Section,
  "yen": VK_JIS_Yen,
  "underscore": VK_JIS_Underscore,
  "keypadcomma": VK_JIS_KeypadComma,
  "eisu": VK_JIS_Eisu,
  "kana": VK_JIS_Kana
}

function parseShortcutKey(text) {
	var modifiers = [], key, modifier
	for (var i = 0, len = text.length; i < len; i++) {
		key = text[i]
		modifier = modifierMap[key]
		if (modifier) {
		    modifiers.push(modifier)
		} else {
			break
		}
	}
	key = text.substring(i).toLowerCase()
	code = keyCodeMap[key]
	return {key: key, code: code, using: modifiers}
}


function addSparkAppHotKey(se, name, shortcut, path) {
  var sparkProc = se.processes['Spark']
  sparkProc.frontmost = true
  se.keystroke('2', { using: 'command down' })
  delay(1)
  se.keyCode(VK_Tab)
  var parsed = parseShortcutKey(shortcut)
  se.keyCode(parsed.code, { using: parsed.using })
  se.keyCode(VK_Tab)
  se.keystroke(name)

  sparkProc.windows[0].sheets[0].groups[0].buttons['Choose…'].click()
  se.keyCode(VK_ANSI_3, { using: 'command down' })
  delay(1)
  se.keystroke(path)
  delay(1)
  se.keyCode(VK_Return)
  delay(1)
  se.keyCode(VK_Return)
  delay(1)
  se.keyCode(VK_Return)
}

function addSparkAppHotKeys(configs) {
  var sparkApp = Application('Spark')
  sparkApp.activate()

  var se = Application('System Events')
  var sparkProc = se.processes['Spark']
  sparkProc.frontmost = true
  try {
    sparkProc.windows[0].sheets[0].buttons['Continue'].click()
  } catch (e) {}

  configs.forEach(function(config) {
    addSparkAppHotKey(se, config.name, config.shortcut, config.path)
  })
  delay(0.5)
  sparkApp.quit()
}

function run(argv) {
  addSparkAppHotKeys([
    { name: 'Finder',        shortcut: '⌃⌘R', path: '/System/Library/CoreServices/Finder.app' },
    { name: 'Safari',        shortcut: '⌃⌘S', path: '/Applications/Safari.app' },
    { name: 'MacPass',       shortcut: '⌃⌘1', path: '/Applications/MacPass.app' },
    { name: 'Google Chrome', shortcut: '⌃⌘C', path: '/Applications/Google Chrome.app' },
    { name: 'Firefox',       shortcut: '⌃⌘E', path: '/Applications/Firefox.app' },
    { name: 'iTerm',         shortcut: '⌃⌘T', path: '/Applications/iTerm.app' },
    { name: 'MacVim',        shortcut: '⌃⌘V', path: '/Applications/MacVim.app' }
  ])
}
EOF
}

install_go() {
  download_url=https://storage.googleapis.com/golang/go1.4.2.darwin-amd64-osx10.8.pkg
  pkg_file=${download_url##*/}
  curl -LO $download_url
  sudo installer -pkg $pkg_file -target /
  rm $pkg_file
}

install_go_tools() {
  cat <<'EOF' >> ~/.bash_profile
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

. $HOME/.bashrc
EOF
  . ~/.bash_profile
  mkdir -p $GOPATH
  go get -u golang.org/x/tools/cmd/goimports
  go get -u github.com/nsf/gocode
  go get -u github.com/golang/lint/golint
  go get -u github.com/jstemmer/gotags
  go get -u github.com/monochromegane/the_platinum_searcher/...
}

install_kaoriya_macvim() {
  download_url=https://github.com/splhack/macvim-kaoriya/releases/download/20150314/macvim-kaoriya-20150314.dmg
  dmg_file=${download_url##*/}

  curl -LO $download_url
  mount_dir=`hdiutil attach $dmg_file | awk 'END{print $NF}'`
  sudo /usr/bin/ditto $mount_dir/MacVim.app /Applications/MacVim.app
  hdiutil detach $mount_dir
  rm $dmg_file
}

config_vim() {
  mkdir -p ~/.vim/bundle
  git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
  cat <<'EOF' > ~/.vimrc
set nocompatible
filetype off
filetype plugin indent off

set noswapfile
set nobackup
set noundofile

" adjust width for full width characters
set ambiwidth=double

" for Vundle {{{
if has('win32')
    let s:vim_home=expand('~/vimfiles')
else
    let s:vim_home=expand('~/.vim')
endif
if has('vim_starting')
    let &runtimepath.=printf(',%s/bundle/Vundle.vim', s:vim_home)
endif
call vundle#begin()

" let Vundle manage Vundle, required
Plugin 'gmarik/Vundle.vim'

Plugin 'dgryski/vim-godef'

call vundle#end()
filetype plugin on
" }}}

" for golang {{{
set rtp^=$GOPATH/src/github.com/nsf/gocode/vim
set path+=$GOPATH/src/**
let g:gofmt_command = 'goimports'
au BufWritePre *.go Fmt
au BufNewFile,BufRead *.go set sw=4 noexpandtab ts=4 completeopt=menu,preview
au FileType go compiler go
" }}}

au FileType javascript setl sw=2 ts=2 et
au FileType html setl sw=2 ts=2 et
au FileType markdown setl sw=2 ts=2 et

au FileType ruby setl sw=2 ts=2 et
au FileType yaml setl sw=2 ts=2 et
au FileType python setl sw=4 ts=4 et
au FileType lua setl sw=4 ts=4 et

" no wrap
set textwidth=0

" change cursor on insert mode
au InsertEnter * set cul
au InsertLeave * set nocul

set fileencodings=utf-8,cp932,euc-jp,iso-2022-jp,default,latin

" Disabled: Use tmux clipboard copy&paste feature instead of vim's.
"set clipboard=unnamed,autoselect

set grepprg=pt\ -e\ --nocolor
autocmd QuickFixCmdPost *grep* cwindow
EOF
  cat <<'EOF' > ~/.gvimrc
set lines=60
EOF
}

config_git() {
  cat <<'EOF' >> ~/.bashrc
alias g=git
EOF
  cat <<'EOF' > ~/.gitconfig
[user]
	name = Hiroaki Nakamura
	email = hnakamur@gmail.com
[core]
	excludesfile = ~/.gitignore
	editor = vim
[merge]
	ff = true
[log]
	date = local
[push]
	default = simple
[alias]
	a = add
	co = checkout
	ci = commit -v
	b = branch
	d = diff -w
	di = diff
	f = fetch --all --prune
	l = log
	me = merge
	s = status -s
	lga = log --graph --all --abbrev-commit --pretty=format:'%x09 %Cred%h%Creset %Cgreen%ai %C(bold blue)(%an) -%C(yellow)%d%Creset %s%Creset'
	lg  = log --graph --abbrev-commit --pretty=format:'%x09 %Cred%h%Creset %Cgreen%ai %C(bold blue)(%an) -%C(yellow)%d%Creset %s%Creset'
	conflicts = diff --name-only --diff-filter=U
	delete-merged-branches = !git branch --merged | grep -v \\* | xargs -n 1 git branch -d

[pager]
	log = diff-highlight | less
	show = diff-highlight | less
	diff = diff-highlight | less
[credential]
	helper = osxkeychain
EOF

  pip install diff-highlight
}

add_japanese_input_source() {
  /usr/bin/osascript - <<'EOF'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preference.keyboard"
	reveal anchor "InputSources" of current pane
end tell
tell application "System Events" to tell process "System Preferences"
	tell window "キーボード"
		click button 1 of group 1 of tab group 1
		delay 1
		tell sheet 1
			select row 2 of table 1 of scroll area 2 -- 日本語
			delay 1
			select row 2 of table 1 of scroll area 1 -- ひらがな (Google)
			click button "追加"
		end tell
	end tell
end tell
delay 0.5
tell application "System Preferences" to quit
EOF
}

set_screen_lock_timing_to_immediate() {
  /usr/bin/osascript - <<'EOF'
tell application "System Preferences"
	activate
	panes
	set current pane to pane "com.apple.preference.security"
	reveal anchor "General" of current pane
end tell
tell application "System Events" to tell process "System Preferences"
	tell tab group 1 of window "セキュリティとプライバシー"
		-- "スリープとスクリーンセーバの解除にパスワードを要求　開始後："の開始後を「すぐに」に変更
		click pop up button 1
		click menu item 1 of menu of pop up button 1
	end tell
end tell
delay 0.5
tell application "System Preferences" to quit
EOF
}

set_osx_defaults() {
  defaults write com.apple.finder AppleShowAllFiles -boolean true
  defaults write com.apple.finder DSDontWriteNetworkStores -string true
  defaults write osx_defaults_system_ui_server_values disable-shadow -boolean true
}

configure_keyboard
swap_caps_and_control_keys
change_next_window_shortcut
configure_trackpad
enable_trackpad_drag_lock

install_xcode
install_xcode_cmdline_tools

setup_homebrew
add_spark_app_shortcuts
register_macpass_shortcut

install_go
install_go_tools
install_kaoriya_macvim
config_vim
config_git
add_japanese_input_source
set_screen_lock_timing_to_immediate
set_osx_defaults
