if (typeof Iso == "undefined") Iso = {};

Iso.Grid = function (cache, element, map, left, top, width, height) {
    this.cache = cache;
    this.element = element;

    this.map = map;

    this.reset(left, top, width, height);
}

Iso.Grid.prototype.reset = function (left, top, width, height) {
    // display area
    this.left = left;
    this.top = top;
    this.height = height;
    this.width = width;

    // tile dimensions
    this.tile_width  = this.cache.graphic[":tile"].width;
    this.tile_height = this.cache.graphic[":tile"].height;

    // half width, which is our "stepping" when we display the grid
    this.half_width  = this.tile_width / 2;
    this.half_height = this.tile_height / 2;

    // number of tiles in the grid
    this.grid_width = Math.floor(this.width / this.tile_width);
    this.grid_height = Math.floor(this.height / this.half_height);

    // central tile
    this.centre_x = Math.floor(this.grid_width / 2);
    this.centre_y = Math.floor(this.grid_height / 2);

    this.grid = new Array(this.grid_width);
    var x, y;
    for (x = 0; x < this.grid_width; x++) {
        this.grid[x] = new Array(this.grid_height);
        for (y = 0; y < this.grid_height; y++) {
            this.grid[x][y] = {
                px: x * this.tile_width + (y & 1 ? this.half_width : 0),
                py: y * this.half_height
            };
        }
    }

    this.show();
}

Iso.Grid.prototype.show = function () {
    while (this.element.hasChildNodes())
        this.element.removeChild(this.element.firstChild);
        
    var x, y;
    for (y = 0; y < this.grid_height; y++) {
        for (x = 0; x < this.grid_width; x++) {
            var img = document.createElement("img");
            img.setAttribute("class", "tile");

            img.setAttribute("width", this.tile_width);
            img.setAttribute("height", this.tile_height);

            img.setAttribute("src", this.cache.graphic[":tile"].url);

            img.style.position = "absolute";
            img.style.left = this.grid[x][y].px;
            img.style.top = this.grid[x][y].py;

            this.element.appendChild(img);
        }
    }
}

Iso.Grid.prototype.hover = function (px, py) {
    /*
     * we consider the map as being two overlaid grids of tiles, one starting
     * at [0,0] and one starting at [half_width,half_height]
     *
     * in the general case, there are always two tiles under the mouse, one
     * from each grid. we need to find the top-left corners of their bounding
     * boxes
     */
    var t1x = Math.floor(px / this.tile_width) * this.tile_width;
    var t1y = Math.floor(py / this.tile_height) * this.tile_height;

    var t2x = Math.floor((px+this.half_width) / this.tile_width) * this.tile_width - this.half_width;
    var t2y = Math.floor((py+this.half_height) / this.tile_height) * this.tile_height - this.half_height;

    /*
     * to distinguish between the tiles, we need to find the edge that goes
     * between the two tiles and then figure out which side of it the mouse is
     * currently on
     *
     * we cheat slightly. the edge goes between the two tile centres, so we
     * get the centres but swap the y-coords to get the edge endpoints.
     */
    var e1x = t1x + this.half_width; var e1y = t2y + this.half_height;
    var e2x = t2x + this.half_width; var e2y = t1y + this.half_height;

    /* compute the line */
    var m = (e2y-e1y) / (e2x-e1x);
    var c = e1y - m * e1x;

    /* figure out if we're above or below the line */
    var in_t1 = (py > m * px+c);
    /* but if tile1 is above tile2, then swap it over */
    if (t1y < t2y) in_t1 = !in_t1;

    /* our tile */
    var tx = in_t1 ? t1x : t2x;
    var ty = in_t1 ? t1y : t2y;

    /* grid position */
    var gc = this.tile_to_grid(tx, ty);
    var mc = this.grid_to_map(gc);

    debug([
        "tile: [" + tx + "," + ty + "]",
        "grid: [" + gc.x + "," + gc.y + "]",
        " map: [" + mc.x + "," + mc.y + "]"
    ]);

    if (gc.x < 0 || gc.y < 0 || gc.x >= this.grid_width || gc.y >= this.grid_height) {
        debug("out of bounds");
        if(this.hover_img) {
            this.element.removeChild(this.hover_img);
            delete this.hover_img;
        }
        return;
    }

    if(!this.hover_img) {
        this.hover_img = document.createElement("img");
        this.hover_img.setAttribute("class", "tile");
        this.hover_img.setAttribute("src", this.cache.graphic[":hover"].url);
        this.hover_img.style.position = "absolute";
        this.element.appendChild(this.hover_img);
    }
    this.hover_img.style.top = ty;
    this.hover_img.style.left = tx;
}

/* tile (pixel) position to grid coords */
Iso.Grid.prototype.tile_to_grid = function (tx, ty) {
    if (typeof tx == "object") {
        ty = tx.y;
        tx = tx.x;
    }

    var gy = ty / this.half_height;
    var gx = (tx - (gy & 1 ? this.half_width : 0)) / this.tile_width;

    return { x: gx, y: gy };
}

/* grid coords to map coords (ie rotate + offset) */
Iso.Grid.prototype.grid_to_map = function (gx, gy) {
    if (typeof gx == "object") {
        gy = gx.y;
        gx = gx.x;
    }


/*
OFF = (gy & 1 ? HW : 0)


ty = gy * HH

(tx - (gy & 1 ? HW : 0)) = gx * TW
tx = gx * TW + OFF



my = (ty * HW - tx * HH) / (2 * HW * HH)
my = (gy * HH * HW - (gx * TW + OFF) * HH) / (2 * HW * HH)
my = (gy * HH * HW - gx * TW * HH - OFF * HH) / (2 * HW * HH)
my = (HH * (gy * HW - gx * TW - OFF)) / (2 * HW * HH)
my = (gy * HW - gx * TW - OFF) / (2 * HW)

mx = (tx + HW * my) / HW
mx = (gx * TW + OFF + HW * ((gy * HW - gx * TW - OFF) / (2 * HW))) / HW
mx = (gx * TW + OFF + (gy * HW - gx * TW - OFF) / 2) / HW
mx = (gx * 2 * HW + OFF + (gy * HW - gx * TW - OFF) / 2) / HW
mx = ((4 * gx * HW + 2 * OFF + gy * HW - gx * TW - OFF) / 2) / HW
mx = (4 * gx * HW + gy * HW - gx * TW + OFF) / (2 * HW)
*/

    var offset = (gy & 1 ? this.half_width : 0);

    var mx = (4 * gx * this.half_width + gy * this.half_width - gx * this.tile_width + offset) / (2 * this.half_width);
    var my = (gy * this.half_width - gx * this.tile_width - offset) / (2 * this.half_width);

/*
    var ty = gy * this.half_height;
    var tx = gx * this.tile_width + (gy & 1 ? this.half_width : 0)


    var my = Math.floor((ty * this.half_width - tx * this.half_height) / (2 * this.half_width * this.half_height));
    var mx = Math.floor((tx + this.half_width * my) / this.half_width);
*/

    return { x: mx, y: my };
}

/* map coords to grid coords */
Iso.Grid.prototype.map_to_grid = function (mx, my) {
}
