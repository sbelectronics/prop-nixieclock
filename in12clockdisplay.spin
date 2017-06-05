CON
   SEL1 = 23
   SEL2 = 22

   DIG0 = 0
   DIG0D = 3
   DIG1 = 4
   DIG1D = 7

   BLK = 4_000 ' 250 us blanking
   DSP = 1_000 ' 1 ms display

VAR
   long hours
   long minutes
   long myStack[16]

PUB Start
    cognew(ShowValue, @myStack)

PUB SetMinutes(x)
    minutes := x

PUB SetHours(x)
    hours := x

PRI ShowValueOld
    dira[SEL1] ~~
    dira[SEL2] ~~
    dira[DIG0..DIG0D] ~~
    dira[DIG1..DIG1D] ~~
    repeat
        ' first let's do the hours
        
        ' blank
        outa[dig1D..dig1] := 11
        outa[sel1] := 0
        outa[sel2] := 0

        waitcnt(clkfreq / BLK + cnt)   ' 250us 

        ' display
        outa[dig0D..dig0] := (hours / 10)
        outa[sel1]:= 1

        waitcnt(clkfreq / DSP + cnt)    ' 1ms

        ' blank
        outa[sel1] := 0
        outa[sel2] := 0

        waitcnt(clkfreq / BLK + cnt)

        ' display
        outa[dig0D..dig0] := (hours // 10)
        outa[sel2] := 1

        waitcnt(clkfreq / DSP + cnt)

        ' now let's do the minutes 

        ' blank
        outa[dig0D..dig0] := 11
        outa[sel1] := 0      
        outa[sel2] := 0

        waitcnt(clkfreq / BLK + cnt)   ' 250us 

        ' display
        outa[dig1D..dig1] := (minutes / 10)
        outa[sel1]:= 1

        waitcnt(clkfreq / DSP + cnt)    ' 1ms

        ' blank
        outa[sel1] := 0
        outa[sel2] := 0

        waitcnt(clkfreq / BLK + cnt)

        ' display
        outa[dig1D..dig1] := (minutes // 10)
        outa[sel2] := 1

        waitcnt(clkfreq / DSP + cnt)  

PRI ShowValue
    dira[SEL1] ~~
    dira[SEL2] ~~
    dira[DIG0..DIG0D] ~~
    dira[DIG1..DIG1D] ~~
    repeat
        ' first let's do the hours
        
        ' blank
        outa[sel1] := 0
        outa[sel2] := 0

        waitcnt(clkfreq / BLK + cnt)   ' 250us 

        ' display
        outa[dig0D..dig0] := (hours / 10)
        outa[dig1D..dig1] := (minutes / 10)
        outa[sel1]:= 1

        waitcnt(clkfreq / DSP + cnt)    ' 1ms

        ' blank
        outa[sel1] := 0
        outa[sel2] := 0

        waitcnt(clkfreq / BLK + cnt)

        ' display
        outa[dig0D..dig0] := (hours // 10)
        outa[dig1D..dig1] := (minutes // 10)
        outa[sel2] := 1

        waitcnt(clkfreq / DSP + cnt)      
    