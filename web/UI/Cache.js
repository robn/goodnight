if (typeof UI == "undefined") UI = {};

UI.Cache = function () {
    this.graphic = {};
}

UI.Cache.prototype.addGraphic = function (name, url, width, height, centrex, centrey) {
    if (this.graphic[name])
        return;

    if (arguments.length == 2 && typeof arguments[1] == "object" && arguments[1].constructor == Array) {
        url = arguments[1][1];
        width = arguments[1][2];
        height = arguments[1][3];
        centrex = arguments[1][4];
        centrey = arguments[1][5];
    }

    this.graphic[name] = {
        url:     url,
        width:   width,
        height:  height,
        centrex: centrex,
        centrey: centrey
    };
}

UI.Cache.prototype.addGraphics = function (list) {
    var name;
    for (name in list) {
        var graphic = list[name];
        this.addGraphic(name, graphic[0], graphic[1], graphic[2], graphic[3], graphic[4]);
    }
}
