// faust2lv2 mightymic.dsp  &&  sed -i -e 's/in0/In/g' -e 's/in1/InInv/g' -e 's/in2/InPeak/g' -e 's/in3/InPeakInv/g' -e 's/out0/Out0/g' -e 's/out1/Out1/g' -e 's/out2/Thru/g' -e 's/out3/ThruPeak/g' -e 's/out4/UNUSED0/g' -e 's/out5/UNUSED1/g' -e 's/out6/UNUSED2/g' -e '/lv2:name "Overload/a\\tlv2:portProperty lv2:integer ;' mightymic.lv2/mightymic.ttl  &&  cp -R ./mightymic.lv2/ /usr/local/lib/lv2/

declare name "MightyMic"; // No spaces for better JACK port names.
declare version "2025";
declare author "jpka";
declare license "MIT";
declare description "4-wire mic frontend. See readme at github.com/twonoise/mightymic.dsp";

import("stdfaust.lib");
import("filters.lib");


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

// S is samples q'ty for delay, ma.SR is current sample rate (internal func).
// Note that for all 60 & 50 Hz & 44.1 & 48 kS/s multiplies combinations, there is integer division; while for like 16 or 22.5 kS/s, 60 Hz will give some offset.
S = abs(round(ma.SR / MAINSFREQIDEAL - nentry("[5] Mains Detune", 0, -5, 5, 1)));

MAINSFREQ = ma.SR / S : vbargraph("[6] Mains Freq", 0, 1000);

// Notch chains for first three harmonics.
// NOTE It works, but adds few metal ghosts.
notch3 = _ <: _, (
  notchw(MAINSFREQ * 1.0 * 0.2,  MAINSFREQ * 1.0) :
  notchw(MAINSFREQ * 3.0 * 0.15, MAINSFREQ * 3.0) :
  notchw(MAINSFREQ * 5.0 * 0.1,  MAINSFREQ * 5.0)
) :> select2(checkbox("[3] Notch Three"));

// IIR Comb filter is for all harmonics.
// Nobody knows how it works! Despite of its tiny look, it is result of long and massive blind trials and errors. Long story short, i am try to make it according to theory [1]. It is essential that we do not need just comb filter which is just (x - x_delayed). Rather, we need it to have Q factor. The difference is narrow notches, note picture at [1]. But problem is what to do with "b" "multiplier" (see H(z)=... at [1]). The transformation (2)->(3) (transfer "function" to Faust-compatible form) as per [2], is not known with "multiplier" in transfer "function". However, happily, we have Q > 1 now. FIXME someone else, please! DSP students welcome.
// [1] https://www.mathworks.com/help/dsp/ref/iircomb.html
// [2] page 3 (315) at https://cdn.intechopen.com/pdfs/17794/InTech-Adaptive_harmonic_iir_notch_filters_for_frequency_estimation_and_tracking.pdf
// [3] Fig. 2.27 from https://www.dsprelated.com/freebooks/pasp/Comb_Filters.html
iircombnotch(x) = kernel ~ _ with { kernel(y) = 1.0*x - 1.0*x@(S) - (0.5*y - 0.5*y@(S)); };
notchcomb = _ <: _, iircombnotch :> select2(checkbox("[4] Notch Comb"));

// LM1894 DNR
envelopeFastLimited = abs : min(1.0) : max ~ -(2.0/ma.SR) ; // Max = 1.0
sensitivity = hslider("[8] LM1894 Sens.", 0.1, 0, 1, 0.01);
bw(x) = 1000 + 19000 * (envelopeFastLimited(x * sensitivity * 10.0));
lm1894(x) = lowpass(FLT_ORD, bw(x));
dnr = _ <: _,
  lm1894
:> select2(checkbox("[7] LM1894"));

// Spectral tilt to rectify microphone frequency responce a bit
tilt = _ <: _,
  spectral_tilt(3, 20, 10000, nentry("[A] Tilt dB/Oct", 0, -6, 6, 1) : int / 6.0)
:> select2(checkbox("[9] Tilt"));

// Robot voice, as per request, but it's strange, no real use i think.
fbcf(del, g, x) = loop ~ _ with { loop(y) = x + y@(del - 1) * g; }; // Thanks to https://github.com/LucaSpanedda/Digital_Reverberation_in_Faust
robot = _ <: _,
  fbcf(nentry("[C] Robot Size", 5000, 1000, 10000, 100) : int, 0.9)
:> select2(checkbox("[B] Robot"));

// Finally, regular microphone LPF.
AUDIO_BW_HZ = hslider("[D] BW Hz", 20000, 500, 20000, 500);
FLT_ORD = 3;

OUTPUTLEVEL = hslider("[G] Output Level", 1.0, 0, 5.0, 0.1);


process =
  (_,_ : diff),   // Straight differential (balanced) inputs
  (_,_ : diff) <: // Attenuated differential (balanced) inputs

  // OR
  // _,_ <: // Straight and Attenuated: single (UNbalanced) inputs

  // 1. Two identical mono outputs
  (
    micout        // This one have two inputs and mono output;
    : notch3      // The following all are mono.
    : notchcomb
    : dnr
    : tilt
    : robot
    : lowpass(FLT_ORD, AUDIO_BW_HZ)
    * OUTPUTLEVEL <: _,_
  ) ,
  // 2. Thru line (outputs) unbalanced, Straight and Attenuated.
  (_,_) ,
  // How it compiles, but adds extra unused audio ports.
  // 3. LEDS, with unneeded outputs.
  //    Rename to UNUSED also included in command above as a workaround.
  ( (overloadLed : int : vbargraph("[E] Overload0 [CV:0]", 0, 1)),
    (overloadLed : int : vbargraph("[F] Overload1 [CV:1]", 0, 1)) )
  // (3). How it should be: but lost LED ports.
  // ((overloadLed : int : vbargraph("Overload0 [CV:0]", 0, 1) : !),
  //  (overloadLed : int : vbargraph("Overload1 [CV:1]", 0, 1) : !) )

  // 4. Ratio measured display output.
  , (ratioMeasured : vbargraph("[2] Ratio Meter [CV:2]", 0, 1))
;
