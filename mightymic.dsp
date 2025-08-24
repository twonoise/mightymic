// faust2lv2 mightymic.dsp  &&  sed -i -e 's/in0/In/g' -e 's/in1/InInv/g' -e 's/in2/InPeak/g' -e 's/in3/InPeakInv/g' -e 's/out0/Out0/g' -e 's/out1/Out1/g' -e 's/out2/Thru/g' -e 's/out3/ThruPeak/g' -e 's/out4/UNUSED0/g' -e 's/out5/UNUSED1/g' -e 's/out6/UNUSED2/g' -e '/lv2:name "Overload/a\\tlv2:portProperty lv2:integer ;' mightymic.lv2/mightymic.ttl  &&  cp -R ./mightymic.lv2/ /usr/local/lib/lv2/

declare name "MightyMic"; // No spaces for better JACK port names.
declare version "2025";
declare author "jpka";
declare license "MIT";
declare description "4-wire mic frontend. See readme at github.com/twonoise/mightymic.dsp";

import("stdfaust.lib");
import("filters.lib");

EN4WIRE = checkbox("4 Wire");

// * IMPORTANT! *
// MUST exactly match attenuation of secondary attenuated output of mic!
// Often it is turns ratio of attenuated to straight windings output.
// Most often it is 0.5 (attenuated is half of whole winding).
RATIO = hslider("Ratio", 0.5, 0.1, 0.9, 0.001);

diff(x,y) = (x - y) / 2;

// We need not single point but some transition band, if some
// compression is possible near range limit of ADCs; or, we lower
// our point a bit, at the cost of loss ENOB for same small amount.
// Also used for LED outputs.
overload(x) = (abs(x) > 0.95);

overloadLed(x) = ba.peakholder(ba.sec2samp(0.25), overload(x));

mux2(x,y) = select2(select2(EN4WIRE, 0, overload(x)), x * RATIO, y);

// Real ratio meter, works when sounding into mic without overloads.
// Use it to set Ratio control.
envelope = abs : max ~ -(0.2/ma.SR);
ratioMeasured(x,y) = select2(envelope(x) > 0.01, 0, envelope(y) / envelope(x));

// We use notch chains, due to FFT or comb filters will add more delay at low freqs.
NOTCH50 = checkbox("Notch 50");
NOTCH60 = checkbox("Notch 60");

// Finally, regular microphone LPF. Anybody sings above 5 kHz?
AUDIO_BW_HZ = hslider("BW Hz", 2000, 500, 5000, 500);
FLT_ORD = 3;

process =
  (_,_ : diff),   // Straight differential (balanced) inputs
  (_,_ : diff) <: // Attenuated differential (balanced) inputs

  // OR
  // _,_ <: // Straight and Attenuated: single (UNbalanced) inputs

  // 1. Two identical mono outputs
  (mux2
    <: _, (notchw(10, 50) : notchw(20, 150) : notchw(35, 250)) :> select2(NOTCH50)
    <: _, (notchw(12, 60) : notchw(25, 180) : notchw(40, 300)) :> select2(NOTCH60)
    : fi.lowpass(FLT_ORD, AUDIO_BW_HZ) <: _,_) ,
  // 2. Thru line (outputs) unbalanced, Straight and Attenuated.
  (_,_) ,
  // How it compiles, but adds extra unused audio ports.
  // 3. LEDS, with unneeded outputs.
  //    Rename to UNUSED also included in command above as a workaround.
  ( (overloadLed : int : vbargraph("Overload0 [CV:0]", 0, 1)),
    (overloadLed : int : vbargraph("Overload1 [CV:1]", 0, 1)) )
  // (3). How it should be: but lost LED ports.
  // ((overloadLed : int : vbargraph("Overload0 [CV:0]", 0, 1) : !),
  //  (overloadLed : int : vbargraph("Overload1 [CV:1]", 0, 1) : !) )

  // 4. Ratio measured display output.
  , (ratioMeasured : vbargraph("Ratio Meter [CV:2]", 0, 1))
;
