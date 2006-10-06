var width = 5;
var height = 7;

var tile_width = 100;
var tile_height = 46;

function add_tile (map_x, map_y, plot_x, plot_y) {
    var img = document.createElement("img");
    img.setAttribute("class", "tile");
    img.setAttribute("src", "green.png");

    img.style.left = plot_x;
    img.style.top = plot_y;

    img.addEventListener("mouseover", function () {
        window.status = "[" + map_x + "," + map_y + "]";
    }, false);

    document.body.appendChild(img);
}

function setup_tiles () {
    var origin_x = (height-1) * (tile_width/2);
    var origin_y = 0;

    var half_width = tile_width/2;
    var half_height = tile_height/2;

    var x, y;
    
    for (x = 0; x < width; x++) {
        for (y = 0; y < height; y++) {
            var plot_x = origin_x + x * half_width  - y * half_width;
            var plot_y = origin_y + x * half_height + y * half_height;

            add_tile(x, y, plot_x, plot_y);
        }
    }
}
