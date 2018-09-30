// Name of the synth
var thisSynth = \asyncSynth;

// Synthesis definition for ASYNCHRONOUS granular synthesis
// gain - overall volume of the synth
// grainFreq - "density" of the impulses that trigger a grain to be fired
// grainDur - the duration (or "length") of the grains
// wavRatio - the playback rate of the enveloped sound
// panAngle - the angle at which the sound is panned
// index - where in the sound a grain will be fired from (0.0 to 1.0)
// bufferL / bufferR - the left and right buffers containing the input sound
// mute - parameter used to mute the synth. This is lagged so that it is gradually muted.
// gate - setting this to 0 will release the synth after it slowly fades out.

// Synth definition ----------------------------------------
SynthDef.new(thisSynth, { arg gain = 0.0, grainFreq = 200.0, wavRatio = 1, q = 1, panAngle = 0.0, loop = 0, indx = 0, bufferL = 0, bufferR = 0, mute = 0, grainDur = 0.2, gate = 1;

	// variables
	var bus = 0;      // var to specify output bus: first output
	var numChannels = 1; // mono buffer
	var sig, out;     // vars assigned to audio signals
	var amp;          // a few vars for synthesis
	var trigger;
	var envelope;

	indx = indx + WhiteNoise.ar(0.002);

	// calcs
	amp = gain.dbamp * Lag2.kr(1-mute, 2) / ( max(1, log2(grainDur * grainFreq))) * 1.1;  // convert from gain in dB to linear amplitude scale

	// granular (grain frequency) trigger
	trigger = Dust.ar(grainFreq);

	// granular synthesis & envelope
	sig = GrainBuf.ar(numChannels: numChannels, trigger: trigger, dur: grainDur, sndbuf: [bufferL, bufferR], rate: wavRatio, pos: indx);
	sig = amp * sig;
	sig = HPF.ar(sig,25);

	// expand to two channels - panning
	out = ~sinCosPanLaw.value(panAngle) * sig;  // <-- Panning happens here!

	// Create envelope for switching synths
	envelope = EnvGen.ar(Env([0, 1, 0], [1, 1], 'lin', 1), gate, doneAction: 2);

	// out!!
	Out.ar(bus, out)
}).add;


// handling OSC messages
OSCdef(thisSynth ++ \Osc,{|msg, time, addr, recvPort|
	var grainFreqSpec = ControlSpec(10, 1000, 'exp');
	var wavRatioSpec = ControlSpec(0.25, 4, 'exp');
	var ampSpec = ControlSpec(1, 0);
	// 0 - message name
	// 1 - has left hand? (0 or 1)
	// 2 - x position left palm
	// 3 - y position left palm
	// 4 - z position left palm
	// 5 - roll left palm (z-axis rotation)
	// 6 - pitch left palm (x-axis rotation)
	// 7 - yaw left palm (y-axis rotation)
	// 8 - x velocity left palm
	// 9 - grab strength left palm
	// 10 - switch synth? (-1, 0, 1)
	// 11 - 19, same but for the right hand

	~synth.do({ arg synth, i;
		var offset = i * 10;
		var val;
		if (synth.defName == thisSynth, {
			if ((msg[offset + 1] == 0) || ((msg[offset + 2] - 0.5).abs > 0.5), {
				synth.set(\mute, 1);
			}, {
				if ((msg[offset + 1].asBoolean), {                                // IS THIS NECESSARY??
					synth.set(\gain, (ampSpec.map(msg[offset + 4]).ampdb));
				});

				synth.set(\mute, 0);
				val = (-1.0 * pow(msg[offset + 9]/2.2,2)) + 0.2 + ((1.0 / (10.0 * (1.0 + exp(-8.0 * (msg[offset + 9] - 0.5)))))*pow(msg[offset + 9]/2.0,2));
				synth.set(\grainDur, val);  // closed = 1, open = 0
				synth.set(\indx, msg[offset + 2]);
				synth.set(\grainFreq, grainFreqSpec.map(msg[offset + 3]));
				synth.set(\wavRatio, wavRatioSpec.map(abs(msg[offset + 5]) / pi));
				    // *replace previous line with this to reverse the direction of wavRatio changes for the left hand - i.e. for "mirroring"
				    //synth.set(\wavRatio, wavRatioSpec.map((1 - i) + (pow(-1,i+1) * abs(msg[offset + 5]) / pi)));
				synth.set(\panAngle, 180 * msg[offset + 7] / pi);
			});
		})
	});

}, '/LeapMotion', recvPort: 5347);
s.sync;