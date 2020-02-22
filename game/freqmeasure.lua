local FreqMeasure = class("FreqMeasure")

function FreqMeasure:initialize(maxTimeDist, maxNumSamples)
    self.samples = {}
    self.maxTimeDist = maxTimeDist
    self.maxNumSamples = maxNumSamples
end

function FreqMeasure:truncate(currentTime)
    for i = #self.samples, 1, -1 do
        if self.samples[i] > currentTime - self.maxTimeDist then
            break
        end
        table.remove(self.samples, i)
    end
end

function FreqMeasure:event(currentTime)
    table.insert(self.samples, 1, currentTime)
end

function FreqMeasure:getSampleFreq()
    local avgFreq = 0
    local n = 0
    for i = 1, self.maxNumSamples - 1 do
        if #self.samples > i then
            local freq = 1.0 / (self.samples[i] - self.samples[i+1])
            avgFreq = avgFreq + freq
            n = n + 1
        end
    end
    if n == 0 then
        return 0
    end
    return avgFreq / n
end

function FreqMeasure:get(currentTime)
    local sampleFreq = self:getSampleFreq()
    local avgPeriod = 1.0 / sampleFreq
    if #self.samples == 0 or currentTime < self.samples[1] + avgPeriod then
        return sampleFreq
    end

    -- This is the algorithm I actually want to use, but if
    -- currentTime is too close to the last event, we will overestimate the frequency
    -- so in that case I will only use the frequency from the time distance between
    -- the samples (the return above)
    local avgFreq = 0
    local n = 0
    for i = 1, #self.samples do
        local freq = i * 1.0 / (currentTime - self.samples[i])
        avgFreq = avgFreq + freq
        n = n + 1
    end
    return avgFreq / n
end

return FreqMeasure