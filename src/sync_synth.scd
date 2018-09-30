// Name of the synth
var thisSynth = \syncSynth;

// Synthesis definition for SYNCHRONOUS granular synthesis
// gain - overall volume of the synth
// grainFreq - frequency of the impulses that trigger a grain to be fired
// envFreq - frequency of the grain envelopes (inverse of grain duration)
// wavRatio - the playback rate of the enveloped sound
// q - the "quaility" of the grain. Alters the ratio between the envelope and grain frequency
// panAngle - the angle at which the sound is panned
// index - where in the sound a grain will be fired from (0.0 to 1.0)
// bufferL / bufferR - the left and right buffers containing the input sound
// mute - parameter used to mute the synth. This is lagged so that it is gradually muted.
// gate - setting this to 0 will release the synth after it slowly fades out.
SynthDef.new(thisSynth, { arg gain = 0.0, grainFreq = 200.0, envFreq = 100.0,
	wavRatio = 1, q = 1, panAngle = 0.0, index = 0, bufferL = 0, bufferR = 0, mute = 0, gate = 1;

	// variables
	var bus = 0;      // var to specify output bus: first output
	var numChannels = 1; // mono buffer
	var sig, out;     // vars assigned to audio signals
	var amp;          // a few vars for synthesis
	var trigger;
	var grainDur;
	var envelope;

	// Index jittering
	index = index + WhiteNoise.ar(0.001);

	envFreq = grainFreq / q / 2;

	// calcs
	amp = gain.dbamp * Lag2.kr(1-mute, 2);
	grainDur = envFreq.reciprocal;  // calculate grainDur

	// granular (grain frequency) trigger
	trigger = Impulse.ar(grainFreq);

	// granular synthesis & envelope
	sig = GrainBuf.ar(numChannels: numChannels,
		trigger: trigger,
		dur: grainDur,
		sndbuf: [bufferL, bufferR],
		rate: wavRatio,
		pos: index);
	sig = amp * sig;
	sig = HPF.ar(sig,25);

	// panning
	out = ~sinCosPanLaw.value(panAngle) * sig;

	// Create envelope for switching synths
	envelope = EnvGen.ar(Env([0, 1, 0], [1, 1], 'lin', 1), gate, doneAction: 2);

	// out!!
	Out.ar(bus, out * envelope)
}).add;


// handling OSC messages
OSCdef(thisSynth ++ \Osc,{|msg, time, addr, recvPort|
	var grainFreqSpec = ControlSpec(5, 100, 'exp');
	var qSpec = ControlSpec(1, 0.5, 'exp');
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


	// for the left and right hand...
	~synth.do({ arg synth, i;
		var offset = i * 10;

		// If this synth definition is what the currently playing synth is using...
		if (synth.defName == thisSynth, {
			// Mute the synth if it's out of the interaction box or the hand is lost
			if ((msg[offset + 1] == 0) || ((msg[offset + 2] - 0.5).abs > 0.5), {
				synth.set(\mute, 1);
			}, { // otherwise update the parameters...

				// ensure the synth is not muted
				synth.set(\mute, 0);

				// gain is -inf when your palm's z-position is 0 (close to you) and
				// 0.0 when your palm's z-position is 1 (far away from you)
				synth.set(\gain, (ampSpec.map(msg[offset + 4]).ampdb));

				// q is 1 when your palm is open and 0.5 when it is closed
				synth.set(\q, qSpec.map(msg[offset + 9]));

				// The index is 0 when your palm is to the left of the controller and 1
				// when it is to the right of the controller
				synth.set(\index, msg[offset + 2]);

				// grainFreq is 5 when your palm's y-position is 0 (low and close to the Leap)
				// and 100 when your palm's y-position is 1 (high and far from the Leap)
				synth.set(\grainFreq, grainFreqSpec.map(msg[offset + 3]));

				// wavRatio is 0.25 when your palm is rolled counter-clockwise to the left
				// and 1 when rotated clockwise
				synth.set(\wavRatio, wavRatioSpec.map(abs(msg[offset + 5]) / pi));

				// panAngle is set to -45 when your hand is directed to the left
				// and 45 when your hand is directed to the right
				synth.set(\panAngle, 180 * msg[offset + 7] / pi);
			});
		})
	});

}, '/LeapMotion', recvPort: 5347);
s.sync;