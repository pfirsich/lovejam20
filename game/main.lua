require("globals") -- schmutz!
require("libs.strict")
require("libs.slam")

local scenes = require("scenes")
local codex = require("codex")
local blobtiles = require("blobtiles")

local assetList = require("assetlist")

function love.load(arg)
    const.reload()
    assets.load(assetList)
    blobtiles.init(const.dirtTileSize)
    codex.init()

    scenes.require()
    for name, scene in pairs(scenes) do
        scene.realTime = 0
        scene.simTime = 0
        scene.frameCounter = 0
        util.callNonNil(scene.load)
    end
    scenes.enter(scenes.questview)
    scenes.enter(scenes.storysequence, {
        dialog = {
            {"The year is 2264 and I've made it.", 2.5, 0.5},
            {"I am the head janitor at the intergalatic space station Garzikulon Prime.", 3.8, 0.7},
            {"Only three years after basic training at the academy I reached the very top.", 4.0, 0.6},
            {"But not without a cost.", 1.5, 0.4},
            {"Two months ago my master Rüdiger-sensei died in a mission cleaning up a Glorzag-poop spill.", 4.0, 0.8},
            {"It was a routine job and Rüdiger-sensei was a pro.", 3.0, 0.5},
            {"Something is off about this and I will figure out what it is.", 3.5, 0.5},
            {"For now though, I simply have have to do my job.", 2.5},
        },
        audio = assets.voiceIntro,
        buttonText = "Do your job",
    }, scenes.questview)
end

function love.keypressed(key)
    local ctrl = lk.isDown("lctrl") or lk.isDown("rctrl")
    if ctrl and key == "r" then
        const.reload()
        print("Constants reloaded.")
    end
end

function love.run()
	love.load(love.arg.parseGameArguments(arg), arg)

	-- We don't want the first frame's dt to include time taken by love.load.
	lt.step()

	local dt = 0

	return function()
        local scene = scenes.current
        while scene.simTime <= scene.realTime do
            scene.simTime = scene.simTime + const.simDt
            scene.frameCounter = scene.frameCounter + 1

            if love.event then
                love.event.pump()
                for name, a,b,c,d,e,f in love.event.poll() do
                    if name == "quit" then
                        if not love.quit or not love.quit() then
                            util.callNonNil(scene.exit)
                            return a or 0
                        end
                    end

                    love.handlers[name](a, b, c, d, e, f)
                    util.callNonNil(scene[name], a, b, c, d, e, f)
                end
            end

            util.callNonNil(scene.tick)
        end

		dt = lt.step()

        scene.realTime = scene.realTime + dt

		if lg and lg.isActive() then
			lg.origin()
			lg.clear(lg.getBackgroundColor())
			scene.draw(dt)
			lg.present()
		end

		lt.sleep(0.001)
	end
end