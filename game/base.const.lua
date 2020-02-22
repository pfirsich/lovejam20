return {
    simDt = 1/60.0,
    resX = 640,
    resY = 360,

    dirtTileSize = 64,
    scrubHistoryLen = 4, -- in seconds
    scrubSampleNum = 8,
    mouseHistoryLen = 0.2, -- seconds

    gaugeWidth = 96,
    gaugeHeight = 16,
    gaugeOffset = {40, -5},

    cleanerColors = {
        cleanerA = {0.85, 0.42, 0.85, 1.0},
        cleanerB = {0.61, 0.82, 0.87, 1.0},
        cleanerC = {0.86, 0.86, 0.42, 1.0},
    }
}