// faust2lv2 mightymictestsource.dsp  &&  sed -i -e 's/out0/Out/g' -e 's/out1/OutInv/g' -e 's/out2/OutPeak/g' -e 's/out3/OutPeakInv/g' mightymictestsource.lv2/mightymictestsource.ttl  &&  cp -R ./mightymictestsource.lv2/ /usr/local/lib/lv2/

declare name "MightyMicTestSource"; // No spaces for better JACK port names.
declare version "2025";
declare author "jpka";
declare license "MIT";
declare description "See readme at github.com/twonoise/mightymic.dsp";

import("stdfaust.lib");

// Must match with Ratio of mightymic plugin.
RATIO = hslider("Ratio", 0.5, 0.1, 0.9, 0.001);

LEVEL = hslider("Level", 1.0, 0.0, 2.0, 0.1);

BTNON = button("ON");
BTNPEAK = button("Peak Ch ON");

// Emulates the subsequent ADCs limitation.
clip(lo,hi) = min(hi) : max(lo);
sym_clip(thr) = clip(-thr,thr);

testsrc = (os.osc(420) + os.osc(440)) * 0.475 / RATIO * LEVEL;
noisesrc = no.noise * 0.01; // -40 dB

process =
  // Straight diff pair
  (  testsrc         +  noisesrc : sym_clip(BTNON) ),
  ( -testsrc         + -noisesrc : sym_clip(BTNON) ),

  // Attenuated diff pair
  (  testsrc * RATIO +  noisesrc : sym_clip(BTNON * BTNPEAK) ),
  ( -testsrc * RATIO + -noisesrc : sym_clip(BTNON * BTNPEAK) )
;
