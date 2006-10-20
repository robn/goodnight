var graphics = {
    ":tile":   [ "gfx/tile/tile.png",        100, 46, 50, 23 ],
    ":hover":  [ "gfx/tile/hover.png",       100, 46, 50, 23 ],

    army:      [ "gfx/terrain/army.png"    , 54,  14, 27, 14 ],
    city:      [ "gfx/terrain/city.png"    , 64,  30, 32, 30 ],
    forest:    [ "gfx/terrain/forest.png"  , 52,  26, 26, 26 ],
    fortress:  [ "gfx/terrain/fortress.png", 42,  12, 21, 12 ],
    fountant:  [ "gfx/terrain/fountain.png", 29,  15, 15, 15 ],
    gate:      [ "gfx/terrain/gate.png"    , 51,  13, 25, 13 ],
    hall:      [ "gfx/terrain/hall.png"    , 26,  15, 13, 15 ],
    hills:     [ "gfx/terrain/hills.png"   , 64,  11, 32, 11 ],
    hut:       [ "gfx/terrain/hut.png"     , 11,  12, 5,  12 ],
    mist:      [ "gfx/terrain/mist.png"    , 60,  15, 30, 15 ],
    mountain:  [ "gfx/terrain/mountain.png", 64,  40, 32, 40 ],
    palace:    [ "gfx/terrain/palace.png"  , 61,  25, 30, 25 ],
    pit:       [ "gfx/terrain/pit.png"     , 37,  8,  18, 8  ],
    stones:    [ "gfx/terrain/stones.png"  , 28,  19, 14, 19 ],
    temple:    [ "gfx/terrain/temple.png"  , 65,  33, 32, 33 ],
    tower:     [ "gfx/terrain/tower.png"   , 16,  39, 8,  39 ],
    wastes:    [ "gfx/terrain/wastes.png"  , 61,  14, 30, 14 ]
};

function go () {
    var cache = new Iso.Cache();
    cache.addGraphics(graphics);

//    var m = new Map;
    // something

    var element = document.getElementById("grid");
    var grid = new Iso.Grid(cache, element, null, 0, 0, window.innerWidth, window.innerHeight);

    element.addEventListener("mousemove", function (e) {
        grid.hover(e.pageX, e.pageY);
    }, false);
}

function debug (thing) {
    if (typeof thing == "object" && thing.constructor != Array) {
        var l = new Array();
        var i;
        for (i in thing)
            l.push(i + ": " + thing[i])
        debug(l);
        return;
    }

    var p = document.getElementById("debug");

    while (p.hasChildNodes()) {
        p.removeChild(p.lastChild);
    }

    if (typeof thing == "string") {
        p.appendChild(document.createTextNode(thing));
    }

    else if (typeof thing == "object" && thing.constructor == Array) {
        var i;
        for (i in thing) {
            p.appendChild(document.createTextNode(thing[i]));
            p.appendChild(document.createElement("br"));
        }
    }
}
