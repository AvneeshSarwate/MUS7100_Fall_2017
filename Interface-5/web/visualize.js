/*
    OSC Communication and Handlers
*/
var port = new osc.WebSocketPort({
    url: "ws://" + window.location.hostname + ":8083"
});

port.on("message", function (oscMessage) {
    // Configure handlers here
    if (oscMessage.address == "/visualize") visualize(oscMessage.args);
});

port.open();

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

    var bodyStyle = {fillStyle: '#fff'};

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

// Retrieve the set of balls
var getBalls = function () {
    var balls = [];
    var composites = Matter.Composite.allComposites(matterContext['engine'].world);
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

var worlds = {};

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

Matter.Events.on(matterContext['engine'], 'afterUpdate', function (event) {
    var height = matterContext['canvas'].height;
    var balls = getBalls();

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

var getDist = function(well, ball) {
    return Math.sqrt( Math.pow(ball.position.x - well.position.x, 2) + Math.pow(ball.position.y - well.position.y, 2) )
};

var getAngle = function(x1, y1, x2, y2) {
    var del_x = x2 - x1;
    var del_y = y2 - y1;
    return Math.atan2(del_y, del_x);
};

var visualizing = null;

// Load a world
var visualize = function (args) {
    if(visualizing) clearInterval(visualizing);
    visualizing = setInterval(function() { 
        $( "#matter" ).fadeTo( 20 , 0.5, function() {
            $( "#matter" ).fadeTo( 20 , 1.0, function() {});
        });
        refreshLoadedWorld(args); 
    }, 1000);
};

var refreshLoadedWorld = function(args) {
    var worldName = args[0];
    var resurrect = new Resurrect();
    var bodies = resurrect.resurrect(args[1]);

    var composites = Matter.Composite.allComposites(matterContext['engine'].world);

    _.each(composites, function(composite){
        Matter.Composite.clear(composite);
        _.each(bodies, function(bodyList, label){
            _.each(bodyList, function(body){
                if(composite.label == label) Matter.Composite.add(composite, body);
            });
        });
    });

    $('#world').text(worldName);

    console.log("World " + worldName + " loaded.");
};