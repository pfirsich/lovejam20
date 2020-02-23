local particles = {}

particles.sets = {}

function particles.spawn(set, image, x, y, lifetime, rotation, maxScale)
    local angle = 0
    if rotation then
        angle = lm.random(0, 3) * math.pi / 2.0
    end
    local scale = 1
    if maxScale then
        scale = lm.random(1, maxScale)
    end

    local particle = {
        image = image,
        x = x, y = y,
        angle = angle,
        color = {1, 1, 1, 1},
        scale = scale,
        lifetime = lifetime,
    }

    if particles.sets[set] == nil then
        particles.sets[set] = {}
    end
    table.insert(particles.sets[set], particle)

    return particle
end

function particles.update(set, dt, updateFunc)
    if particles.sets[set] == nil then
        return
    end

    local deadIndices = {}
    for i, particle in ipairs(particles.sets[set]) do
        particle.lifetime = math.max(0, particle.lifetime - dt)
        if particle.lifetime <= 0 then
            table.insert(deadIndices, i)
        else
            updateFunc(particle)
        end
    end

    for _, index in ipairs(deadIndices) do
        table.remove(particles.sets[set], index)
    end
end

function particles.draw(set)
    if particles.sets[set] == nil then
        return
    end

    for _, particle in ipairs(particles.sets[set]) do
        lg.setColor(particle.color)
        local img = particle.image
        lg.draw(img, particle.x, particle.y,
            particle.angle, particle.scale, particle.scale,
            img:getWidth()/2, img:getHeight()/2)
    end
end

return particles