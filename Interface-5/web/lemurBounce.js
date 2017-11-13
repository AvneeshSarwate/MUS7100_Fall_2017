/*
    NexusUI Elements
*/
var frictSlider = new Nexus.Slider('#frictSlider', {
    'size': [60, 200],
    'mode': 'relative',  // 'relative' or 'absolute'
    'min': 0,
    'max': 1,
    'step': 0.01,
    'value': 0
});

var frictSliderLC = new Nexus.Slider('#frictSliderLC', {
    'size': [60, 200],
    'mode': 'relative',  // 'relative' or 'absolute'
    'min': 0,
    'max': 1,
    'step': 0.01,
    'value': 0
});

frictSliderLC.colorize("accent", "#48f");

var frictNumber = new Nexus.Number('#frictNumber');
frictNumber.link(frictSlider);

var frictButton = new Nexus.Button('#frictButton');

var ballsSlider = new Nexus.Slider('#ballsSlider', {
    'size': [60, 200],
    'mode': 'relative',  // 'relative' or 'absolute'
    'min': 1,
    'max': 10,
    'step': 1,
    'value': 10
});

var ballsSliderLC = new Nexus.Slider('#ballsSliderLC', {
    'size': [60, 200],
    'mode': 'relative',  // 'relative' or 'absolute'
    'min': 1,
    'max': 10,
    'step': 1,
    'value': 10
});

ballsSliderLC.colorize("accent", "#48f");

var ballsNumber = new Nexus.Number('#ballsNumber');
ballsNumber.link(ballsSlider);

var ballsButton = new Nexus.Button('#ballsButton');

var massSlider = new Nexus.Slider('#massSlider', {
    'size': [60, 200],
    'mode': 'relative',  // 'relative' or 'absolute'
    'min': 1,
    'max': 10,
    'step': 0.01,
    'value': 3
});

var massSliderLC = new Nexus.Slider('#massSliderLC', {
    'size': [60, 200],
    'mode': 'relative',  // 'relative' or 'absolute'
    'min': 1,
    'max': 10,
    'step': 0.01,
    'value': 3
});

massSliderLC.colorize("accent", "#48f");

var massNumber = new Nexus.Number('#massNumber');
massNumber.link(massSlider);

var massButton = new Nexus.Button('#massButton');

var slowFrictSlider = new Nexus.Slider('#slowFrictSlider', {
    'size': [60, 200],
    'mode': 'relative',  // 'relative' or 'absolute'
    'min': 0,
    'max': 1,
    'step': 0.01,
    'value': 0
});

var slowFrictNumber = new Nexus.Number('#slowFrictNumber');
slowFrictNumber.link(slowFrictSlider);

/*
    OSC Communication and Handlers
*/
var port = new osc.WebSocketPort({
    url: "ws://" + window.location.hostname + ":8081"
});

port.on("message", function (oscMessage) {
    // Configure handlers here
    $('#m').text(oscMessage.args[1]);
    if (oscMessage.address == "/saveWorld") saveWorld(oscMessage.args[0]);
    if (oscMessage.address == "/loadWorld") loadWorld(oscMessage.args[0]);
    if (oscMessage.address == "/setGate") setGate(oscMessage.args[0], oscMessage.args[1], oscMessage.args[2]);
    if (oscMessage.address == "/toggleGate") toggleGate(oscMessage.args[0]);
    if (oscMessage.address == "/setParam") setParam(oscMessage.args);
    if (oscMessage.address == "/slingshot") slingshot(oscMessage.args);
    if (oscMessage.address == "/gravity") gravity(oscMessage.args);
    if (oscMessage.address == "/visualize") visualize(oscMessage.args);
});

port.open();

var port_viz = new osc.WebSocketPort({
    url: "ws://" + window.location.hostname + ":8082"
});

port_viz.on("message", function (oscMessage) {
    // Configure handlers here
});

port_viz.open();

/*
    Matter.js content
 */
$(window.matterContext = (function () {
    Matter.use('matter-wrap');

    var Engine = Matter.Engine,
        Render = Matter.Render,
        Runner = Matter.Runner,
        Body = Matter.Body,
        Events = Matter.Events,
        Composite = Matter.Composite,
        Composites = Matter.Composites,
        Common = Matter.Common,
        MouseConstraint = Matter.MouseConstraint,
        Mouse = Matter.Mouse,
        World = Matter.World,
        Bodies = Matter.Bodies,
        WIDTH = 800,
        HEIGHT = 800;

    // create engine
    var engine = Engine.create(),
        world = engine.world;

    // Set gravity to none
    world.gravity.scale = 0.000;

    // create renderer
    var render = Render.create({
        element: document.getElementById('matter'),
        engine: engine,
        options: {
            width: WIDTH,
            height: HEIGHT,
            wireframes: false
        }
    });

    Render.run(render);

    // create runner
    var runner = Runner.create();
    Runner.run(runner, engine);

    // an example of using composite events on the world
    Events.on(world, 'afterAdd', function (event) {
        console.log('added to world:', event.object);
    });

    // an example of using beforeUpdate event on an engine
    Events.on(engine, 'beforeUpdate', function (event) {
        var engine = event.source;

        // apply random forces every 5 secs
        // if (event.timestamp % 5000 < 50)
        //     shakeScene(engine);
    });

    // an example of using collisionStart event on an engine
    Events.on(engine, 'collisionStart', function (event) {
        var pairs = event.pairs;

        // change object colours to show those starting a collision
        for (var i = 0; i < pairs.length; i++) {
            var pair = pairs[i];
            pair.bodyA.render.fillStyle = '#aaa';
            pair.bodyB.render.fillStyle = '#aaa';

            collisionPair = getCollisionPair(pair);
            if (collisionPair) {
                wall = collisionPair['wall'];
                wallIndex = parseInt(wall[wall.length - 1]);
                ballIndex = collisionPair['ball'];
                port.send({
                    address: "/toSC",
                    args: ["/collision", ballIndex, wallIndex, 'start']
                });
            }
        }
    });

    // an example of using collisionActive event on an engine
    Events.on(engine, 'collisionActive', function (event) {
        var pairs = event.pairs;

        // change object colours to show those in an active collision (e.g. resting contact)
        for (var i = 0; i < pairs.length; i++) {
            var pair = pairs[i];
            pair.bodyA.render.fillStyle = '#aaa';
            pair.bodyB.render.fillStyle = '#aaa';
        }
    });

    // an example of using collisionEnd event on an engine
    Events.on(engine, 'collisionEnd', function (event) {
        var pairs = event.pairs;

        // change object colours to show those ending a collision
        for (var i = 0; i < pairs.length; i++) {
            var pair = pairs[i];

            pair.bodyA.render.fillStyle = '#fff';
            pair.bodyB.render.fillStyle = '#fff';

            collisionPair = getCollisionPair(pair);
            if (collisionPair) {
                wall = collisionPair['wall'];
                wallIndex = parseInt(wall[wall.length - 1]);
                ballIndex = collisionPair['ball'];
                port.send({
                    address: "/toSC",
                    args: ["/collision", ballIndex, wallIndex, 'end']
                });
            }
        }
    });

    var getCollisionPair = function (pair) {
        if (pair.bodyA.label.match(/(Wall)[\s\S]*/)) {
            return {
                'wall': pair.bodyA.label,
                'ball': pair.bodyB.id - 6
            }
        }
        else if (pair.bodyA.label.match(/(Wall)[\s\S]*/)) {
            return {
                'wall': pair.bodyB.label,
                'ball': pair.bodyA.id - 6
            }
        }
        else {
            return null
        }
    };

    var bodyStyle = {fillStyle: '#fff'};

    // Add walls to scene
    // World.add(world, [
    //     Bodies.rectangle(400, 0, 800, 50, {isStatic: true, label: 'Wall 0', render: bodyStyle}),
    //     Bodies.rectangle(400, 600, 800, 50, {isStatic: true, label: 'Wall 2', render: bodyStyle}),
    //     Bodies.rectangle(800, 300, 50, 600, {isStatic: true, label: 'Wall 1', render: bodyStyle}),
    //     Bodies.rectangle(0, 300, 50, 600, {isStatic: true, label: 'Wall 3', render: bodyStyle})
    // ]);

    var stack = Composites.stack(70, 100, 5, 2, 50, 50, function (x, y) {
        // Remove the collisionFilter to get the bodies to collide
        return Bodies.circle(x, y, 30, {
            restitution: 1,
            render: bodyStyle,
            label: 'Ball',
            collisionFilter: {group: -1, category: 1}
        });
    });

    stack.label = "Balls";
    World.add(world, stack);

    var gates = Composite.create({label: 'Gates'});
    World.add(world, gates);

    var wellComposite = Composite.create({label: 'Wells'});
    World.add(world, wellComposite);

    // World.add(wellComposite, Bodies.circle(600, 600, 50, {
    //         restitution: 1,
    //         render: bodyStyle,
    //         label: 'Well',
    //         collisionFilter: {group: -1, category: 1}
    //     })
    // );

    window.shakeScene = function (engine) {
        var bodies = Composite.allBodies(engine.world);

        for (var i = 0; i < bodies.length; i++) {
            var body = bodies[i];

            if (!body.isStatic && body.position.y >= 500) {
                var forceMagnitude = 0.02 * body.mass;

                Body.applyForce(body, body.position, {
                    x: (forceMagnitude + Common.random() * forceMagnitude) * Common.choose([1, -1]),
                    y: -forceMagnitude + Common.random() * -forceMagnitude
                });
            }
        }
    };

    // add mouse control
    var mouse = Mouse.create(render.canvas),
        mouseConstraint = MouseConstraint.create(engine, {
            mouse: mouse,
            constraint: {
                stiffness: 0.2,
                render: {
                    visible: false
                }
            }
        });

    World.add(world, mouseConstraint);

    // keep the mouse in sync with rendering
    render.mouse = mouse;

    // an example of using mouse events on a mouse
    Events.on(mouseConstraint, 'mousedown', function (event) {
        var mousePosition = event.mouse.position;
        console.log('mousedown at ' + mousePosition.x + ' ' + mousePosition.y);
        console.log(Composite.allBodies(stack));
    });

    // an example of using mouse events on a mouse
    Events.on(mouseConstraint, 'mouseup', function (event) {
        var mousePosition = event.mouse.position;
        console.log('mouseup at ' + mousePosition.x + ' ' + mousePosition.y);
    });

    // an example of using mouse events on a mouse
    Events.on(mouseConstraint, 'startdrag', function (event) {
        console.log('startdrag', event);
    });

    // an example of using mouse events on a mouse
    Events.on(mouseConstraint, 'enddrag', function (event) {
        console.log('enddrag', event);
    });

    // fit the render viewport to the scene
    Render.lookAt(render, {
        min: {x: 0, y: 0},
        max: {x: WIDTH, y: HEIGHT}
    });

    // wrapping using matter-wrap plugin
    var allBodies = Composite.allBodies(world);

    _.each(allBodies, function (body) {

        // Wrap bodies around canvas
        body.plugin.wrap = {
            min: {x: render.bounds.min.x, y: render.bounds.min.y},
            max: {x: render.bounds.max.x, y: render.bounds.max.y}
        };

        // Kill all friction
        body.friction = 0;
        body.frictionAir = 0;
        body.frictionStatic = 0;
    });

    /*
        Slow Ball Instance
    */
    var WIDTH_SLOW = 400,
        HEIGHT_SLOW = 400;

    // create engine
    var engine_slow = Engine.create(),
        world_slow = engine_slow.world;

    // Set gravity to none
    world_slow.gravity.scale = 0.000;

    // create renderer
    var render_slow = Render.create({
        element: document.getElementById('matter_slow'),
        engine: engine_slow,
        options: {
            width: WIDTH_SLOW,
            height: HEIGHT_SLOW,
            wireframes: false
        }
    });

    Render.run(render_slow);

    // create runner
    var runner_slow = Runner.create();
    Runner.run(runner_slow, engine_slow);

    var bodyStyle_slow = {fillStyle: '#fff'};

    var stack_slow = Composites.stack(70, 100, 2, 2, 50, 50, function (x, y) {
        // Remove the collisionFilter to get the bodies to collide
        return Bodies.circle(x, y, 20, {
            restitution: 1,
            render: bodyStyle_slow,
            label: 'Ball',
            collisionFilter: {group: -1, category: 1}
        });
    });

    stack_slow.label = "Balls";

    World.add(world_slow, stack_slow);

    var gates_slow = Composite.create({label: 'Gates'});

    World.add(world_slow, gates_slow);

    var mouse_slow = Mouse.create(render_slow.canvas),
        mouseConstraint_slow = MouseConstraint.create(engine_slow, {
            mouse: mouse_slow,
            constraint: {
                stiffness: 0.2,
                render: {
                    visible: false
                }
            }
        });

    World.add(world_slow, mouseConstraint_slow);

    // keep the mouse in sync with rendering
    render_slow.mouse = mouse_slow;

    // fit the render viewport to the scene
    Render.lookAt(render_slow, {
        min: {x: 0, y: 0},
        max: {x: WIDTH_SLOW, y: HEIGHT_SLOW}
    });

    // wrapping using matter-wrap plugin
    var allBodies_slow = Composite.allBodies(world_slow);

    _.each(allBodies_slow, function (body) {

        // Wrap bodies around canvas
        body.plugin.wrap = {
            min: {x: render_slow.bounds.min.x, y: render_slow.bounds.min.y},
            max: {x: render_slow.bounds.max.x, y: render_slow.bounds.max.y}
        };

        // Kill all friction
        body.friction = 0;
        body.frictionAir = 0;
        body.frictionStatic = 0;
    });

    // context for MatterTools.Demo
    return {
        engine: engine,
        runner: runner,
        render: render,
        canvas: render.canvas,
        stop: function () {
            Matter.Render.stop(render);
            Matter.Runner.stop(runner);
        },
        slowEngine: engine_slow,
        slowCanvas: render_slow.canvas
    };
})());

var worlds = {};

// Save the current world to a dictionary
var saveWorld = function (worldName) {
    newSave = {}
    newSave.world = _.cloneDeep(Matter.Composite.allComposites(matterContext['engine'].world));
    newSave.gates = _.cloneDeep(gates);
    worlds[worldName] = newSave;
    sendVisual(worldName, newSave);
};

// Load a world
var loadWorld = function (worldName) {

    var loadedWorld = _.cloneDeep(worlds[worldName].world);
    Matter.World.remove(matterContext['engine'].world, Matter.Composite.allComposites(matterContext['engine'].world), deep = true);
    _.each(loadedWorld, function(composite){
        Matter.World.addComposite(matterContext['engine'].world, composite);
    });
    gates = worlds[worldName].gates

    console.log("World " + worldName + " loaded.");
};

// Retrieve the set of balls
var getBalls = function () {
    var balls = [];
    var composites = Matter.Composite.allComposites(matterContext['engine'].world);
    _.each(composites, function (composite) {
        if (composite.label == "Balls") balls = composite.bodies;
    })
    return balls;
};

var getSlowBalls = function () {
    var balls = [];
    var composites = Matter.Composite.allComposites(matterContext['slowEngine'].world);
    _.each(composites, function (composite) {
        if (composite.label == "Balls") balls = composite.bodies;
    })
    return balls;
};

// https://en.wikipedia.org/wiki/Help:Distinguishable_colors
// Wine, Red, Orange, Yellow, Jade, Green, Sky, Blue, Violet, White
var colors =['#990000', '#FF0010', '#FFA405', '#FFFF00', '#94FFB5', '#2BCE48', '#5EF1F2', '#0075DC', '#740AFF', '#FFFFFF']
var balls = getBalls();
_.each(balls, function(ball, i){
    ball.render.fillStyle = colors[i];
});

var balls = getSlowBalls();
_.each(balls, function(ball, i){
    ball.render.fillStyle = colors[i];
});

// Gets the composite for a given label
var getCompositeByLabel = function (label) {
    var comp = null;
    var composites = Matter.Composite.allComposites(matterContext['engine'].world);
    _.each(composites, function (composite) {
        if (composite.label == label) {
            comp = composite;
        }
    });
    return comp
};

// Gets the body for a given label
var getBodyByLabel = function (label) {
    var bod = null;
    var bodies = Matter.Composite.allBodies(matterContext['engine'].world);
    _.each(bodies, function (body) {
        if (body.label == label) {
            bod = body;
        }
    });
    return bod
};

// Save the first set of active balls
var ballHistory = _.cloneDeep(getBalls());

var setFriction = function (value) {

    var balls = getBalls();

    for (var i = 0; i < balls.length; i++) {
        ball = balls[i];
        ball.frictionAir = value / 10;
    }

    for (var i = 0; i < ballHistory.length; i++) {
        ball = ballHistory[i];
        ball.frictionAir = value / 10;
    }
};

frictSlider.on('change', function (value) {
    setFriction(value)
});

var setSlowFriction = function (value) {

    var balls = getSlowBalls();

    for (var i = 0; i < balls.length; i++) {
        ball = balls[i];
        ball.frictionAir = value / 10;
    }

    for (var i = 0; i < ballHistory.length; i++) {
        ball = ballHistory[i];
        ball.frictionAir = value / 10;
    }
};

slowFrictSlider.on('change', function (value) {
    setSlowFriction(value)
});

var setBalls = function (value) {
    var balls = getBalls();
    var ballsComposite = getCompositeByLabel('Balls');

    if (value > balls.length) {
        for (var i = balls.length; i < value; i++) {
            newBall = ballHistory[i];
            Matter.Composite.add(ballsComposite, newBall);
        }
    }
    else if (value < balls.length) {
        for (var i = balls.length - 1; i > value - 1; i--) {
            ballToRemove = balls[i];
            ballHistory[i] = ballToRemove;
            Matter.Composite.remove(ballsComposite, ballToRemove);
        }
    }
};

ballsSlider.on('change', function (value) {
    setBalls(value);
});

var setMass = function (value) {

    var balls = getBalls();

    for (var i = 0; i < balls.length; i++) {
        ball = balls[i];
        ball.mass = value;
    }

    for (var i = 0; i < ballHistory.length; i++) {
        ball = ballHistory[i];
        ball.mass = value;
    }
};

massSlider.on('change', function (value) {
    setMass(value)
});

var setParam = function (args) {
    var param = args[0];
    var value = args[1];

    switch (param) {
        case 'balls':
            if (!ballsButton.state) ballsSlider.value = value;
            ballsSliderLC.value = value;
            break;

        case 'friction':
            if (!frictButton.state) frictSlider.value = value;
            frictSliderLC.value = value;
            break;

        default:
            console.log("Unrecognized parameter " + param);
    }
};

var gates = {};

var setGate = function (key, m, b) {

    var width = matterContext['canvas'].width;
    var height = matterContext['canvas'].height;

    var points = [];

    // See if it intersects with top of canvas, y = height
    var top_x = (height - b) / m;
    if (top_x >= 0 && top_x <= width) points.push({'x': top_x, 'y': height});

    // See if it intersects with bottom of canvas, y = 0
    var bot_x = -b / m;
    if (bot_x >= 0 && bot_x <= width) points.push({'x': bot_x, 'y': 0});

    // See if it intersects with left of canvas, x = 0
    if (b > 0 && b < height) points.push({'x': 0, 'y': b});

    // See if it intersects with left of canvas, x = width
    var right_y = (m * width) + b;
    if (right_y > 0 && right_y < height) points.push({'x': width, 'y': right_y});

    if (points.length == 2) {
        points = convertQuadrant(points);
        if(gates[key]){
            var body = getBodyByLabel("Gate #" + key);
            var gatesComposite = getCompositeByLabel('Gates');
            if(body) Matter.World.remove(gatesComposite, body);   
        }
        gates[key] = {'m': m, 'b': b, 'status': [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], 'show':true};
        return addGate(key, points);
    }
};

var convertQuadrant = function (points) {
    var height = matterContext['canvas'].height;

    points[0].y = height - points[0].y;
    points[1].y = height - points[1].y;

    return points;
};

var addGate = function (key, points) {
    // Assume points to be an array of length 2 with JSON objects containing x and y
    var width = matterContext['canvas'].width;
    var height = matterContext['canvas'].height;
    var verts = [];

    _.each(points, function (point) {
        if (point.x == 0 || point.x == width) {
            verts.push(Matter.Vector.create(point.x, point.y));
            if (point.y > height / 2) verts.push(Matter.Vector.create(point.x, point.y - 1));
            else verts.push(Matter.Vector.create(point.x, point.y + 1));
        }
        else if (point.y == 0 || point.y == height) {
            verts.push(Matter.Vector.create(point.x, point.y));
            if (point.x > width / 2) verts.push(Matter.Vector.create(point.x - 1, point.y));
            else verts.push(Matter.Vector.create(point.x + 1, point.y));
        }
    });

    mid_x = (points[0].x + points[1].x) / 2;
    mid_y = (points[0].y + points[1].y) / 2;
    x_off = (width / 2) - mid_x;
    y_off = (height / 2) - mid_y;

    console.log(mid_x, mid_y, x_off, y_off, verts);

    var body = Matter.Bodies.fromVertices((width / 2) - x_off, (height / 2) - y_off, verts);
    body.render.fillStyle = '#a01';
    body.collisionFilter = {group: -1, category: 1};
    body.label = "Gate #" + key;
    var gatesComposite = getCompositeByLabel('Gates');
    Matter.World.add(gatesComposite, body);
};

var toggleGate = function(key) {
    gate = gates[key];
    if(gate.show) {
        // Hide gate
        var gatesComposite = getCompositeByLabel('Gates');
        var body = getBodyByLabel("Gate #" + key);
        if(body) Matter.World.remove(gatesComposite, body);
        gate.show = !gate.show;
    }
    else {
        // Show gate
        setGate(key, gate.m, gate.b);
        gate.show = !gate.show;   
    }
}

Matter.Events.on(matterContext['engine'], 'afterUpdate', function (event) {
    var height = matterContext['canvas'].height;
    var balls = getBalls();

    // Gate cross event handler
    _.each(gates, function(gate, key) {
        if(gate.show){
            _.each(balls, function(ball, j) {
                var x = ball.position.x;
                var y = height - ball.position.y;
                var prevX = ballHistory[j][0];
                var prevY = ballHistory[j][1];
                var xDist = Math.abs(x - prevX);
                var yDist = Math.abs(y-prevY);

                var prevVal = gate.status[j];
                var curVal = Math.sign(y - ((gate.m * x) + gate.b));
                gate.status[j] = curVal;

                if(Math.abs(prevVal - curVal) > 1 && xDist < 50 && yDist < 50){
                    port.send({
                        address: "/toSC",
                        args: ["/gateCross", j, key]
                    });  
                } 
                ballHistory[j] = [x, y];
            });
        }   
    });

    // Gravity well handler
    var wells = getCompositeByLabel('Wells').bodies;
    _.each(wells, function(well) {
        _.each(balls, function(ball){
            var dist = getDist(well, ball);
            if(dist < Infinity && dist > 10) {
                angle = getAngle(ball.position.x, ball.position.y, well.position.x, well.position.y);
                Matter.Body.applyForce(ball, ball.position, {
                    x: (well.mass * ball.mass * Math.cos(angle)) / Math.pow(dist, 2),
                    y: (well.mass * ball.mass * (Math.sin(angle))) / Math.pow(dist, 2)
                });
            }
        });
    });
});

var effectBallList = [0, 0, 0, 0];

Matter.Events.on(matterContext['slowEngine'], 'afterUpdate', function (event) {
    var height = matterContext['slowCanvas'].height;
    var width = matterContext['slowCanvas'].width;
    var radius = Math.sqrt( Math.pow(height/2, 2) + Math.pow(width/2, 2) );
    var balls = getSlowBalls();

    // Gate cross event handler
    _.each(balls, function(ball, index) {
        var dist = getDist({'position': { 'x': width/2, 'y': height/2 } }, ball) / radius;
        if(Math.abs(effectBallList[index] - dist) > 0.001){
            effectBallList[index] = dist;
                port.send({
                address: "/toSC",
                args: ["/effectBall", index, dist]
            });
        }        
    });
});

var getDist = function(well, ball) {
    return Math.sqrt( Math.pow(ball.position.x - well.position.x, 2) + Math.pow(ball.position.y - well.position.y, 2) )
}

var stopBall = function(ballNumber) {
    var balls = getBalls();
    var width = matterContext['canvas'].width;
    var height = matterContext['canvas'].height;

    if(ballNumber <= balls.length){
        var ball = balls[ballNumber - 1];
        Matter.Body.setVelocity(ball, Matter.Vector.create(0, 0));
        Matter.Body.setPosition(ball, Matter.Vector.create(width/2 + (10*Math.random() - 5), height/2 + (10*Math.random() - 5)));
    }
};

var stopAllBalls = function() {
    var balls = getBalls();

    _.each(balls, function(ball){
        Matter.Body.setVelocity(ball, Matter.Vector.create(0, 0));
    });
};

var slingshot = function(args) {
    const MAX_VEL = 0.5;
    var width = matterContext['canvas'].width;
    var height = matterContext['canvas'].height;

    var pos_x = args[0];
    var pos_y = args[1];
    var des_x = args[2];
    var des_y = args[3];

    var mag = args[4];
    var vel = mag * MAX_VEL;

    var del_x = des_x - pos_x;
    var del_y = pos_y - des_y;
    var angle_rads = Math.atan2(del_y, del_x);

    var vel_x = vel * Math.cos(angle_rads);
    var vel_y = -(vel * Math.sin(angle_rads));

    var ballIndexes = [];
    for(var i = 5; i < args.length; i++) ballIndexes.push(args[i]);

    var balls = getBalls();
    var count = 0;
    var x_off = 0;
    var y_off = 0;
    _.each(ballIndexes, function(i) {
        if(count != 0){
            if(count % 2 == 1){
                x_off += 10;
                y_off += 10;
            }
            x_off = Math.sign(del_x) * -1 * x_off;
            y_off = Math.sign(del_y) * -1 * y_off;
        }
        var ball = balls[i];
        Matter.Body.setVelocity(ball, Matter.Vector.create(vel_x, vel_y));
        Matter.Body.setPosition(ball, Matter.Vector.create((pos_x * (width / 8)) + (width / 16) + x_off, (pos_y * (height / 8)) + (height / 16) + y_off));
        count++;
    });
};

var getAngle = function(x1, y1, x2, y2) {
    var del_x = x2 - x1;
    var del_y = y2 - y1;
    return Math.atan2(del_y, del_x);
};

var gravity = function(args) {
    var width = matterContext['canvas'].width;
    var height = matterContext['canvas'].height;
    var bodyStyle = {fillStyle: '#fff'};

    var type = args[0];
    var well_index = args[1];

    if(type == "on"){
        var wellComposite = getCompositeByLabel('Wells');
        Matter.World.add(wellComposite, Matter.Bodies.circle(width/2, height/2, 50, {
                restitution: 1,
                render: bodyStyle,
                label: 'Well ' + well_index,
                collisionFilter: {group: -1, category: 1}
            })
        );
        console.log("well...");
    }
    else if(type == "off"){
        var wellComposite = getCompositeByLabel('Wells');
        var well = getBodyByLabel("Well " + well_index);
        Matter.Composite.remove(wellComposite, well);
    }
    else {
        var well = getBodyByLabel("Well " + well_index);
        var x = args[2] * 2 * (width / 270);
        var y = height - (args[3] * 2 * (height / 270));
        Matter.Body.setPosition(well, Matter.Vector.create(x, y));
        var mass = (args[4] * 0.1) + 0.01;
        Matter.Body.setMass(well, mass);
        well.render.fillStyle = hslToHex(151 - (150 * (args[4]/135)), 100, 50);
    }
};

var hslToHex = function(h, s, l) {
  h /= 360;
  s /= 100;
  l /= 100;
  let r, g, b;
  if (s === 0) {
    r = g = b = l; // achromatic
  } else {
    const hue2rgb = (p, q, t) => {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1 / 6) return p + (q - p) * 6 * t;
      if (t < 1 / 2) return q;
      if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
      return p;
    };
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    r = hue2rgb(p, q, h + 1 / 3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1 / 3);
  }
  const toHex = x => {
    const hex = Math.round(x * 255).toString(16);
    return hex.length === 1 ? '0' + hex : hex;
  };
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
};

var sendVisual = function(worldName){
    var world = worlds[worldName];
    var resurrect = new Resurrect();
    var bodies = {};

    _.each(world.world, function(composite){
        bodies[composite.label] = [];        
        _.each(composite.bodies, function(body){
            bodies[composite.label].push(body);
        });
    });

    var gates = getCompositeByLabel('Gates');
    _.each(gates.bodies, function(body){
        bodies['Gates'].push(body);
    });

    serializedBodies = resurrect.stringify(bodies);
    port_viz.send({
        address: "/visualize",
        args: [worldName, serializedBodies]
    });
};

var lispIt = function(input, output) {
    output += "(";
    
    for(var i = 0; i < input.length; i++)
    {
        if(Array.isArray(input[i]))
        {
            output += lispIt(input[i], output);
            output += " ";
        }
        else
        {
            output += input[i];
            output += " ";
        }
    }
    output += ")";
    return output;
}

lispIt([[1,2,3,4]], "");