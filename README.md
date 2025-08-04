# mightymic
High dynamic range passive mic with Faust

> [!Note]
> Decibels used here, are _re: amplitude_.

DESCRIPTION
-----------

Microphones are _noisy_. That's not a big secret. Very low output amplitude of most microphone transducers ("capsules") available, means high white noise level added to output signal by the following circuit, as well as high EMI noise on connecting cable.

Microphone noise gets way more frustrating if one tries to use some (digital) compressors to somewhat rectify level variations in sound processing plugins path: compressors are considerably increase noise at silent parts of vocal (when noise already most noticeable). While for pure electronic music there is infinite SNR, so no any noise to increase by compressors, but, mic signals are opposite for that, sadly.

> [!Note]
> Compressors can't fix already overloaded input.

Large amount of ways to fight with both types of mentioned noise sources were invented, and they all can be divided to **passive** and **active** approaches (and with rocket priced setups, both are **combined**; we will omit this case here).

Active are "simple" (and cheap today), and they are "just" an LNA, placed near capsule, then outputs amplified signal in single-phase or differential form and with low or controlled output impedance. Indeed, there is a power supply required for that, but, most high quality microphone input standards are does not offer power output line. There is another drawback: active circuit adds noise itself, so, there is a balance between added and rejected noise. Also, we do not talk here about added non-linearity distortions, dynamic range limitation, power line collected noise, as these can be eliminated more or less effectively today.

Let's take a look at passive one. Despite of its name, it is a way more expensive, due to it requires high quality wideband transformer. The key parameter of transformer is windings _inductance_. That means either very high magnetic permeability yet wide frequency band core (often impossible to obtain today); or, regular ferrite, but, to keep inductance, it will be very large (at least, way larger than you can find in some microphones). Largest possible size also unavoidable to keep both _resistive_ and _magnetic_ power losses (we have _too_ little power to just lost it!).

> Isn't "Larger size = lower losses" rule wrong and should be opposite?

No. Every electric, electronic, and radio frequency appliances, are suffered from this. Larger is better and more effective always; however, there is **not possible** to make cavity resonators (= filters) for GHz and THz larger than wavelength allows, sadly.

Well, hopefully, there are two good news:
1. Typical microphone (let's take regular SM58: it will be fake most probably, anyway we can't obtain correct one) have some space inside of its enclosure;
2. Transformers can be paralleled with no losses, but only gains. And special winding is not required for that. So, we can use two easily available 600:600 Ohm with (1+1):(1+1) windings, of largest possible size, which fits the SM58 body.

> [!Tip]
> Pins should be shortened almost completely to fit the crank, but note that windings are extremely thin, this is most hard thing of our research.

Let's connect it as pictured:

<img width="366" height="527" alt="mic" src="https://github.com/user-attachments/assets/ff320d21-51c4-4be3-92f5-d827e4225def" />

As one can see, there is no more than 4x amplitude gain (when we use `A` & `E` pins). If one need more, then way more expensive custom transformers are need, and this setup will be even more sensitive to connecting cable capacitance (yes, this is some disadvantage of passive approach, and 150- or even 300-Ohms cables are recommended here, instead of regular 50/75-Ohms ones).

Now we can connect it to some low noise ADC. There is known approach how to reduce ADC noise at the expence of get only half possible souns channels [^1].
We will use same trick, but been even more smart: Mixing stereo to mono, we will not **add**, but **subtract** channels, which, giving us exactly same internal ADC noise power reduction, but, also creates perfect _differential_ input (please read separately if you in doubt why and how differential signalling used and works).

At other side, one may note that our schematic use exactly differential output. So it's time to connect it. We will use regular sound card line input, available on PC motherboards: while it is known they are perfect _except_ ENOB, but it, looks like, enough for our microphone setup.

Note that some motherboards are not exposes true stereo blue line input connector, but it often can be obtained via pink noisy mono mic input, using 'hdajackretask' magic, please read separate research for it (TBD, work in progress).

Next step is tune up our line input to be less noisy yet non-scaling (24-bit ADC output is not altered by codec level scalers). Using `alsamixer`, we carefully tune both `Line Boost` and `Capture` sliders of Capture tab (`F4`) of alsamixer, when check using data flow statistics with [jasmine-sa](https://github.com/twonoise/jasmine-sa) (`F10` then `F1`) to get 24 bit data flow. Mine is `Line Boost`=100 and `Capture`=33. Line input itself can be unconnected when tune up bit depth using `Capture` control; but for set up best _level_ and _SNR_ using `Line Boost` control, it is worth to connect some clean sound to it and estimate SNR using our spectrum analyzer or other measurement.

Now it's time to add differential input plugin to our audio plugin host like `Carla`, and one may enjoy lowest possible noise with such a cheap components.

But if mic is fake (output amplitude of capsule is low, or, capsule DC resistance is _too_ hidh for that output), singer can note earlier on later that there is **low dynamic range** of our setup (or, which is same, still low SNR). Are we take all the best our setup offers, or time to think more?

Best solution here is, exactly with loudspeakers world, is just to add extra microphone. But it is weird for singer to hangle this setup in hand, so it is "best" electrically only, and quite weird in practice. Another ideas?

When ADCs quantity is enough (in our case, if we have one more _stereo_ ADC), i am use simple approach to extend dynamic a bit. Just feed a part (often a half of voltage) of input to separate ADC, and use this channel when main one is overloaded. This gives 3 dB extra signal strength, while also adds some amount of noise during the periods of overload of main channel. In terms of music, added noise are well masked of strong signal peaks at these moments. For sum of two sine waves, there will be ~0.6 dB _total_ (long-term) noise added, so we won ~2.4 dB SNR or dynamic, or in simple words, have extra 3 dB for voice peaks while keep near same (for non-peaked voice part, is _exactly_ same) noise.

The problem is resistive tap is rarely useful due to resistors itself adds noise. Recall these `B` and `D` transformer taps? Yes, you're got the idea.

> Wut? 4-wire microphone? :-[   ]

It is 5-wire.

We will use 5(7)-pin DIN connector, some extra wiring, and one extra stereo ADC, for almost zero extra hardware price.

> [!Note]
> Read here (TBD) to know if your motherboard (or pci-e sound card) have it. In short, **ALC887** onboard codec, and **ASUS Xonar** card (**ALC1220** codec) are have it, and are tested. While **ALC897** or **ALC283** are only one ADC, sadly.

Now we will need some gate to switch main and peak outputs. I've make it using `Faust` and `faust2lv2` compiler. Comparator here is sharp and momentary (per-sample), but feel free to implement one with some transition band, if you find this approach useful but need to lower gating THD even further; while current is quite low.
It is important to tune `Ratio` parameter correctly (it is run time knob, no need to change code). We have ratio estimate output meter for that, just give some non-overloading sound to mic. Then set this measured value (often near 0.5) with `Ratio` knob.

We offer also test signal source (using `Faust`, again) as sum of 420 and 440 Hz sine waves, with two fully differential outputs, main one and "taped" (reduced or peak) one; and peak output can be switched off by runtime button. Noise of equal levels are added to outputs, to emulate input noise of the following circuit (ADCs), which makes possible the measurements below.
Note that `alsamixer` should be used to set same settings for both ADCs.

Btw, one may note that _float value storage_  is implemented in same way: It have momentary SNR of 25 bits (24 + sign) (for 32-bit floats), while way more long-time dynamic range. It is just full of these transition points each 3 dB.

Here are test results with test signal source. One may recall that 3rd order IMD's extra frequency components (easily seen as extra blue peaks) are _extremely_ sensitive to any overload as non-linearity. So one may exactly know if no IMD are introduced, when no extra peaks.

<img width="732" height="373" alt="mightymic-test-snr" src="https://github.com/user-attachments/assets/a8f257d7-e90b-43ed-abab-e8ddec5e0f3c" />

<details> 
<summary>[Command]</summary>
  
    jasmine-sa MightyMic:Out0 MightyMic:Thru MightyMic:ThruPeak -h 330,530 -d -60,0,6
      
</details>

> [!Note]
> White ray traces on picture, are overlayed red and yellow.

One can see that we have extra SNR (lower noise floor) around or more than 2 dB at output of our plugin when it work at full its power (loud constant yelling), compared to using only one mic output with its max non-overloaded level. SNR will npt degraded but only better (up to 3 dB) when yelling reduces. These 2 dB are long-time value, and distributed like 0 dB at loudest yet non-overloaded peaks (where masked well, makes it all better) and 3 db between peaks.

Btw, why these 3 dB, if no peaks, just normal underloaded input? This is because we attenuate main channel by 3 dB (or more precisely, by ratio amount, like windings tap ratio) _always_, so noise are reduced by 3 dB along with the signal.

Such approach can be expanded by yet another extra stage for peaks, but we need 3rd stereo ADC and extra wiring (while DIN-7 connector and our transformers already allows it).

Q & A
-----
**Can this plugin be made even more strong, with same hardware?**

We let our readers to answer it.

**What if windings (and/or taps) are not perfectly balanced?**

Our setup is highly immune to that. Some differential non-equivalency are easily rejected by definition of differential signals. Non-symmetric taps measured & agjusted using `Ratio` knob & scale.
 
[^1]: https://www.eeweb.com/enhance-adc-dynamic-range/
