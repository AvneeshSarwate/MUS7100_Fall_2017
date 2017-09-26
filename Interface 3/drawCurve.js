inlets = 1;
outlets = 1;

var xDim = jsarguments[1];
var yDim = jsarguments[2];
var copyMatrix = new JitterMatrix(1, "char", xDim, yDim);
var whiteMatrix = new JitterMatrix("white");
var blackMatrix = new JitterMatrix("black");
var numBeats = 16;
var lineThickness = 65;
var stepsPerBeat = 40; //this is hardcoded both here and in LFOFM.scd
var numSteps = numBeats * stepsPerBeat; 
var stepWidth = Math.floor(xDim/numSteps);
var yRange = yDim - lineThickness;
var curveVals = [];
var scaleVal = 1;

function map(arr, func){
  var newArr = [];
  for(var i = 0; i < arr.length; i++) {newArr.push(func(arr[i]))}
  return newArr;
}

function bang(){
	copyMatrix.frommatrix(whiteMatrix);
	drawCurve();
	outlet(0, "jit_matrix", copyMatrix.name);
}

function step(stepPos){
	
}

function setCurve(){
	curveVals = [arguments][0];
	scaleVal = getScaleValue(curveVals);
	post("Scale val", scaleVal);
	post();
	drawCurve();
}

function getMaxOfArray(numArray) {
  return Math.max.apply(null, numArray);
}

function getMinOfArray(numArray) {
  return Math.min.apply(null, numArray);
}

function getScaleValue(numArray){
	var high = getMaxOfArray(numArray);
	var low = getMinOfArray(numArray);
	return Math.max(Math.abs(high), Math.abs(low));
}

function drawCurve() {
	copyMatrix.frommatrix(whiteMatrix);
	var old_dstdimstart = copyMatrix.dstdimstart;
	var old_dstdimend = copyMatrix.dstdimend;
	copyMatrix.usedstdim = 1;
	for(var i = 0; i < curveVals.length; i++){
		var pointRectLeft  = i*stepWidth;
		//normalization assumes wave is coming in as +- 64 (midi wave)
		var pointRectBottom = ((curveVals[i]/64) + 1) / 2 * yRange;
		var v1 = Math.max(0, yDim - pointRectBottom);
		var v2 = Math.min(yDim, yDim - (pointRectBottom+lineThickness));
		copyMatrix.dstdimstart = [i, v1];
		copyMatrix.dstdimend = [i+1, v2];
		copyMatrix.frommatrix(blackMatrix);
		var yBarSize = (yDim - pointRectBottom) - (yDim - (pointRectBottom+lineThickness));
	}
	copyMatrix.dstdimstart = old_dstdimstart;
	copyMatrix.dstdimend = old_dstdimend;
	copyMatrix.usedstdim = 0;
}