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
        cleanerB = {0.86, 0.86, 0.42, 1.0},
        cleanerC = {0.31, 0.51, 0.82, 1.0},
    },

    cleanerRadius = {
        cleanerA = 90,
        cleanerB = 60,
        cleanerC = 120,
    },

    cleanerLifetime = {
        cleanerA = 4.0,
        cleanerB = 3.0,
        cleanerC = 2.0,
    },

    codexPaddingTop = 30,
    codexMoveSpeed = 1000.0,
}