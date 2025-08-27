# mightymic
High dynamic range passive mic with JACK, LV2, and Faust

DESCRIPTION
-----------

> [!Note]
> Decibels used here, are _re: voltage amplitude_.

Microphones are _noisy_. 

That's not a big secret. Very low output amplitude of most microphone transducers ("capsules") available, means high white noise level added to output signal by the following circuit, as well as high EMI noise on connecting cable.

Microphone noise gets way more frustrating if one tries to use some analog or digital **AGC** and/or digital **compressors** to somewhat rectify level variations: they both are considerably increase noise at silent parts of vocal (when noise already most noticeable). While for pure electronic music there is infinite SNR, so no any noise to increase by compressors, but, mic signals are opposite for that, sadly.

Large amount of ways to fight with both types of mentioned noise sources were invented, and they all can be divided to **passive** and **active** approaches (and with rocket priced setups, both are **combined**; we will omit this case here). Let us also omit here noise gate approaches like DNR from compact cassette epoch, as they and their limitations are well known already.

Active are "simple" (and cheap today), and they are "just" an LNA, placed near capsule, then outputs amplified signal in single-phase or differential form and with low or controlled output impedance. Indeed, there is a power supply required for that, but, most high quality microphone input standards are does not offer power output line. There is another drawback: active circuit adds noise itself, so, there is a balance between added and rejected noise. Also, we do not talk here about added non-linearity distortions, dynamic range limitation, power line collected noise, as these can be eliminated more or less effectively today.

Let's take a look at passive one. Despite of its name, it is a way more expensive, due to it requires high quality wideband transformer. The key parameter of transformer is windings _inductance_. That means either very high magnetic permeability yet wide frequency band core (often impossible to obtain today); or, regular ferrite, but, to keep inductance, it will be very large (at least, way larger than you can find in some microphones). Largest possible size also unavoidable to keep both _resistive_ and _magnetic_ power losses (we have _too_ little power to just lost it!).

>> Isn't "Larger size = lower losses" rule wrong and should be opposite?
> <!-- Indent seems to be never work, should use workaround. -->
> No. Every electric, electronic, and radio frequency appliances, are suffered from this. Larger is better and more effective always. Don't worry if tiny power from membrane is not enough to drive palm sized transformer: it will.
>
> Btw, however, there is **not possible** to make cavity resonators (= filters) for GHz and THz larger than wavelength allows, sadly (oh, sorry for off-topic).

Well, hopefully, there are two good news:
1. Typical microphone (let's take regular SM58: it will be fake most probably, anyway we can't obtain correct one) have some space inside of its enclosure;
2. Several transformers can be joined together with no losses, but only gains, to mimic larger one. And special winding is not required for that. So, we can use two easily available 600:600 Ohm with (1+1):(1+1) windings, of largest possible size, which fits the SM58 body.

Let's connect it as pictured:

<img width="183" height="264" alt="mic" src="https://github.com/user-attachments/assets/ff320d21-51c4-4be3-92f5-d827e4225def" />

How it looks using 26x20 mm sized core, 18 mm bobbin width 600:600 Ohm transformers:

> [!Tip]
> Pins should be grinded out almost completely to fit the crank, but note that windings are extremely thin, this is most hard thing of our research.

![beta58a](https://github.com/user-attachments/assets/53336034-e74a-4e30-88b9-28c3bc8242e2)

As one can see, there is no more than 4x amplitude gain (when we use `A` & `E` pins). If one need more, then way more expensive custom transformers are need, and this setup will be even more sensitive to output cable capacitance (yes, this is some disadvantage of passive approach, and 150- or even 300-Ohms cables are recommended here, instead of regular 50/75-Ohms ones).

Now we can connect it to some ADC. 

ADCs are _noisy_...

There is known approach how to reduce ADC noise at the expence of get only half possible sound channels [^1].
We will use same trick, but been even more smart: Mixing stereo to mono, we will not **add**, but **subtract** channels, which, giving us exactly same internal ADC noise power reduction, but, also creates perfect _differential_ input.

> [!Tip]
> Please read separately if you in doubt why and how differential signalling used and works.

> [!Note]
> Musicians often calls it _balanced_ (or _symmetrical_) wiring, it is same as differential one.

At other side, one may note that our schematic use exactly differential output. So it's time to connect it. We will use regular blue stereo line input, available on PC motherboards: while it is known they are perfect sound cadrs _except_ ENOB, but it, looks like, enough for our microphone setup.

> [!Note]
> Some motherboards are not exposes true stereo blue line input connector, but it often can be obtained via pink noisy mono mic input, using `hdajackretask` magic, please read separate research for it (TBD, work in progress).
>
> <img width="239" height="96" alt="retask" src="https://github.com/user-attachments/assets/b3084c5c-ccaf-49a3-8991-94cc57b060b9" />

Next step is tune up our line input to be less noisy yet non-scaling (24-bit ADC output is not altered by codec level scalers). Using `alsamixer`, we carefully tune both `Line Boost` and `Capture` sliders of Capture tab (`F4`) of alsamixer, when check using data flow statistics with [jasmine-sa](https://github.com/twonoise/jasmine-sa) (`F10` then `F1`) to get 24 bit data flow. Mine is `Line Boost`=100 and `Capture`=33. Line input itself can be unconnected when tune up bit depth using `Capture` control; but for set up best _level_ and _SNR_ using `Line Boost` control, it is worth to connect some clean sound to it and estimate SNR using our spectrum analyzer or other measurement.

Now it's time to add differential input plugin to our audio plugin host like [Carla](https://github.com/twonoise/carla-patches), and one may enjoy lowest possible _THD+N_ with such a cheap components.

> Low THD+N is important for reverbs, as they have some degrade of SNR. (Example: Simple echo have exactly 3 dB SNR degrade). So it's time to enjoy plenty of air with reverbs.

<img width="369" height="119" alt="carla-diff-iama" src="https://github.com/user-attachments/assets/857aab40-cf5e-4671-a204-58b071c68ae0" />

     
<br>
Well, that works fine!

But if mic is fake (output amplitude of capsule is low, or, capsule DC resistance is _too_ hidh for that output), singer can note earlier on later that there is **low dynamic range** of our setup (or, which is same **(*)**, still low SNR). Are we take all the best our setup offers, or time to think more?
> **(*)** If we're not reached membrane resonance yet.

Best solution here is, exactly with loudspeakers world, is just to add extra microphone. But it is weird for singer to hangle this setup in hand, so it is "best" electrically only, and quite weird in practice. Another ideas?

When ADCs quantity is enough (in our case, if we have one more _stereo_ ADC), i am use simple approach to extend dynamic a bit. Just feed a part (often a half of voltage) of input to separate ADC, and use this channel when main one is overloaded. This gives 3 dB extra overload margin. But also adds some amount of noise: 3 dB during the periods of overload of main channel, and 0 dB else. In terms of music, added noise are well masked with strong signal peaks at these moments. For sum of two sine waves, there will be ~0.6 dB _total_ (long-term) noise added, so we won ~2.4 dB of measurable ("real") SNR or dynamic, or in simple words, have extra 3 dB for voice peaks while keep near same (for non-peaked voice part, is _exactly_ same) noise.

The problem is resistive tap is rarely useful due to resistors itself adds noise. Recall these `B` and `D` transformer taps? Yes, you're got the idea.

> Wut? 4-wire microphone? :-[     ]

It is 5-wire.

We will use 5(7)-pin DIN connector, some extra wiring, and one extra stereo ADC, for almost zero extra hardware price.

> [!Note]
> Read here (TBD) to know if your motherboard (or pci-e sound card) have it. In short, **ALC887** onboard codec, and **ASUS Xonar** card (**ALC1220** codec) are have it, and are tested. While **ALC897** or **ALC283** are only one ADC, sadly.

Now we will need some gate to switch main and peak outputs. I've make it using `Faust` and `faust2lv2` compiler. Comparator here is sharp and momentary (per-sample), but feel free to implement one with some transition band, if you find this approach useful but need to lower gating THD even further; while current is quite low.

> [!Important]
> Tune `Ratio` parameter correctly.

It is run time knob, no need to change code. We have ratio estimate output meter for that, just give some non-overloading sound to mic. Then set this measured value (often near 0.5) with `Ratio` knob.

<img width="328" height="216" alt="mic-Carla" src="https://github.com/user-attachments/assets/9d0c2c80-88b2-4361-ac1f-1aeabd6a384d" />


We offer also test signal source (using `Faust`, again) as sum of 420 and 440 Hz sine waves, with two fully differential outputs, main one and "taped" (reduced or peak) one; and peak output can be switched off by runtime button. Noise of equal levels are added to outputs, to emulate input noise of the following circuit (ADCs), which makes possible the measurements below.

> [!Important]
> `alsamixer` should be used to set same settings for both ADCs.

Btw, one may note that _float value storage_  is implemented in same way: It have momentary SNR of 25 bits (24 + sign) (for 32-bit floats), while way more long-time dynamic range. It is just full of these transition points each 3 dB.

Here are test results with test signal source. One may recall that 3rd order IMD's extra frequency components (easily seen as extra blue peaks) are _extremely_ sensitive to any overload as non-linearity. So one may exactly know if no IMD are introduced, when no extra peaks.

<img width="732" height="373" alt="mightymic-test-snr" src="https://github.com/user-attachments/assets/a8f257d7-e90b-43ed-abab-e8ddec5e0f3c" />

<details> 
<summary>[Command]</summary>
  
    jasmine-sa MightyMic:Out0 MightyMic:Thru MightyMic:ThruPeak -h 330,530 -d -60,0,6
      
</details>

> [!Note]
> White ray traces on picture, are overlayed red and yellow.

One can see that we have extra SNR (lower noise floor) around, or more than, 2 dB at output of our plugin when it work at full its power (loud constant yelling), compared to using only one mic output with its max non-overloaded level. SNR will npt degraded but only better (up to 3 dB) when yelling reduces. These 2 dB are long-time value, and distributed like 0 dB at loudest yet non-overloaded peaks (where masked well, makes it all better) and 3 db between peaks.

Btw, why these 3 dB, if no peaks, just normal underloaded input? This is because we attenuate main channel by 3 dB (or more precisely, by ratio amount, like windings tap ratio) _always_, so noise are reduced by 3 dB along with the signal.

Such approach can be expanded by yet another extra stage for peaks, but we need 3rd stereo ADC and extra wiring (while DIN-7 connector and our transformers already allows it).

Post processing
---------------

We have added some extra filters recently, together with bypass switch for each. As well as 2- or 4-wire mic selector was added, so now our plugin will work well with both regular and 4-wire microphones. It's worth to check `.dsp` source code for filters descriptions. Full instruction manual is WIP, due to final filters set is not settled yet.

Please let me know how you like new mains hum remover, especially if you have noisy (distorted) mains lines around. Note that we have run time fine-tuned mains frequency to reject. Base frequency value is changed at `.dsp` file.

<img width="1500" height="225" alt="mightymic" src="https://github.com/user-attachments/assets/4368b703-12be-45d8-8983-c80a984ef4a3" />

Note that **Notch** control is three-position, and have _scalepoints_ which describe current one. With **Carla**, value can be seen as tooltip during pressing `Spacebar` on mouse hover, or using mouse button. Or, use _Set value..._ (`E` on hover).


Q & A
-----
**Why not just use [^1] at its full power with 4 (two stereo) ADCs?**

It have 3 dB worse EMI noise due to lower signal levels, and like 0.9 to 1.5 dB worse SNR compared to our 4-wire mic plugin, but else it will work.


**Can this plugin be made even more strong, with _same_ hardware?**

We let our readers to answer it.
<details> 
<summary>[Spoiler]</summary>
I think there is more than one way possible with <em>same</em> hardware.
  
* When no 1st (main) stage overload, take not just it, but sum of both (main + peak). Shuold reduce noise ~1.5 times (~2 db) further.
* Use some trainable AI to "guess" lost peaks, when all stages are overloaded; but rarely possible with `Faust`, i think.
</details>

**I need even better SNR, maybe _another_ passive hardware possible?**

You will need to decrease windings resistance, as it is source of thermal noise. To keep inductance, this is possible either with very rare and fragile permalloy or similar core, of at least same size; or, larger transformer(s) need, will do not fit mic body any more. Pure silver wire winding also helps, but not so much.

Here is triple effect on SNR:
* Less thermal noise;
* Less power loss due to winding resistance;
* Less power loss due to core losses.

**What if windings (and/or taps) are not perfectly balanced?**

Our setup is highly immune to that. Some differential non-equivalency are easily rejected by definition of differential signals. Non-symmetric taps measured & agjusted using `Ratio` knob & scale.

**Disadvantages?**

Both stereo ADCs should form a perfect tandem, in terms of timings (relative skew and wander of it), as well as already mentioned amplitude and preamp gain match. (However, it is true for _every_ music work station). It is known that for `JACK` setup and `ALCxxx` codecs, and `alsamixer`, this is true; but your setup can differ, like "[multi-channel soundcard out of el-cheapo consumer cards](https://www.alsa-project.org/main/index.php/Asoundrc#Virtual_multi_channel_devices)", and it is not easy to create test set for it to confirm its ideal behaviour. Hopefully, for voice, some skew is acceptable (think about compact cassette tape head misaligned a bit).

Amplitudes mismatch (imperfect `Ratio` value) can create some distortions at the points where gate flip flops. This is mostly fixed with included LPF. Probably, there is automatic calculation of `Ratio` possible, but not easy. It should be like step error detector, integrator, and feedback. It can rectify possible skew also. Ask me if you really need it.

**Are these quite few dB SNR gain really counts?**

If you _found_ this plugin, you _know_ how much every single dB costs, _especially_ at the input of DAW, don't you?

Glossary
--------
* LNA: Low noise amplifier.
* SNR: Signal to Noise ratio.
* LPF: Low pass filter.
* EMI: Electromagnetic interference, cables pickup noise due to it.
* ADC: Andlog to Digital converter, like _input_ of PC or sound card.
* ENOB: Effective number of bits, "real" (heavy-loading) ADC/DAC SNR measure, unlike of just silence noise floor.
* AGC: Auto gain control.
* Mixing: Audio people uses it as (linear) _adding_ but not multiplying.
* DNR: Dynamic Noise Reduction (Analog noise gate).
* THD: Total harmonic distortion, most often due to non-linearity. Sum of all IMDx.
* IMD: Intermodulation distortion. Most important is IMD3 part, because it falls to in-band.
* DAW: Digital audio workstation, in our case it is realtime DSP chain.
* TBD: To be displayed.
* WIP: Work in progress.

LICENSE
-------

This research text description, together with its inlined pictures, are licensed under Creative Commons Attribution 4.0. You are welcome to contribute to the description in order to improve it so long as your contributions are made available under this same license.

Included software is licensed as per LICENSE file.


[^1]: https://www.eeweb.com/enhance-adc-dynamic-range/
