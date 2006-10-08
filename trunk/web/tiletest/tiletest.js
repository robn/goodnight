var width = 5;
var height = 7;

var tile_width = 100;
var tile_height = 46;

var edge_gradient = 0.46;

var origin_x = (height-1) * (tile_width/2);
var origin_y = 0;

var half_width = tile_width/2;
var half_height = tile_height/2;

function debug (text) {
    var p = document.getElementById("debug");

    while (p.hasChildNodes()) {
        p.removeChild(p.lastChild);
    }

    if (typeof text == "string") {
        p.appendChild(document.createTextNode(text));
    }

    else if (typeof text == "object" && text.constructor == Array) {
        for (i in text) {
            p.appendChild(document.createTextNode(text[i]));
            p.appendChild(document.createElement("br"));
        }
    }
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

    var map_y = Math.floor((tile_y * half_width - page_x * half_height) / (2 * half_width * half_height));
    var map_x = Math.floor((tile_x + half_width * map_y) / half_width);

    if(!select) {
        select = document.createElement("img");
        select.setAttribute("class", "tile");
        select.setAttribute("src", "select.png");
        select.style.position = "absolute";
        document.body.appendChild(select);
    }
    select.style.top = tile_y;
    select.style.left = tile_x;

    debug([
        "[px,py]   = [" + page_x + "," + page_y + "]",
        "[t1x,t1y] = [" + tile1_x + "," + tile1_y + "]",
        "[t2x,t2y] = [" + tile2_x + "," + tile2_y + "]",
        "in t1     = " + in_tile1,
        "[mx,my]   = [" + map_x + "," + map_y + "]"
    ]);

    return [ map_x, map_y ];
}

function add_tile (map_x, map_y, page_x, page_y) {
    var img = document.createElement("img");
    img.setAttribute("class", "tile");
    img.setAttribute("src", "blank.png");

    img.style.left = page_x;
    img.style.top = page_y;

    document.body.appendChild(img);
}

function setup_tiles () {
    var x, y;
    
    for (x = 0; x < width; x++) {
        for (y = 0; y < height; y++) {
            var page_x = origin_x + ((x-y) * half_width);
            var page_y = origin_y + ((x+y) * half_height);

            add_tile(x, y, page_x, page_y);
        }
    }

    document.body.addEventListener("mousemove", function (e) {
        var map_xy = page_to_map(e.pageX, e.pageY);
    }, false);
}
