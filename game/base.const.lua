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
        glab = {0.85, 0.42, 0.85, 1.0},
        shlooze = {0.86, 0.86, 0.42, 1.0},
        blinge = {0.31, 0.51, 0.82, 1.0},
    },

    cleanerRadius = {
        glab = 90,
        shlooze = 60,
        blinge = 120,
    },

    cleanerLifetime = {
        glab = 4.0,
        shlooze = 3.0,
        blinge = 2.0,
    },

    codexPaddingTop = 30,
    codexMoveSpeed = 1000.0,
}