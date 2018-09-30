# AIRWAVE #

A gesture-based granular synthesis controller, using a Leap Motion controller
communicating with Python and SuperCollider

## Dependencies ##
* Leap Motion Orion (requiring Windows)
* Python 2.7
* SuperCollider 3+
* pyOsc 0.3.5b5294

## Components ##
### Gesture Tracker - src/gesture_tracker.py ###
The gesture tracker is a Python script that receives
information from the Leap Motion controller, processes / translates it, then
passes it onto the SuperCollider scripts through OSC at port 5437 for synthesis
and visualization. To improve the accuracy and range of the Leap Motion, a
bound has been placed on the location in space where interactions are monitored. 

### Driver - src/AIRWAVE.scd ###
The driver is a SuperCollider script that loads and executes every other
SuperCollider script that AIRWAVE requires for synthesis and visualization.
It handles booting the SuperCollider server, loading in the audio file
specified within this script, and managing synth switching.

### Visualizer - src/visualizer.scd ###
The visualizer is a SuperCollider script that is loaded by the driver. It manages
building and manipulating a simple GUI to give the user information about
their hand positioning. The visualizer is split into two halves, with each side
providing information about their respective hand (left / right). The following
information is displayed:
* Palm X-coordinate (red line on the audio file waveform)
    * The position of the red line of the waveform mimics the position of your hand
    relative to the Leap Motion controller
    * If the red line is not present, either your hand is not over the Leap Motion or
    it cannot be tracked
* Grip (slider)
    * 0 while your palm is open
    * 1 while making a fist a fist
* Palm Y-coordinate (slider)
    * 0 when the elevation of your hand relative to the Leap Motion is low
    * 1 when the elevation of your hand relative to the Leap Motion is high
* Palm Z-coordinate (slider)
    * 0 when your hand is in between you and the Leap Motion
    * 1 when the Leap Motion is between you and your hand
* Palm Roll (knob)
    * 0 (rotated fully to the left) when your palm is perpendicular to the floor
     and facing to the right of you
    * 1 (rotated fully to the right) when your palm is perpendicular to the floor
    and facing your left.
    * 0.5 (vertical position) when your palm is parallel to the floor
* Palm Yaw (knob)
    * 0 (rotated fully to the left) when your hand is rotated at your wrist to the left
    * 1 (rotated fully to the right) when your hand is rotated at your wrist to the right
    * 0.5 (vertical position) when your hand is pointing directly forwards

### Synthesizers - src/*_synth.scd ###
AIRWAVE is designed to be easily customizable to those who are familiar with SuperCollider.
The application can easily handle added synthesis definitions or tweaks to existing ones.
To create a new synth, one must:
1. Write a script that defines / loads a synth onto the server and defines an OSCdef to
handle the Leap Motion data coming in from port 5347. It should be located in src/ and 
have a filename that ends with _synth.scd.
2. The name of the synth def must be added to ~synthNames in the driver script.
3. Relaunch AIRWAVE to begin playing with the newly created synth

Note: OSCdefs update the parameters of the currently playing synth by referencing global
variable ~synth and using ".set". ~synth is an array of two synths, with indexes 0 and 1 being
generally used for the left and right hands respectively. It is very useful to look through 
existing synths (e.g. sync_synth.scd) before attempting to create your own.
    
## Launching AIRWAVE ##
1. Ensure that your Leap Motion is connected to your computer and the Leap Motion service is
running. This can be confirmed through the Leap Motion Control Panel.
2. The Leap Motion controller should be oriented so that it is directly in front of you on a
flat surface. Its length should move from the left to the right and its width should move towards
and away from you. Ensure that the green light is facing you. For best performance, you should place
the Leap Motion in a location with minimal sunlight, high ceilings, or without any other factors
that may minimize the contrast between your hand and the environment. Additionally, it is best
to roll up your sleeves.
3. Launch the gesture tracker (src/gesture_tracker.py). This is typically done through a 
command terminal. A message should display stating that the Leap Motion is connecting. 
"Connected" will display when the Leap Motion is detected. When you are finished using AIRWAVE,
you can exit the script by pressing enter.
4. Launch the driver (src/AIRWAVE.scd). In SuperCollider, simply ctrl + right click the main body
of the script. The visualizer should open after a few seconds. To kill AIRWAVE, simply press
ctrl + period.
