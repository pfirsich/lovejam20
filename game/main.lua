require("globals") -- schmutz!
require("libs.strict")
require("libs.slam")

local scenes = require("scenes")

assetList = {
    assets.image("handSponge"),
    assets.image("handCloth"),

    assets.image("gaugeEmpty", "gauge2Empty.png"),
    assets.image("gaugeSlow", "gauge2Slow.png"),
    assets.image("gaugeMed", "gauge2Med.png"),
    assets.image("gaugeFast", "gauge2Fast.png"),

    assets.image("goo"),
    assets.image("specks"),
    assets.image("transitions"),

    assets.image("bubble1"),
    assets.image("bubble2"),

    assets.image("squareBubble1"),
    assets.image("squareBubble2"),

    assets.image("splat1"),
    assets.image("splat2"),

    assets.image("sparkle1"),
    assets.image("sparkle2"),

    assets.sound("scrub"),
    assets.sound("spray"),
    assets.sound("sparkle"),
}

function love.load(arg)
    const.reload()
    assets.load(assetList)

    scenes.require()
    for name, scene in pairs(scenes) do
        scene.realTime = 0
        scene.simTime = 0
        scene.frameCounter = 0
        util.callNonNil(scene.load)
    end
    scenes.enter(scenes.clean)
end

function love.update(dt)
end

function love.draw(dt)
    scenes.current.draw(dt)
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

            love.update(const.simDt)
            util.callNonNil(scene.tick)
        end

		dt = lt.step()

        scene.realTime = scene.realTime + dt

		if lg and lg.isActive() then
			lg.origin()
			lg.clear(lg.getBackgroundColor())
			love.draw()
			lg.present()
		end

		lt.sleep(0.001)
	end
end