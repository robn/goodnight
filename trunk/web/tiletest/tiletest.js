var width = 5;
var height = 7;

var tile_width = 100;
var tile_height = 46;

var half_width = tile_width/2;
var half_height = tile_height/2;

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

function tile_to_map (tile_x, tile_y) {
    /* magic the current tile into an x,y coordinate for the map array */
    var map_y = Math.floor((tile_y * half_width - tile_x * half_height) / (2 * half_width * half_height));
    var map_x = Math.floor((tile_x + half_width * map_y) / half_width);

    return [ map_x, map_y ];
}
    
var select;

function page_to_map (page_x, page_y) {
    /*
     * we consider the map as being two overlaid grids of tiles, one starting
     * at [0,0] and one starting at [half_width,half_height]
     *
     * in the general case, there are always two tiles under the mouse, one
     * from each grid. we need to find the top-left corners of their bounding
     * boxes
     */
    var tile1_x = Math.floor(page_x / tile_width) * tile_width;
    var tile1_y = Math.floor(page_y / tile_height) * tile_height;

    var tile2_x = Math.floor((page_x+half_width) / tile_width) * tile_width - half_width;
    var tile2_y = Math.floor((page_y+half_height) / tile_height) * tile_height - half_height;

    /*
     * to distinguish between the tiles, we need to find the edge that goes
     * between the two tiles and then figure out which side of it the mouse is
     * currently on
     *
     * we cheat slightly. the edge goes between the two tile centres, so we
     * get the centres but swap the y-coords to get the edge endpoints.
     */
    var e1x = tile1_x + half_width; var e1y = tile2_y + half_height;
    var e2x = tile2_x + half_width; var e2y = tile1_y + half_height;

    /* compute the line */
    var m = (e2y-e1y) / (e2x-e1x);
    var c = e1y - m*e1x;

    /* figure out if we're above or below the line */
    var in_tile1 = (page_y > m * page_x+c);
    /* but if tile1 is above tile2, then swap it over */
    if (tile1_y < tile2_y) in_tile1 = !in_tile1;

    /* our tile */
    var tile_x = in_tile1 ? tile1_x : tile2_x;
    var tile_y = in_tile1 ? tile1_y : tile2_y;

    if(!select) {
        select = document.createElement("img");
        select.setAttribute("class", "tile");
        select.setAttribute("src", "select.png");
        select.style.position = "absolute";
        document.body.appendChild(select);
    }
    select.style.top = tile_y;
    select.style.left = tile_x;

    return tile_to_map(tile_x, tile_y);
}

var tiles = [ "red.png", "green.png", "yellow.png", "blue.png" ];

var map = new Array(50);
var p;
for (p = 0; p < 50; p++)
    map[p] = new Array(50);
var t = 0, e = 0;
while (e < 25) {
    for (p = e; p < 50 - e; p++) {
        map[p]  [e] = map[p]  [49-e] = t;
        map[p-e][e] = map[p-e][49-e] = t;
        map[e]  [p] = map[49-e][p]   = t;
        map[e][p-e] = map[49-e][p-e] = t;
    }
    t = (t+1) % 4;
    e++;
}

function add_tile (map_x, map_y, page_x, page_y) {
    var img = document.createElement("img");
    img.setAttribute("class", "tile");

    var map_xy = tile_to_map(page_x, page_y);
//    img.setAttribute("src", tiles[map[map_xy[0]][map_xy[1]+10]]);
    img.setAttribute("src", "blank.png");

    img.style.left = page_x;
    img.style.top = page_y;

    document.body.appendChild(img);
}

function setup_tiles () {
    var max_x = window.innerWidth;
    var max_y = window.innerHeight;

    var page_x, page_y;
    for (page_y = 0; page_y + tile_height < max_y; page_y += half_height) {
        for (page_x = 0; page_x + tile_width < max_x; page_x += tile_width) {
            add_tile(0, 0, page_x + (page_y % tile_height ? half_width : 0), page_y);
        }
    }

    document.body.addEventListener("mousemove", function (e) {
        var map_xy = page_to_map(e.pageX, e.pageY);
        debug("[" + map_xy[0] + "," + map_xy[1] + "]");
    }, false);
}
