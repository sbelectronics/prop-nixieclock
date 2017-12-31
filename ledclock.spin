CON
  _clkmode = xtal1 + pll16x 
  _xinfreq = 5_000_000

VAR
  long hours, minutes, seconds, tzone, month, day, year, dst, last_seconds

OBJ
  display : "7segdouble"
  rtc : "ds1302"
  gps : "gpsdriver2"
  'pst : "Parallax Serial Terminal"  

PUB main
    tzone := -7 ' pacific daylight offset from GMT
    hours := 12
    minutes := 34
    seconds := 0
    last_seconds := -1

    dst := 0

    display.Start(8, 0, 4)

    'pst.start(115200)

    'test_fixed
    gps_clockloop

' DST check, see https://forums.parallax.com/discussion/166813/daylight-saving-time-calculation-in-spin
PUB check_dst(y, m, d, h) | i,bSaving
   ' sometimes I'm getting nonsensical YMD values from the gps, like 11-20-26  
   if (m=<0) or (m>12) or (d=<0) or (d>31) 
        return -1 ' unknown
        
   y := y + 2000
   m := m - 1
   bSaving := false

    'Appears to be valid from 1987
   if (y=>2007) 
      case (m)
        2:  'DST begins in March on second Sunday at 2 AM
          i:=14-(1+y*5/4)//7
          if (d>i) OR ((d==i) AND (h>1))
            bSaving:=true
        3..9:  'April to October is DST
          bSaving:=true
        10:  'DST ends in November on first sunday at 2 AM
          i:=7-(1+y*5/4)//7
          if NOT ((d>i) OR ((d==i) AND (h>1)))
            bSaving:=true
   else
      case (m)
        3:  'DST begins in April
          i:=1+(2+6*y-y/4)//7
          if (d>i) OR ((d==i) AND (h>1))
            bSaving:=true
        3..8:  'April to September is DST
          bSaving:=true
        9:  'DST ends in October
          i:=31-(y*5/4)//7
          if NOT((d>i) OR ((d==i) AND (h>1)))
            bSaving:=true
   if bSaving
        return 1
   else
        return 0

PUB gps_clockloop | lastMinutes, t, gpsPointer
    gpsPointer := gps.start(20, 21, 0, 9600)
        
    repeat
        hours := long[gpsPointer]
        minutes := long[gpsPointer+4]
        seconds := long[gpsPointer+8]
        year := long[gpsPointer+12]
        month := long[gpsPointer+16]
        day := long[gpsPointer+20]

        t := check_dst(year, month, day, hours)
        if (t==0)
            dst := -1
        elseif (t==1)
            dst := 0

        ' adjust time zone
        hours := hours + tzone + dst
        if (hours < 0)
            hours := hours + 24

        ' convert from 24H to 12H
        if (hours > 12)
            hours := hours - 12

        display.SetMinutes(minutes)
        display.SetHours(hours)
        
        ' uncomment if we want the colon to blink
        ' display.SetDot(1, seconds & 1)
        ' display.SetDot(2, seconds & 1)

        ' uncomment if we want solid colon
        display.SetDot(1, 1)
        display.SetDot(2, 1)

        waitcnt(clkfreq/20 + cnt)

PUB ds1302_clockloop | lastMinutes
    rtc.init(16,18,17)
    rtc.config
    rtc.setDateTime(1, 17, 07, 3, 22, 21, 0) 
    lastMinutes := 61
    repeat
        rtc.readTime(@hours, @minutes, @seconds)
        display.SetMinutes(minutes)
        display.SetHours(hours)
        waitcnt(clkfreq/20 + cnt)
    

PUB test_increment
    ' increments the minutes digit 10 times per second

    hours:=0
    minutes:=0
    Repeat
        minutes:=minutes + 1
        if (minutes=>60)
            minutes:=0
            hours:=hours + 1
            if (hours=>24)
                hours:=0
        display.SetMinutes(minutes)
        display.SetHours(hours)
        waitcnt(clkfreq / 100 + cnt)

PUB test_fixed
    
    display.SetHours(12)
    display.SetMinutes(34)
    display.SetDot(1,1)
    display.SetDot(2,1)
    
    Repeat
        waitcnt(clkfreq / 100 + cnt) 