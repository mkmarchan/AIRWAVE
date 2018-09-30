(
s.waitForBoot({
	// Synthesis Components
	var bufferL, bufferR;

	// Define audio file
	~soundFilePath = "".resolveRelative ++ "../res/day.wav";

	// Load helper functions
	"*_func.scd".loadRelative;
	// Ensure helper functions are loaded before creating synthdefs
	s.sync;

	// Currently playing synth. Index 0 should be for the left hand, index 1
	// should be for the right hand
	~synth = [Synth.basicNew(\placeholder), Synth.basicNew(\placeholder2)];

	// Load synth definitions
	"*_synth.scd".loadRelative;

	// Load audio file into two buffers. Assumes the file is stereo
	bufferL = Buffer.readChannel(s, ~soundFilePath, channels: [0]);
	bufferR = Buffer.readChannel(s, ~soundFilePath, channels: [0]);
	// Ensure buffers / synthdefs are loaded before playing synths
	s.sync;

	// Name of all synths that are part of AIRWAVE
	~synthNames = [\syncSynth, \asyncSynth];
	// The default synth that will be played is at index 0 in ~synthNames
	~selectedSynth = 0;

	// Play synth
	~synth = [Synth(\syncSynth, ["bufferL", bufferL, "bufferR", bufferR]),
		Synth(\syncSynth, ["bufferL", bufferL, "bufferR", bufferR])];


	// Ensure synth is playing before loading visualizer
	s.sync;


	// Load GUI
	"visualizer.scd".loadRelative;

	// Define OSCFunc to manage synth switching
	OSCdef(\switchOsc,{|msg, time, addr, recvPort|
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
		// 10 - switch synth? (-1, 0, 1, 2), 2 means confirm switch
		// 11 - 19, same but for the right hand

		// If we are confirming that we want to switch synths and we have selected
		// a synth that is not currently playing:
		if ((msg[10] == 2) && (~synthNames[~selectedSynth] != ~synth[0].defName), {
			// Set the synth's gate parameter to trigger its release, making it fade out
			~synth[0].set(\gate, 0);
			~synth[1].set(\gate, 0);

			// Play the newly confirmed synth
			~synth = [Synth(~synthNames[~selectedSynth], ["bufferL", bufferL, "bufferR", bufferR]),
				Synth(~synthNames[~selectedSynth], ["bufferL", bufferL, "bufferR", bufferR])];

		}, { // otherwise...
			// increment the selected synth index if a left or right switch is detected.
			~selectedSynth = (~selectedSynth + ((msg[10] % 2) * msg[10].sign)) % ~synthNames.size;
		});

	}, '/LeapMotion', recvPort: 5347);

	// Command-Period Function
	CmdPeriod.doOnce({
		~bufferL.free;
		~bufferR.free;
	});
})

)