CON
  _clkmode = xtal1 + pll16x 
  _xinfreq = 5_000_000

VAR
  long hours, minutes, seconds, tzone, month, day, year, dst
  long snoopStack[16], snoopAddr

OBJ
  display : "in12clockdisplay"
  rtc : "ds1302"
  gps : "gpsdriver"
  pst : "Parallax Serial Terminal"

PUB main
    tzone := -7 ' pacific daylight offset from GMT
    hours := 12
    minutes := 34
    seconds := 0

    dst := 0

    display.Start  

    'test_fixed
    gps_clockloop

PUB check_dst(y, m, d)
    ' sometimes I'm getting nonsensical YMD values from the gps, like 11-20-26
    if (m<=0) or (m>12) or (d<=0) or (d>30) 
        return -1 ' unknown

    if (y==13)
        ' 3/10/13 to 11/3/13
        if (m<3) or (m==3) and (d<=10)
            return 0
        if (m>11) or (m==11) and (d>=3)
            return 0
        return 1

    if (y==14)
        ' 3/9/14 to 11/2/14
        if (m<3) or (m==3) and (d<=9)
            return 0
        if (m>11) or (m==11) and (d<=2)
            return 0
        return 1

    if (y==15)
        ' 3/8/15 to 11/1/15
        if (m<3) or (m==3) and (d<=8)
            return 0
        if (m>11) or (m==11) and (d<=1)
            return 0
        return 1

    if (y==16)
        ' 3/13/16 to 11/6/16
        if (m<3) or (m==3) and (d<=13)
            return 0
        if (m>11) or (m==11) and (d<=6)
            return 0
        return 1

    return -1 ' unknown    

PUB gps_clockloop | lastMinutes, t, gpsPointer
    gpsPointer := gps.start(20, 0, 9600)

    pst.start(115200)
    snoopAddr := gpsPointer+56
    cognew(snoop, @snoopStack) 
        
    repeat
        t := long[gpsPointer+40]
        day := ((t>>24) - 48) * 10 + ((t>>16) & $FF) - 48
        month := ((t>>8) & $FF - 48) * 10 + (t & $FF) - 48
        
        t := long[gpsPointer+44]
        year := ((t>>8) & $FF - 48) * 10 + (t & $FF) - 48
    
        ' we don't really need these in a 4-digit clock
        t := long[gpsPointer+12]
        seconds := ((t>>16) & $FF - 48) * 10 + ((t>>8) & $FF - 48)

        t := long[gpsPointer+8]
        minutes := ((t>>8) & $FF - 48) * 10 + (t & $FF) - 48

        hours := ((t>>24) - 48) * 10 + ((t>>16) & $FF) - 48

        t := check_dst(year, month, day)
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

        display.SetHours(hours)
        display.SetMinutes(minutes)

        waitcnt(clkfreq/20 + cnt)

PUB snoop | t
    repeat
        t := long[snoopAddr]
        if (t <> 0)
            pst.Char(t)
            long[snoopAddr] := 0

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
    display.SetMinutes(45)
    
    Repeat
        waitcnt(clkfreq / 100 + cnt) 