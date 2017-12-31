CON
  NUM_SAMPLES = 10

VAR
  long PhotoPin
  long myStack[12]
  long samples[NUM_SAMPLES]
  long samplePtr

PUB start(aphotopin)
  PhotoPin := aphotopin
  cognew(MeasurePhotoTransistor, @mystack)

PUB get_average : avg | i
  i:=0
  repeat NUM_SAMPLES
      avg := avg + samples[i]
      i := i + 1
  return avg / NUM_SAMPLES

PRI MeasurePhotoTransistor | time
  ctra[30..26] := %01000
  ctra[5..0] := PhotoPin
  frqa := 1
  samplePtr := 0

  repeat
      time := (phsa - 624) #> 0
      samples[samplePtr] := time
      if samplePtr => NUM_SAMPLES
          samplePtr := 0

      dira[PhotoPin] := outa[PhotoPin] := 1
      waitcnt(clkfreq/100_000 + cnt)
      phsa~
      dira[PhotoPin]~

      ' do some work
      waitcnt(clkfreq/1000 * 10 + cnt)
 