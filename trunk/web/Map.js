var Map = function () {
    this.width = Map.width;
    this.height = Map.height;
    this.player = { x: Map.player.x; y: Map.player.y };

    this.map = new Array(this.width);
    
    var x, y;

    for (x = 0; x < this.width; x++) {
        this.map[x] = new Array(this.height);
        for (y = 0; y < this.height; y++) {
            this.map[x][y] = {
                terrain: "mountain"
            };
        }
    }

    this.map[this.player.x][this.player.y] = 1;
}

Map.width = 50;
Map.height = 50;
Map.player = { x: 10, y: 10 };

Map.prototype.get_at = function (x, y) {
    if (x < 0 || y < 0 || x >= this.width || y >= this.height)
        return -1;

    return this.map[x][y];
}

Map.prototype.move = function (dir) {
    var cx = this.player.x, cy = this.player.y;
    var moved = 0;

    switch (dir) {
        case 0:
            if (this.player.y > 0) this.player.y--;
            moved = 1;
            break;
        case 1:
            if (this.player.x <= 50) this.player.x++;
            moved = 1;
            break;
        case 2:
            if (this.player.y <= 50) this.player.y++;
            moved = 1;
            break;
        case 3:
            if (this.player.x > 0) this.player.x--;
            moved = 1;
            break;
    }

    if (moved)
        signal(this, "moved", { from: [ cx, cy ], to: [ this.player.x, this.player.y ] });
}

Map.prototype.tellme = function (fn) {
    connect(this, "moved", fn);
}
