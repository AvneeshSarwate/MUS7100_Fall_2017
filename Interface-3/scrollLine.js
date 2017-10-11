inlets = 1;
outlets = 1;

var xDim = jsarguments[1];
var yDim = jsarguments[2];
var copyMatrix = new JitterMatrix(1, "char", xDim, yDim);
var whiteMatrix = new JitterMatrix("white");
var blackMatrix = new JitterMatrix("black");
var stepsPerBar = 10; //this is hardcoded into LFOFM.scd
var numBars = 16;
var numSteps = stepsPerBar*numBars;
var stepWidth = Math.floor(xDim/numSteps);
var ind = 0;

function map(arr, func){
  var newArr = [];
  for(var i = 0; i < arr.length; i++) {newArr.push(func(arr[i]))}
  return newArr;
}

function bang(){
	copyMatrix.frommatrix(whiteMatrix);
	var old_dstdimstart = copyMatrix.dstdimstart;
	var old_dstdimend = copyMatrix.dstdimend;
	copyMatrix.usedstdim = 1;
	copyMatrix.dstdimstart = [ind*stepWidth, 0];
	copyMatrix.dstdimend = [(ind+1)*stepWidth, yDim];
	copyMatrix.frommatrix(blackMatrix);
	copyMatrix.dstdimstart = old_dstdimstart;
	copyMatrix.dstdimend = old_dstdimend;
	copyMatrix.usedstdim = 0;
	outlet(0, "jit_matrix", copyMatrix.name);
	ind = (ind+1)%numSteps;
}


function resetCounter(index){
	ind = index;
}