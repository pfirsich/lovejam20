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
            {text = "The year is 2264 and you've made it."},
            {text = "You are the head janitor at the intergalatic space station L4P7."},
            {text = "Only three years after basic training at the academy you reached the very top."},
            {text = "But not without a cost."},
            {text = "Two months ago your master Rüdiger-sensei died in a mission cleaning up a Glorzag-poop spill."},
            {text = "It was a routine job and Rüdiger-sensei was a pro."},
            {text = "Something is off about this and you will figure out what it is."},
            {text = "For now though, you have simply have to do your job."},
        },
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