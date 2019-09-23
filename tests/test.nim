import ../src/terminal

# chcp 65001 # set output to unicode

echo "new terminal"
var vt = newVideoTerminal(40, 10)
vt.dump()

echo "print some text"
vt = newVideoTerminal(40, 10)
discard vt.input("hi there how are you? ░ ░ ░")
vt.dump()

echo "4 lines, overwrite the 4th"
vt = newVideoTerminal(40, 10)
discard vt.input("\nline1\nline2\nline3\nline4")
discard vt.input("\x08\x08\x08\x08\x08overwrite")
vt.dump()

echo "some text then clear"
vt = newVideoTerminal(40, 10)
discard vt.input("this all will clear\ec")
vt.dump()

echo "text on 5th line with extra params"
vt = newVideoTerminal(40, 10)
discard vt.input("\e[5;99;88;77Bhi there!")
vt.dump()

echo "move about the screen"
vt = newVideoTerminal(40, 10)
discard vt.input("\e[20G\e[5dr")
discard vt.input("\e[1Au")
discard vt.input("\e[2B\e[1Dd\e[1A\e[0Cl")
discard vt.input("\e[9;39H*")
vt.dump()

echo "tab stops"
vt = newVideoTerminal(40, 10)
echo vt.tabStops
discard vt.input("1\e[1I2\e[1I3\e[1I4")
discard vt.input("\n1\t2\t3\t4")
vt.dump()

echo "clear screen"
vt = newVideoTerminal(40, 10)
for i in 0 ..< vt.text.len:
  discard vt.input("X")
discard vt.input("\e[3;3H\e[1J")
vt.dump()
discard vt.input("\e[7;37H\e[0J")
vt.dump()
discard vt.input("\e[2J")
vt.dump()

echo "clear line"
vt = newVideoTerminal(40, 10)
for i in 0 ..< vt.text.len:
  discard vt.input("X")
discard vt.input("\e[3;3H\e[1K")
vt.dump()
discard vt.input("\e[3;37H\e[0K")
vt.dump()
discard vt.input("\e[2K")
vt.dump()

echo "save and restore"
vt = newVideoTerminal(40, 10)
discard vt.input("\e7")
for i in 0 ..< vt.text.len:
  discard vt.input("S")
vt.dump()
discard vt.input("\e8")
vt.dump()

echo "line scroll down"
vt = newVideoTerminal(40, 10)
for i in 0 ..< 10:
  discard vt.input("Line: " & $i & "\n")
vt.dump()
discard vt.input("\e[1;0H")
discard vt.input("\e[7L")
vt.dump()

echo "line scroll up"
vt = newVideoTerminal(40, 10)
for i in 0 ..< 10:
  discard vt.input("Line: " & $i & "\n")
vt.dump()
discard vt.input("\e[4;0H")
discard vt.input("\e[4M")
vt.dump()

echo "scroll up"
vt = newVideoTerminal(40, 10)
for i in 0 ..< 10:
  discard vt.input("Line: " & $i & "\n")
vt.dump()
discard vt.input("\e[4S")
vt.dump()

echo "scroll down"
vt = newVideoTerminal(40, 10)
for i in 0 ..< 10:
  discard vt.input("Line: " & $i & "\n")
vt.dump()
discard vt.input("\e[3T")
vt.dump()

echo "characters at cursor (overwrite with spaces)"
vt = newVideoTerminal(40, 10)
for i in 0 ..< vt.text.len:
  discard vt.input("X")
discard vt.input("\e[4;0H")
discard vt.input("\e[20X")
vt.dump()

echo "Go to previous tab stop"
vt = newVideoTerminal(40, 10)
discard vt.input("1aa\e[1I2aa\e[1I3aa")
vt.dump()
discard vt.input("\e[Z4bb")
vt.dump()

echo "Repeat previous character P1 times"
vt = newVideoTerminal(40, 10)
for i in 0 ..< vt.text.len:
  discard vt.input("X")
discard vt.input("\e[4;0Hy")
vt.dump()
discard vt.input("\e[20b")
vt.dump()

echo "Get cursor pos"
vt = newVideoTerminal(40, 10)
discard vt.input("\e[5;5H")
echo vt.input("\e[6n")

