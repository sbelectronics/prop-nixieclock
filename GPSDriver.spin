''********************************************
''*             GPS Driver v0.1              *
''*         By: Ryan David, 2/21/10          *
''*                                          *
''*     - a derivative work based on -       *
''*                                          *
''*     Full-Duplex Serial Driver v1.2       *
''*      By: Chip Gracey, Jeff Martin        *
''*                                          *
''*   Creates a single cog to receive and    *
''*    parse the data at the same time.      *
''*  Currently it only parses RMC and GGA,   *
''* but more messages could be easily added. *
''*    Tested at 115200 baud with a 10Hz     *
''*         position update rate             *
''*                                          *
''*    See end of file for terms of use.     *
''********************************************

{-----------------REVISION HISTORY-----------------
 v0.1 - 2/23/2010, first official release.
}

VAR
  long  cog

  long rx_pin
  long rxtx_mode
  long bit_ticks

  long Course
  long Speed
  long TimeStamp[2]
  long Flags
  long Latitude[2]
  long Longitude[3]
  long Date[2]
  long Satellites
  long Altitude
  long DataByte

PUB start(rxpin, mode, baudrate)
'' mode bit 0 = invert rx
'' mode bit 1 = invert tx
'' mode bit 2 = open-drain/source tx
'' mode bit 3 = ignore tx echo on rx

  stop
  longmove(@rx_pin, @rxpin, 1)
  bit_ticks := clkfreq / baudrate
  date[0]:=960051513 ' 9999
  date[1]:=960051513
  cog := cognew(@entry, @rx_pin) + 1

  return @Course

PUB stop
  if cog
    cogstop(cog~ - 1)
DAT
                        org

'---------------------------------------------------------------------------------------
' Intialize Serial and GPS Hub pointers                                                -
'---------------------------------------------------------------------------------------
entry                   mov     t1,par                'get structure address

                        rdlong  t2,t1                 'get rx_pin
                        mov     rxmask,#1
                        shl     rxmask,t2

                        add     t1,#4                 'get rxtx_mode
                        rdlong  rxtxmode,t1

                        add     t1,#4                 'get bit_ticks
                        rdlong  bitticks,t1

                        add     t1,#4                 'get Course pointer
                        mov     t3,t1

                        add     t1,#4                 'get Speed pointer
                        mov     t4,t1

                        add     t1,#4                 'get Timestamp[0] pointer
                        mov     t5,t1

                        add     t1,#4                 'get Timestamp[1] pointer
                        mov     t6,t1

                        add     t1,#4                 'get Flags pointer
                        mov     t7,t1

                        add     t1,#4                 'get Latitude[0] pointer
                        mov     t8,t1

                        add     t1,#4                 'get Latitude[1] pointer
                        mov     t9,t1

                        add     t1,#4                 'get Longitude[0] pointer
                        mov     t10,t1

                        add     t1,#4                 'get Longitude[1] pointer
                        mov     t11,t1

                        add     t1,#4                 'get Longitude[2] pointer
                        mov     t12,t1

                        add     t1,#4                 'get Date[0] pointer
                        mov     t13,t1

                        add     t1,#4                 'get Date[1] pointer
                        mov     t14,t1

                        add     t1,#4                 'get Satellites pointer
                        mov     t15,t1

                        add     t1,#4                 'get Altitude pointer
                        mov     t16,t1

                        add     t1, #4
                        mov     t17,t1

'---------------------------------------------------------------------------------------
' Serial Receive Code                                                                  -
'---------------------------------------------------------------------------------------
receive                 test    rxtxmode,#%001  wz    'wait for start bit on rx pin
                        test    rxmask,ina      wc
        if_z_eq_c       jmp     #receive

                        mov     rxbits,#9             'ready to receive byte
                        mov     rxcnt,bitticks
                        shr     rxcnt,#1
                        add     rxcnt,cnt                          

:bit                    add     rxcnt,bitticks        'ready next bit period

:wait                   mov     t1,rxcnt              'check if bit receive period done
                        sub     t1,cnt
                        cmps    t1,#0           wc
        if_nc           jmp     #:wait

                        test    rxmask,ina      wc    'receive bit on rx pin
                        rcr     rxdata,#1
                        djnz    rxbits,#:bit

                        shr     rxdata,#32-9          'justify and trim received byte
                        and     rxdata,#$FF
                        test    rxtxmode,#%001  wz    'if rx inverted, invert byte
        if_nz           xor     rxdata,#$FF
                        wrlong  rxdata, t17


'---------------------------------------------------------------------------------------
' GPS Code                                                                             -
'---------------------------------------------------------------------------------------
                        add     sent_pos, #1            'increment position in GPS sentence

                        cmp     rxdata, #$24    wz      'is the recieved byte the start of a GPS sentence?
        if_nz           jmp     #:det_msgID
                        mov     sent_pos, #0            'Reset position in GPS sentence
                        mov     msgID, #0               'change message ID to undetermined
                        jmp     #receive

:det_msgID              cmp     msgID, #0       wz      'did we already figure out what message ID this is?
        if_nz           jmp     #process
                        cmp     sent_pos, #4    wc      'check to see if this is the middle character of a message ID
        if_c            jmp     #receive

:checkG                 cmp     rxdata, #71     wz      'check to see if middle character is 'G'
        if_nz           jmp     #:checkM
                        mov     msgID, #2               'set message ID to 2, GGA
                        jmp     #receive

:checkM                 cmp     rxdata, #77     wz      'check to see if middle character is 'M'
        if_nz           jmp     #receive
                        mov     msgID, #3               'set message ID to 1, RMC
                        jmp     #receive


'----------------------------- Message Processing Code ---------------------------------
process                 cmp     msgID, #2       wz      'check to see if the message ID is GGA
        if_z            jmp     #:gga                   'jump to GGA processing
                        cmp     msgID, #3       wz      'check to see if the message ID is RMC
        if_z            jmp     #:rmc                   'jump to RMC processing
                        jmp     #receive                'Should never reach this!

:rmc  '----------------------------------------------------------------------------------
                        cmp     sent_pos, #7    wz      'Jump To appropriate section
        if_z            jmp     #:r7
                        cmp     sent_pos, #8    wz
        if_z            jmp     #:r8
                        cmp     sent_pos, #9    wz
        if_z            jmp     #:r9
                        cmp     sent_pos, #10   wz
        if_z            jmp     #:r10
                        cmp     sent_pos, #11   wz
        if_z            jmp     #:r11
                        cmp     sent_pos, #12   wz
        if_z            jmp     #:r12
                        cmp     sent_pos, #14   wz
        if_z            jmp     #:r14
                        cmp     sent_pos, #20   wz
        if_z            jmp     #:r20
                        cmp     sent_pos, #21   wz
        if_z            jmp     #:r21
                        cmp     sent_pos, #22   wz
        if_z            jmp     #:r22
                        cmp     sent_pos, #23   wz
        if_z            jmp     #:r23
                        cmp     sent_pos, #25   wz
        if_z            jmp     #:r25
                        cmp     sent_pos, #26   wz
        if_z            jmp     #:r26
                        cmp     sent_pos, #27   wz
        if_z            jmp     #:r27
                        cmp     sent_pos, #28   wz
        if_z            jmp     #:r28
                        cmp     sent_pos, #30   wz
        if_z            jmp     #:r30
                        cmp     sent_pos, #32   wz
        if_z            jmp     #:r32
                        cmp     sent_pos, #33   wz
        if_z            jmp     #:r33
                        cmp     sent_pos, #34   wz
        if_z            jmp     #:r34
                        cmp     sent_pos, #35   wz
        if_z            jmp     #:r35
                        cmp     sent_pos, #36   wz
        if_z            jmp     #:r36
                        cmp     sent_pos, #38   wz
        if_z            jmp     #:r38
                        cmp     sent_pos, #39   wz
        if_z            jmp     #:r39
                        cmp     sent_pos, #40   wz
        if_z            jmp     #:r40
                        cmp     sent_pos, #41   wz
        if_z            jmp     #:r41
                        cmp     sent_pos, #43   wz
        if_z            jmp     #:r43
                        cmp     sent_pos, #45   wz
        if_z            jmp     #:r45
                        cmp     sent_pos, #46   wz
        if_z            jmp     #:r46
                        cmp     sent_pos, #47   wz
        if_z            jmp     #:r47
                        cmp     sent_pos, #49   wz
        if_z            jmp     #:r49
                        cmp     sent_pos, #51   wz
        if_z            jmp     #:r51
                        cmp     sent_pos, #52   wz
        if_z            jmp     #:r52
                        cmp     sent_pos, #53   wz
        if_z            jmp     #:r53
                        cmp     sent_pos, #55   wz
        if_z            jmp     #:r55
                        cmp     sent_pos, #57   wz
        if_z            jmp     #:r57
                        cmp     sent_pos, #58   wz
        if_z            jmp     #:r58
                        cmp     sent_pos, #59   wz
        if_z            jmp     #:r59
                        cmp     sent_pos, #60   wz
        if_z            jmp     #:r60
                        cmp     sent_pos, #61   wz
        if_z            jmp     #:r61
                        cmp     sent_pos, #62   wz
        if_z            jmp     #:r62
                        jmp     #receive

:r7                     shl     rxdata, #24             'Hours
                        mov     scratchpad, rxdata
                        jmp     #receive

:r8                     shl     rxdata, #16             'Hours
                        add     scratchpad, rxdata
                        jmp     #receive

:r9                     shl     rxdata, #8              'Minutes
                        add     scratchpad, rxdata
                        jmp     #receive

:r10                    add     scratchpad, rxdata      'Minutes
                        wrlong  scratchpad, t5
                        jmp     #receive

:r11                    shl     rxdata, #16             'Seconds
                        mov     scratchpad, rxdata
                        jmp     #receive

:r12                    shl     rxdata, #8              'Seconds
                        add     scratchpad, rxdata
                        jmp     #receive

:r14                    add     scratchpad, rxdata      'Tenths Of Seconds
                        wrlong  scratchpad, t6
                        jmp     #receive

:r20                    shl     rxdata, #24             'Latitude 0
                        mov     scratchpad, rxdata
                        jmp     #receive

:r21                    shl     rxdata, #16             'Laditude 0
                        add     scratchpad, rxdata
                        jmp     #receive

:r22                    shl     rxdata, #8              'Laditude 0
                        add     scratchpad, rxdata
                        jmp     #receive

:r23                    add     scratchpad, rxdata      'Laditude 0
                        wrlong  scratchpad, t8
                        jmp     #receive

:r25                    shl     rxdata, #24             'Laditude 1
                        mov     scratchpad, rxdata
                        jmp     #receive

:r26                    shl     rxdata, #16             'Laditude 1
                        add     scratchpad, rxdata
                        jmp     #receive

:r27                    shl     rxdata, #8              'Laditude 1
                        add     scratchpad, rxdata
                        jmp     #receive

:r28                    add     scratchpad, rxdata      'Laditude 1
                        wrlong  scratchpad, t9
                        jmp     #receive

:r30                    shl     rxdata, #8             'North Or South
                        mov     sharedpad, rxdata
                        'wrlong  rxdata, t7
                        jmp     #receive

:r32                    shl     rxdata, #24             'Longitude 0
                        mov     scratchpad, rxdata
                        jmp     #receive

:r33                    shl     rxdata, #16             'Longitude 0
                        add     scratchpad, rxdata
                        jmp     #receive

:r34                    shl     rxdata, #8              'Longitude 0
                        add     scratchpad, rxdata
                        jmp     #receive

:r35                    add     scratchpad, rxdata      'Longitude 0
                        wrlong  scratchpad, t10
                        jmp     #receive

:r36                    shl     rxdata, #24             'Longitude 1
                        mov     scratchpad, rxdata
                        jmp     #receive

:r38                    shl     rxdata, #16             'Longitude 1
                        add     scratchpad, rxdata
                        jmp     #receive

:r39                    shl     rxdata, #8              'Longitude 1
                        add     scratchpad, rxdata
                        jmp     #receive

:r40                    add     scratchpad, rxdata      'Longitude 1
                        wrlong  scratchpad, t11
                        jmp     #receive

:r41                    wrlong  rxdata, t12             'Longitude 2
                        jmp     #receive

:r43                    'shl     rxdata, #8              'East Or West
                        add     sharedpad, rxdata
                        'wrlong  rxdata, t7
                        jmp     #receive

:r45                    shl     rxdata, #24             'Speed
                        mov     scratchpad, rxdata
                        jmp     #receive

:r46                    shl     rxdata, #16             'Speed
                        add     scratchpad, rxdata
                        jmp     #receive

:r47                    shl     rxdata, #8              'Speed
                        add     scratchpad, rxdata
                        jmp     #receive

:r49                    add     scratchpad, rxdata      'Speed
                        wrlong  scratchpad, t4
                        jmp     #receive

:r51                    shl     rxdata, #24             'Course
                        mov     scratchpad, rxdata
                        jmp     #receive

:r52                    shl     rxdata, #16             'Course
                        add     scratchpad, rxdata
                        jmp     #receive

:r53                    shl     rxdata, #8              'Course
                        add     scratchpad, rxdata
                        jmp     #receive

:r55                    add     scratchpad, rxdata      'Course
                        wrlong  scratchpad, t3
                        jmp     #receive

:r57                    shl     rxdata, #24             'Date[0]
                        mov     scratchpad, rxdata 
                        jmp     #receive

:r58                    shl     rxdata, #16             'Date[0]
                        add     scratchpad, rxdata
                        jmp     #receive

:r59                    shl     rxdata, #8              'Date[0]
                        add     scratchpad, rxdata
                        jmp     #receive

:r60                    add     scratchpad, rxdata      'Date[0]
                        wrlong  scratchpad, t13
                        jmp     #receive

:r61                    shl     rxdata, #8              'Date[1]
                        mov     scratchpad, rxdata
                        jmp     #receive

:r62                    add     scratchpad, rxdata      'Date[1]
                        wrlong  scratchpad, t14
                        jmp     #receive


:gga  '----------------------------------------------------------------------------------
                        cmp     sent_pos, #43    wz     'Jump to appropriate section
        if_z            jmp     #:g43
                        cmp     sent_pos, #45    wz
        if_z            jmp     #:g45
                        cmp     sent_pos, #46    wz
        if_z            jmp     #:g46
                        cmp     sent_pos, #52    wz
        if_z            jmp     #:g52
                        cmp     sent_pos, #53    wz
        if_z            jmp     #:g53
                        cmp     sent_pos, #54    wz
        if_z            jmp     #:g54
                        cmp     sent_pos, #56    wz
        if_z            jmp     #:g56
                        jmp     #receive

:g43                    shl     rxdata, #16             'Fix Type
                        add     rxdata, sharedpad
                        wrlong  rxdata, t7
                        jmp     #receive

:g45                    shl     rxdata, #8              'Satellites
                        mov     scratchpad, rxdata
                        jmp     #receive

:g46                    add     scratchpad, rxdata      'Satellites
                        wrlong  scratchpad, t15
                        jmp     #receive

:g52                    shl     rxdata, #24             'Altitude
                        mov     scratchpad, rxdata
                        jmp     #receive

:g53                    shl     rxdata, #16             'Altitude
                        add     scratchpad, rxdata
                        jmp     #receive

:g54                    shl     rxdata, #8              'Altitude
                        add     scratchpad, rxdata
                        jmp     #receive

:g56                    add     scratchpad, rxdata      'Altitude
                        wrlong  scratchpad, t16
                        jmp     #receive


'---------------------------------------------------------------------------------------
' Variables                                                                            -
'---------------------------------------------------------------------------------------
t1                      res     1
t2                      res     1

t3                      res     1 'Pointer for Course
t4                      res     1 'Pointer for Speed

t5                      res     1 'Pointer for Timestamp[0]
t6                      res     1 'Pointer for Timestamp[1]
t7                      res     1 'Pointer for Flags
t8                      res     1 'Pointer for Latitude[0]
t9                      res     1 'Pointer for Latitude[1]

t10                     res     1 'Pointer for Longitude[0]
t11                     res     1 'Pointer for Longitude[1]
t12                     res     1 'Pointer for Longitude[2]

t13                     res     1 'Pointer for Date[0]
t14                     res     1 'Pointer for Date[1]

t15                     res     1 'Pointer for Satellites

t16                     res     1 'Pointer for Altitude

t17                     res     1 'Pointer for Byte

rxtxmode                res     1
bitticks                res     1

rxmask                  res     1
rxdata                  res     1
rxbits                  res     1
rxcnt                   res     1
rxcode                  res     1

scratchpad              res     1
sharedpad               res     1

sent_pos                long    0 'Current Position In GPS sentence
msgID                   long    0 'Determining = 0, VTG = 1. GGA = 2, RMC = 3, GSA = 4


fit

{{

┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                     │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}