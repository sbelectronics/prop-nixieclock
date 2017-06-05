OBJ
  serial : "FullDuplexSerial"
  'pst : "Parallax Serial Terminal"

VAR
  long myStack[32]
  long char
  long hour
  long minute
  long second
  long year
  long month
  long day

PUB Start (rxpin, txpin, mode, baudrate)
  hour := 12
  minute := 34
  'pst.start(115200)
  serial.Start(rxpin, txpin, mode, baudrate)
  cognew(ParseLoop, @myStack)
  return @hour

PUB SkipComma(count)
  repeat while (count > 0)
      char := serial.rx
      'pst.Char(char)
      if (char == ",")
          count := count - 1
      if (char == "$")
          return False
  return True

PUB ReadTwoDigit(addr) | v
  char := serial.rx
  'pst.Char(char)
  if (char < "0") or (char > "9")
      return False

  v := (char-48) * 10

  char := serial.rx
  'pst.Char(char)
  if (char < "0") or (char > "9")
      return False

  v := v+ (char - 48)

  long[addr] := v

  return True

PUB ParseGPR
  char := serial.rx
  'pst.Char(char)
  if (char <> "M")
      return

  char := serial.rx
  'pst.Char(char)
  if (char <> "C")
      return

  char := serial.rx
  'pst.Char(char)
  if (char <> ",")
      return

  if !ReadTwoDigit(@hour)
      return

  if !ReadTwoDigit(@minute)
      return

  if !ReadTwoDigit(@second)
      return

  if !SkipComma(8)
      return False

  if !ReadTwoDigit(@day)
      return

  if !ReadTwoDigit(@month)
      return

  if !ReadTwoDigit(@year)
      return

  'pst.Dec(day)
  'pst.Dec(month)
  'pst.Dec(year)

PUB ParseGPS
  char := serial.rx
  if (char <> "G")
      return
      
  char := serial.rx
  if (char <> "P")
      return

  char :=serial.rx
  if (char == "R")
      ParseGPR  

PUB ParseLoop
  char := serial.rx
  repeat
      if (char=="$")
          ParseGPS
      else
          char := serial.rx

          
    