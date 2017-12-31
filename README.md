Nixie and LED Clocks
Scott Baker, http://www.smbaker.com/

This repository holds my propeller-based nixie tube and led
clock projects. There are two different main files here,
ledclock.spin and in12clock.spin.

ledclock.spin is the LED-based clock. In my prototype, I used
1" tall common-cathode displays that I sourced on eBay. Blue
displays will just barely work with no current limiting 
resistors as they have a forward voltage of 3.0V. Red displays
in this size typically come in two varieties: a two led per
segment version with a forward voltage of 3.6V and a one led
per segment version with a forward voltage of 1.8V. The 3.6V
version will not work as the logic on this board is 3.3V. 
The 1.8V version should work with an appropriate dropping
resistor, as yet to be determined.

in12clock.spin is the IN-12 Nixie Tube version. It uses 
IN-12 nixie tubes, sourced from ebay. There is a high voltage
supply on-board to power the tubes. You'll also need K155D
drivers.

Both clocks may either be powered from a dallas DS1302 RTC
or from a GPS module. My preference is to use the GPS, as
this allows the clock to be self-setting. There is an onboard
footprint where a fastrax UP501 module may be directly wired 
and mounted. The UP501 is no longer manufactured, so I've been
looking at alternatives such as the U-Blox PAM-7Q which is 
supposed to be pin-compatible with the UP501. I have not tried
the PAM-7Q yet.

There's also a header that should allow connection of a EM406
GPS module.

In addition to the clock functionality, there is a footprint for
a Dallas 1822 digital thermometer, should one wish to repurpose
this is a thermometer board. I have not tried or coded for the
thermometer yet.
