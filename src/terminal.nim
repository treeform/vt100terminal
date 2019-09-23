# terminal state machine library
import unicode, strutils, print, algorithm

const
  KEY_UP* =             "\e[A"
  KEY_DOWN* =           "\e[B"
  KEY_RIGHT* =          "\e[C"
  KEY_LEFT* =           "\e[D"
  KEY_HOME* =           "\e[H"
  KEY_END* =            "\e[Y"
  KEY_INSERT* =         "\e[L"
  KEY_BACKSPACE* =      "\x08"
  KEY_ESCAPE* =         "\x1b"
  KEY_BACK_TAB* =       "\e[Z"
  KEY_PAGE_UP* =        "\e[V"
  KEY_PAGE_DOWN* =      "\e[U"
  KEY_F1* =             "\eOP"
  KEY_F2* =             "\eOQ"
  KEY_F3* =             "\eOR"
  KEY_F4* =             "\eOS"
  KEY_F5* =             "\eOT"
  KEY_F6* =             "\eOU"
  KEY_F7* =             "\eOV"
  KEY_F8* =             "\eOW"
  KEY_F9* =             "\eOX"
  KEY_F10* =            "\eOY"

type VideoTerminal* = ref object
  width*: int
  height*: int
  cursorX*: int
  cursorY*: int
  text*: seq[Rune]
  colors*: seq[uint8]
  bell*: bool
  tabStops*: seq[int]
  saved*: VideoTerminal
  prevRune*: Rune
  cursorVisable*: bool

proc repeat(s: string, n: int): string =
  for i in 0 ..< n:
    result.add s

proc between(minv, v, maxv: int): int =
  if v < minv: return minv
  if v > maxv: return maxv
  return v

proc newVideoTerminal*(width, height: int): VideoTerminal =
  var vt = VideoTerminal()
  vt.width = width
  vt.height = height
  vt.text = newSeq[Rune](vt.width * vt.height)
  vt.colors = newSeq[uint8](vt.width * vt.height)
  vt.cursorVisable = true
  var i = 8
  while i < vt.width:
    vt.tabStops.add(i)
    i += 8
  return vt

proc at(vt: VideoTerminal): int =
  vt.cursorY * vt.width + vt.cursorX

proc atLineStart(vt: VideoTerminal): int =
  vt.cursorY * vt.width

proc atLineEnd(vt: VideoTerminal): int =
  vt.cursorY * vt.width + vt.width


proc advance(vt: VideoTerminal) =
  inc vt.cursorX
  if vt.cursorX >= vt.width:
    inc vt.cursorY
    vt.cursorX = 0

proc clear(vt: VideoTerminal, start, stop: int) =
  for i in start ..< stop:
    vt.text[i] = Rune(0)
    vt.colors[i] = 0

proc moveLine(vt: VideoTerminal, a, b: int) =
  for x in 0 ..< vt.width:
    if a < 0 or a >= vt.height: continue
    if b >= 0 and b < vt.height:
      vt.text[a * vt.width + x] = vt.text[b * vt.width + x]
      vt.colors[a * vt.width + x] = vt.colors[b * vt.width + x]
    else:
      vt.text[a * vt.width + x] = Rune(0)
      vt.colors[a * vt.width + x] = 0

proc clearLine(vt: VideoTerminal, a: int) =
  if a < 0 or a >= vt.height: return
  for x in 0 ..< vt.width:
    vt.text[a * vt.width + x] = Rune(0)
    vt.colors[a * vt.width + x] = 0

proc saveState(vt: VideoTerminal) =
  vt.saved = VideoTerminal()
  vt.saved.cursorX = vt.cursorX
  vt.saved.cursorY = vt.cursorY
  vt.saved.text = vt.text
  vt.saved.colors = vt.colors

proc restoreState(vt: VideoTerminal) =
  if vt.saved != nil:
    vt.cursorX = vt.saved.cursorX
    vt.cursorY = vt.saved.cursorY
    vt.text = vt.saved.text
    vt.colors = vt.saved.colors
    vt.saved = nil

proc input*(vt: VideoTerminal, s: string): string =
  let runes = toRunes(s)
  var i = 0
  while i < runes.len:
    let c = runes[i]
    case c:
      of Rune(7): # Bell
        vt.bell = true
      of Rune(8): # Cursor left one cell
        dec vt.cursorX
        if vt.cursorX < 0:
          vt.cursorX = 0
      of Rune(9): # Cursor to next tab stop or end of line
        for tab in vt.tabStops & @[vt.width]:
          if tab > vt.cursorX:
            vt.cursorX = tab
            break
      of Rune(10): # Cursor to same column one line down, scroll if needed
        inc vt.cursorY
        vt.cursorX = 0
      of Rune(13): # Cursor to same column one line down, scroll if needed
        vt.cursorX = 0
      of Rune(27): # escape
        inc i
        let c = runes[i]
        case $c:
          of "H": # Set a tabstop in this colum
            vt.tabStops.add vt.cursorX
            vt.tabStops.sort()
          of "7": # Save cursor position and current graphical state
            vt.saveState()
          of "8": # Save cursor position and current graphical state
            vt.restoreState()
          of "c": # Reset terminal to default stat
            vt.cursorX = 0
            vt.cursorX = 0
            vt.clear(0, vt.text.len)
          of "[":
            inc i
            var params: seq[int]
            var number: string
            while true:
              if $(runes[i]) in "0123456789":
                number.add($runes[i])
              else:
                if number.len > 0:
                  params.add(parseInt(number))
                  number = ""
                if $(runes[i]) != ";":
                  break
              inc i
            let c = runes[i]
            #print $c, params
            case $c:
              of "A": # Cursor up # rows
                vt.cursorY -= params[0]
              of "B": # Cursor down # rows
                vt.cursorY += params[0]
              of "C": # Cursor right # columns
                vt.cursorX += params[0]
              of "D": # Cursor left # columns
                vt.cursorX -= params[0]
              of "E": # Cursor to first column of line # rows down from current
                vt.cursorX = 0
                vt.cursorY += params[0]
              of "F": # Cursor to first column of line # rows down from current
                vt.cursorX = 0
                vt.cursorY -= params[0]
              of "G": # Cursor to column #
                vt.cursorX = params[0]
              of "d": # Cursor to row #
                vt.cursorY = params[0]
              of "H", "f": # Cursor to row #1, column #2
                vt.cursorY = params[0]
                vt.cursorX = params[1]
              of "I": # Cursor to next tab stop
                for tab in vt.tabStops:
                  if tab > vt.cursorX:
                    vt.cursorX = tab
                    break
              of "J": # Clear screen
                case params[0]:
                  of 0: # Clear screen from cursor to end of screen
                    vt.clear(vt.at, vt.text.len)
                  of 1: # Clear screen from beginning of screen to cursor
                    vt.clear(0, vt.at)
                  of 2: # Clear entire screen
                     vt.clear(0, vt.text.len)
                  else:
                    discard
              of "K": # Clear line
                case params[0]:
                  of 0: # Clear line from cursor to end of line
                    vt.clear(vt.at, vt.atLineEnd)
                  of 1: # Clear line from beginning of line to cursor
                    vt.clear(vt.atLineStart, vt.at)
                  of 2: # Clear entire line
                     vt.clear(vt.atLineStart, vt.atLineEnd)
                  else:
                    discard
              of "L": # Insert # lines at cursor, scrolling lines below down
                for l in 1 .. vt.height - params[0] - vt.cursorY:
                  vt.moveLine(vt.height - l, vt.height - params[0] - l)
                for l in 0 ..< params[0]:
                  vt.clearLine(vt.cursorY + l)
              of "M": # Delete P1 lines at cursor, scrolling lines below up
                for l in vt.cursorY ..< vt.height:
                  vt.moveLine(l, l + params[0])
              of "S": # Scroll screen up P1 lines
                for l in 0 ..< vt.height:
                  vt.moveLine(l, l + params[0])
              of "T": # Scroll screen down P1 lines
                for l in 1 .. vt.height - params[0]:
                  vt.moveLine(vt.height - l, vt.height - params[0] - l)
                for l in 0 ..< params[0]:
                  vt.clearLine(l)
              of "X": # Scroll screen down P1 lines
                for i in 0 ..< params[0]:
                  vt.text[vt.at] = Rune(' ')
                  vt.advance()
              of "Z": # Go to previous tab stop
                var cursorX = 0
                for tab in vt.tabStops:
                  if tab < vt.cursorX:
                    cursorX = tab
                  else:
                    break
                vt.cursorX = cursorX
              of "b": # Repeat previous character P1 times
                for i in 0 ..< params[0]:
                  vt.text[vt.at] = vt.prevRune
                  vt.advance()
              of "c": # Callback with "\e[?6c"
                return "\e[?6c"
              of "g": # If P1 == 3, clear all tabstops
                if params[0] == 3:
                  vt.tabStops.setLen(0)
              of "h": # If P1 == 25, show the cursor
                if params[0] == 25:
                  vt.cursorVisable = true
              #of "m":
              of "l":
                if params[0] == 25:
                  vt.cursorVisable = false
              of "n":
                if params[0] == 6:
                  return "\e[" & $vt.cursorY & ";" & $vt.cursorX & "R"
              of "s":
                vt.saveState()
              of "u":
                vt.restoreState()
              #of "@": #Insert P1 blank spaces at cursor, moving characters to the right over

              else:
                print "unkown code", $c, params
        vt.cursorX = between(0, vt.cursorX, vt.width)
        vt.cursorY = between(0, vt.cursorY, vt.height)
      else:
        vt.prevRune = c
        vt.text[vt.at] = c
        vt.advance()
    inc i



proc dump*(vt: VideoTerminal) =
  ## Dumps terminal window to terminal
  echo "╔" & "═".repeat(vt.width) & "╗"
  for y in 0 ..< vt.height:
    var row = "║"
    for x in 0 ..< vt.width:
      let c = vt.text[y * vt.width + x]
      if c != Rune(0):
        row.add c
      else:
        row.add " "
    row.add "║"
    echo row
  echo "╚" & "═".repeat(vt.width) & "╝"

