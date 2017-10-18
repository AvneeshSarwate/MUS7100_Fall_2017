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

var ballsNumber = new Nexus.Number('#ballsNumber');
ballsNumber.link(ballsSlider);

var ballsButton = new Nexus.Button('#ballsButton');

/*
    OSC Communication and Handlers
*/
var port = new osc.WebSocketPort({
    url: "ws://128.61.5.197:8081" // *** CHANGE THIS TO LAPTOP IP ***
});

port.on("message", function (oscMessage) {
    // Configure handlers here
    $('#m').text(oscMessage.args[1]);
    if(oscMessage.address == "/saveWorld") saveWorld(oscMessage.args[0]);
    if(oscMessage.address == "/loadWorld") loadWorld(oscMessage.args[0]);
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
            if(collisionPair){
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
            if(collisionPair){
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

    var getCollisionPair = function(pair) {
        if(pair.bodyA.label.match(/(Wall)[\s\S]*/)){
            return {
                'wall': pair.bodyA.label,
                'ball': pair.bodyB.id - 6
            }
        }
        else if(pair.bodyA.label.match(/(Wall)[\s\S]*/)){
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
    World.add(world, [
        Bodies.rectangle(400, 0, 800, 50, {isStatic: true, label: 'Wall 0', render: bodyStyle}),
        Bodies.rectangle(400, 600, 800, 50, {isStatic: true, label: 'Wall 2', render: bodyStyle}),
        Bodies.rectangle(800, 300, 50, 600, {isStatic: true, label: 'Wall 1', render: bodyStyle}),
        Bodies.rectangle(0, 300, 50, 600, {isStatic: true, label: 'Wall 3', render: bodyStyle})
    ]);

    var stack = Composites.stack(70, 100, 5, 2, 50, 50, function (x, y) {
        return Bodies.circle(x, y, 30, {restitution: 1, render: bodyStyle, label: 'Ball'});
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
var saveWorld = function(worldName) {
    worlds[worldName] = _.cloneDeep(Matter.Composite.allComposites(matterContext['engine'].world));
}

// Load a world
var loadWorld = function(worldName) {
    
    var loadedWorld =_.cloneDeep(worlds[worldName]);
    Matter.World.remove(matterContext['engine'].world, Matter.Composite.allComposites(matterContext['engine'].world), deep=true);
    Matter.World.addComposite(matterContext['engine'].world, loadedWorld[0]);

    console.log("World " + worldName + " loaded.");
}

// Save the first set of active balls
var ballHistory;
var composites = Matter.Composite.allComposites(matterContext['engine'].world);
_.each(composites, function(composite){
    if(composite.label == "Balls"){
        ballHistory = _.cloneDeep(composite.bodies);
    } 
});

frictSlider.on('change', function (value) {
    var balls = [];
    var composites = Matter.Composite.allComposites(matterContext['engine'].world);
    _.each(composites, function(composite){
        if(composite.label == "Balls") balls = composite.bodies;
    });

    for (var i = 0; i < balls.length; i++) {
        ball = balls[i];
        ball.frictionAir = value / 10;
    }

    for (var i = 0; i < ballHistory.length; i++) {
        ball = ballHistory[i];
        ball.frictionAir = value / 10;
    }
});

ballsSlider.on('change', function (value) {
    console.log(value);
    var balls, ballsComposite;
    var composites = Matter.Composite.allComposites(matterContext['engine'].world);
    _.each(composites, function(composite){
        if(composite.label == "Balls"){
            ballsComposite = composite;
            balls = composite.bodies;  
        } 
    });

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
});