var width = 5;
var height = 7;

var tile_width = 100;
var tile_height = 46;

var edge_gradient = 0.46;

var origin_x = (height-1) * (tile_width/2);
var origin_y = 0;

var half_width = tile_width/2;
var half_height = tile_height/2;

function set_status (text) {
    var p = document.getElementById("status");

    var text = document.createTextNode(text);

    while (p.hasChildNodes()) {
        p.removeChild(p.lastChild);
    }

    p.appendChild(text);
}

function page_to_map (page_x, page_y) {
    page_x -= origin_x;
    page_y -= origin_y;

    var tile_x = Math.floor (page_x / tile_width) * tile_width;
    var tile_y = Math.floor (page_y / half_height) * half_height;

    var delta_x = page_x - tile_x;
    var delta_y = page_y - tile_y;

    var outside1 = (-edge_gradient * delta_x - (-edge_gradient * half_width) - delta_y) > 0;
    var outside2 = (edge_gradient * delta_x - (edge_gradient * width) - delta_y + half_height) > 0;
    var outside3 = (-edge_gradient * delta_x - (-edge_gradient * half_width) - delta_y + tile_height) < 0;
    var outside4 = (edge_gradient * delta_x - delta_y + half_height) < 0;

    return [ "" + delta_x + "," + delta_y + ":" + outside1 + "," + outside2, "" + outside3 + "," + outside4 ];

    

    return [ delta_x, delta_y ];

    var map_y = (page_y * half_width - page_x * half_height) / (2 * half_width * half_height);
    var map_x = (page_x + half_width * map_y) / half_width;

    //var map_x = Math.floor ((page_x - origin_x) / half_width);
    //var map_y = Math.floor ((page_y - origin_y) / half_height);

    return [ Math.floor(map_x), Math.floor(map_y) ];
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
        set_status("[" + map_xy[0] + "," + map_xy[1] + "]");
    }, false);
}
