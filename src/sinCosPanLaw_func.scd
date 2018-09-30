~sinCosPanLaw = { arg angleInDegrees = 0;
	var angleInRadians;
	var theta;

	angleInRadians = angleInDegrees/180*pi;
	theta = pi/4 - angleInRadians;
	[theta.cos, theta.sin]
}