// faust2lv2 mightymic.dsp  &&  sed -i -e 's/in0/In/g' -e 's/in1/InInv/g' -e 's/in2/InPeak/g' -e 's/in3/InPeakInv/g' -e 's/out0/Out0/g' -e 's/out1/Out1/g' -e 's/out2/Thru/g' -e 's/out3/ThruPeak/g' -e 's/out4/UNUSED0/g' -e 's/out5/UNUSED1/g' -e 's/out6/UNUSED2/g' -e '/lv2:name "Overload/a\\tlv2:portProperty lv2:integer ;' mightymic.lv2/mightymic.ttl  &&  cp -R ./mightymic.lv2/ /usr/local/lib/lv2/

declare name "MightyMic"; // No spaces for better JACK port names.
declare version "2025";
declare author "jpka";
declare license "MIT";
declare description "4-wire mic frontend. See readme at github.com/twonoise/mightymic.dsp";

import("stdfaust.lib");
import("filters.lib");
import("music.lib");


/* Differential inputs section */

diff(x,y) = (x - y) / 2;


/* 4 wire section */

EN4WIRE = checkbox("[0] 4 Wire");

// IMPORTANT!
// MUST exactly match attenuation of secondary attenuated output of mic!
// Often it is turns ratio of attenuated to straight windings output.
// Most often it is 0.5 (attenuated is half of whole winding).
RATIO = hslider("[1] Ratio", 0.5, 0.1, 0.9, 0.001);

// We need not single point but some transition band, if some
// compression is possible near range limit of ADCs; or, we lower
// our point a bit, at the cost of loss ENOB for same small amount.
// Also used for LED outputs.
overload(x) = (abs(x) > 0.95);

overloadLed(x) = ba.peakholder(ba.sec2samp(0.25), overload(x));

mux2(x,y) = select2(overload(x), x * RATIO, y);

micout(x,y) = select2(EN4WIRE, x, mux2(x,y));

/* Metering helper subsection */

// Real ratio meter, works when sounding into 4-wire mic without overloads.
// Use it to set Ratio control.
envelope = abs : max ~ -(0.2/ma.SR);
ratioMeasured(x,y) = select2(envelope(x) > 0.01, 0, envelope(y) / envelope(x));


/* Various post processing with per-section On-Off switches */

// Mains frequency is compile-time value.
MAINSFREQIDEAL = 60; // 60 or 50, or 400 sometimes

// S is samples q'ty for delay, SR is current sample rate (internal func).
// Note that for all 60 & 50 Hz & 44.1 & 48 kS/s multiplies combinations, there is integer division; while for like 16 or 22.5 kS/s, 60 Hz will give some offset.
S = abs(round(SR / MAINSFREQIDEAL + nentry("[5] Mains Freq Detune", 0, -5, 5, 1)));

MAINSFREQ = SR / S : vbargraph("[6] Mains Freq", 0, 1000);

// Notch chains for first three harmonics.
notch3 = _ <: _, (
  notchw(MAINSFREQ * 1.0 * 0.2,  MAINSFREQ * 1.0) :
  notchw(MAINSFREQ * 3.0 * 0.15, MAINSFREQ * 3.0) :
  notchw(MAINSFREQ * 5.0 * 0.1,  MAINSFREQ * 5.0)
) :> select2(checkbox("[3] Notch Three"));

// IIR Comb filter is for all harmonics.
iircombnotch(x) = kernel ~ _ with { kernel(y) = 1.0*x - 1.0*x@(S) - (0.5*y - 0.5*y@(S)); };
notchcomb = _ <: _, iircombnotch :> select2(checkbox("[4] Notch Comb"));

// Spectral tilt to rectify microphone frequency responce a bit
tilt = _ <: _,
  spectral_tilt(3, 20, 10000, nentry("[8] Tilt dB/Oct", 0, -6, 6, 1) : int / 6.0)
:> select2(checkbox("[7] Tilt"));

// Finally, regular microphone LPF.
AUDIO_BW_HZ = hslider("[9] BW Hz", 20000, 500, 20000, 500);
FLT_ORD = 3;

OUTPUTLEVEL = hslider("[C] Output Level", 1.0, 0, 5.0, 0.1);


process =
  (_,_ : diff),   // Straight differential (balanced) inputs
  (_,_ : diff) <: // Attenuated differential (balanced) inputs

  // OR
  // _,_ <: // Straight and Attenuated: single (UNbalanced) inputs

  // 1. Two identical mono outputs
  (
    micout
    : notch3
    : notchcomb
    : tilt
    : lowpass(FLT_ORD, AUDIO_BW_HZ)
    * OUTPUTLEVEL <: _,_ // _, (spectral_tilt_demo(3) : _)
  ) ,
  // 2. Thru line (outputs) unbalanced, Straight and Attenuated.
  (_,_) ,
  // How it compiles, but adds extra unused audio ports.
  // 3. LEDS, with unneeded outputs.
  //    Rename to UNUSED also included in command above as a workaround.
  ( (overloadLed : int : vbargraph("[A] Overload0 [CV:0]", 0, 1)),
    (overloadLed : int : vbargraph("[B] Overload1 [CV:1]", 0, 1)) )
  // (3). How it should be: but lost LED ports.
  // ((overloadLed : int : vbargraph("Overload0 [CV:0]", 0, 1) : !),
  //  (overloadLed : int : vbargraph("Overload1 [CV:1]", 0, 1) : !) )

  // 4. Ratio measured display output.
  , (ratioMeasured : vbargraph("[2] Ratio Meter [CV:2]", 0, 1))
;
