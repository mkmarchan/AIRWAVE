// GUI Parts
var window, soundfile, selectedSynthLabel, synthLabel, handLabels, waveforms, gripSliders, ySliders, zSliders, rollKnobs, yawKnobs;

// Create GUI
Server.default.makeGui;

// Build GUI
window = Window.new("AIRWAVE", Rect(0, 0, 1280, 370));
selectedSynthLabel = StaticText.new(window, Rect(540, 10, 200, 20));
selectedSynthLabel.string = "";
selectedSynthLabel.align = \center;
selectedSynthLabel.font = Font("Helvetica", 10);
synthLabel = StaticText.new(window, Rect(540, 30, 200, 20));
synthLabel.string = ~synth[0].defName;
synthLabel.align = \center;
synthLabel.font = Font("Helvetica", 20, true);
handLabels = [StaticText.new(window, Rect(285, 30, 80, 20)),
	StaticText.new(window, Rect(915, 30, 80, 20))];
["LEFT", "RIGHT"].do({arg label, i;
	handLabels[i].string = label ++ " HAND";
	handLabels[i].align = \center;
	handLabels[i].font = Font("Helvetica", 12, true);
});
waveforms = [SoundFileView.new(window, Rect(20, 70, 610, 60)),
	SoundFileView.new(window, Rect(650, 70, 610, 60))];
gripSliders = [EZSlider.new(window, Rect(20, 150, 60, 200), "Grip", layout: \vert),
	EZSlider.new(window, Rect(650, 150, 60, 200), "Grip", layout: \vert)];
ySliders = [EZSlider.new(window, Rect(100, 150, 60, 200), "Palm Y", layout: \vert),
	EZSlider.new(window, Rect(730, 150, 60, 200), "Palm Y", layout: \vert)];
zSliders = [EZSlider.new(window, Rect(180, 150, 60, 200), "Palm Z", layout: \vert),
	EZSlider.new(window, Rect(810, 150, 60, 200), "Palm Z", layout: \vert)];
rollKnobs = [EZKnob.new(window, Rect(260, 150, 80, 100), "Palm Roll"),
	EZKnob.new(window, Rect(890, 150, 80, 100), "Palm Roll")];
yawKnobs = [EZKnob.new(window, Rect(360, 150, 80, 100), "Palm Yaw"),
	EZKnob.new(window, Rect(990, 150, 80, 100), "Palm Yaw")];

soundfile = SoundFile.new;
soundfile.openRead(~soundFilePath);

waveforms.do({arg waveform;
	waveform.soundfile = soundfile;
	waveform.read(0, soundfile.numFrames);
	waveform.elasticMode = true;
	waveform.gridColor = Color.black;
	waveform.peakColor = Color.grey;
	waveform.rmsColor = Color.white;
	waveform.timeCursorOn = true;
	waveform.timeCursorColor = Color.red;
	waveform.drawsWaveForm = true;
	waveform.gridOn = true;
	waveform.gridResolution = 0.2;
});

window.front;

OSCdef(\visualizerOSC,{|msg, time, addr, recvPort|
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

	{synthLabel.string = ~synth[0].defName;
		if ((~synth[0].defName != ~synthNames[~selectedSynth]), {
			selectedSynthLabel.string = ~synthNames[~selectedSynth];
		}, {
			selectedSynthLabel.string = "";
		});
	}.defer;

	2.do({arg i;
		var offset = 10 * i;
		if ((msg[offset + 1] == 0) || ((msg[offset + 2] - 0.5).abs > 0.5), {
			{
				waveforms[i].timeCursorOn = false;
			}.defer;
		}, {
			{
				waveforms[i].timeCursorOn = true;
				waveforms[i].timeCursorPosition = waveforms[i].numFrames * (msg[offset + 2]);
				gripSliders[i].value = msg[offset + 9];
				ySliders[i].value = msg[offset + 3];
				zSliders[i].value = 1 - msg[offset + 4];
				rollKnobs[i].value = abs(msg[offset + 5]) / pi;
				yawKnobs[i].value = 1 - (abs(msg[offset + 7]) / pi);
			}.defer;
		});
	});
}, '/LeapMotion', recvPort: 5347);

CmdPeriod.doOnce({
	window.close;
});