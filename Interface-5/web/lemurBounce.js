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

/*
    OSC Communication and Handlers
*/
var port = new osc.WebSocketPort({
    url: "ws://192.168.0.107:8081" // *** CHANGE THIS TO LAPTOP IP ***
});

port.on("message", function (oscMessage) {
    // Configure handlers here
    $('#m').text(oscMessage.args[1]);
    if (oscMessage.address == "/saveWorld") saveWorld(oscMessage.args[0]);
    if (oscMessage.address == "/loadWorld") loadWorld(oscMessage.args[0]);
    if (oscMessage.address == "/setParam") setParam(oscMessage.args);
});

port.open();

var sayHello = function () {
    port.send({
        address: "/hello",
        args: ["world"]
    });
};

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
        Bodies = Matter.Bodies;

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
            width: 800,
            height: 600,
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
        max: {x: 800, y: 600}
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

    // context for MatterTools.Demo
    return {
        engine: engine,
        runner: runner,
        render: render,
        canvas: render.canvas,
        stop: function () {
            Matter.Render.stop(render);
            Matter.Runner.stop(runner);
        }
    };
})());

var worlds = {};

// Save the current world to a dictionary
var saveWorld = function (worldName) {
    worlds[worldName] = _.cloneDeep(Matter.Composite.allComposites(matterContext['engine'].world));
};

// Load a world
var loadWorld = function (worldName) {

    var loadedWorld = _.cloneDeep(worlds[worldName]);
    Matter.World.remove(matterContext['engine'].world, Matter.Composite.allComposites(matterContext['engine'].world), deep = true);
    Matter.World.addComposite(matterContext['engine'].world, loadedWorld[0]);

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

// Get the composite for the set of balls
var getBallsComposite = function () {
    var ballsComposite = null;
    var composites = Matter.Composite.allComposites(matterContext['engine'].world);
    _.each(composites, function (composite) {
        if (composite.label == "Balls") {
            ballsComposite = composite;
        }
    });
    return ballsComposite
};


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

// Save the first set of active balls
var ballHistory = _.cloneDeep(getBalls());

frictSlider.on('change', function (value) {
    setFriction(value)
});

var setBalls = function (value) {
    var balls = getBalls();
    var ballsComposite = getBallsComposite();

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

var setGate = function (m, b) {

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
        return addGate(points);
    }
};

var convertQuadrant = function (points) {
    var width = matterContext['canvas'].width;
    var height = matterContext['canvas'].height;

    points[0].y = height - points[0].y;
    points[1].y = height - points[1].y;

    return points;
};

var addGate = function (points) {
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

    console.log(x_off, y_off, verts);

    var body = Matter.Bodies.fromVertices(width / 2 - x_off, height / 2 - y_off, verts);
    body.render.fillStyle = '#a01';
    body.collisionFilter = {group: -1, category: 1};
    Matter.World.add(matterContext['engine'].world, body);
};

