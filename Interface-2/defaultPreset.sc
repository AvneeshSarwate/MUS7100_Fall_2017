var o, p;
o = [
	Array.prNew(3),  Dictionary.prNew,  Array.prNew(64),  Array.prNew(1),  
	Array.prNew(1),  Array.prNew(1),  Array.prNew(2),  Array.prNew(2),  
	Array.prNew(1),  "/1/playrate",  Array.prNew(1),  Array.prNew(1),  
	"/2/pitch",  "/2/playrate",  Array.prNew(1),  Array.prNew(1),  
	Array.prNew(1),  "/1/pitch",  Array.prNew(1)
];
p = [
	// Array
	0, [ 71,  'preset',  o[1] ],  
	// Dictionary
	1, [ array: o[2],  size: 16 ],  
	// Array
	2, [ nil,  nil,  '/2/q',  o[3],  
		nil,  nil,  nil,  nil,  
		nil,  nil,  nil,  nil,  
		nil,  nil,  '/2/width',  o[4],  
		'/1/duration',  o[5],  '/2/volres',  o[6],  
		'/1/volres',  o[7],  '/1/q',  o[8],  
		o[9],  11.0,  '/2/pos',  o[10],  
		'/2/speed',  o[11],  o[12],  11.0,  
		o[13],  11.0,  nil,  nil,  
		'/1/speed',  o[14],  nil,  nil,  
		nil,  nil,  nil,  nil,  
		nil,  nil,  '/1/pos',  o[15],  
		nil,  nil,  nil,  nil,  
		nil,  nil,  '/2/duration',  o[16],  
		o[17],  11.0,  '/1/width',  o[18],  
		nil,  nil,  nil,  nil ],  
	// Array
	3, [ 0.59751772880554 ],  
	// Array
	4, [ 0.12943261861801 ],  
	// Array
	5, [ 0.42907801270485 ],  
	// Array
	6, [ 0.0,  0.24187725782394 ],  
	// Array
	7, [ 0.30708661675453,  0.20216606557369 ],  
	// Array
	8, [ 0.1719858199358 ],  
	// Array
	10, [ 0.13058942556381 ],  
	// Array
	11, [ 0.15837104618549 ],  
	// Array
	14, [ 0.66742080450058 ],  
	// Array
	15, [ 0.0 ],  
	// Array
	16, [ 0.1861702054739 ],  
	// Array
	18, [ 0.037234041839838 ]
];
prUnarchive(o,p);
