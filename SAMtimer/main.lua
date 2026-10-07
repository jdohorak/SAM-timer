-- SAM timer (ALOT) – flight timer and scoring widget for vintage (old-timer) RC contests
-- Install: SCRIPTS:/alot/main.lua + SCRIPTS:/alot/lang.lua (UI strings)
--
-- 4 rounds + 1 fly-off. Timing is started/stopped with a dedicated switch:
--   switch ON  -> timing starts in the current round
--   switch OFF -> timing stops, the time is recorded, the widget moves to the next round
-- Points = whole seconds, capped at the max time (default 600 s = 10 min).
-- A flight longer than the max time gets maximum points and a "MAX" marker.

local translations = assert(loadfile("lang.lua"))()

local function tr()
    return translations[system.getLocale()] or translations.en
end

local function name()
    return tr().name
end

---------------------------------------------------------------- helpers

local function fmtTime(t)
    if not t then return "--:--" end
    local s = math.floor(t)
    return string.format("%02d:%02d", s // 60, s % 60)
end

local function swState(sw)
    if not sw then return false end
    local ok, st = pcall(function() return sw:state() end)
    return ok and st == true
end

-- total rounds = regular rounds + (fly-off ? 1 : 0)
local function totalRounds(widget)
    return widget.rounds + (widget.flyoff and 1 or 0)
end

local function isFlyoff(widget, i)
    return widget.flyoff and i == widget.rounds + 1
end

local function maxFor(widget, i)
    return isFlyoff(widget, i) and widget.foMax or widget.maxTime
end

local function pointsFor(widget, i, t)
    if not t then return nil end
    return math.min(math.floor(t), maxFor(widget, i))
end

local function roundLabel(widget, i)
    if isFlyoff(widget, i) then return tr().fo end
    return i .. "."
end

-- Index of the dropped (lowest-scoring) regular round once all regular rounds are flown; otherwise nil.
-- On a tie the earlier round is dropped.
local function droppedRound(widget)
    if not widget.dropWorst or widget.rounds < 2 then return nil end
    local worst, worstPts
    for i = 1, widget.rounds do
        if widget.times[i] == nil or (widget.running and i == widget.current) then return nil end
        local p = pointsFor(widget, i, widget.times[i])
        if worstPts == nil or p < worstPts then worst, worstPts = i, p end
    end
    return worst
end

-- index of the first empty round; totalRounds + 1 if all are done
local function firstEmpty(widget, from)
    for i = from or 1, totalRounds(widget) do
        if widget.times[i] == nil then return i end
    end
    return totalRounds(widget) + 1
end

---------------------------------------------------------------- persistence
-- Recorded times are saved to a file per model, so they survive a power cycle.
-- Only a reset (menu or reset switch) clears them.

local DATA_DIR = "/scripts/alot/"

local function dataFile()
    local mn = (model and model.name and model.name()) or "model"
    mn = string.gsub(mn, "[^%w%-_]", "_")
    return DATA_DIR .. "res_" .. mn .. ".txt"
end

local function saveResults(widget)
    local f = io.open(dataFile(), "w")
    if not f then return end
    f:write("current=" .. widget.current .. "\n")
    for i, t in pairs(widget.times) do
        f:write(string.format("%d=%.2f\n", i, t))
    end
    f:close()
end

local function loadResults(widget)
    widget.times = {}
    widget.current = 1
    local f = io.open(dataFile(), "r")
    if not f then return end
    local txt = f:read(1024) or "" -- Ethos io only accepts a byte count or "*l", not "a"
    f:close()
    for k, v in string.gmatch(txt, "([%w]+)=([%d%.]+)") do
        if k == "current" then
            widget.current = math.floor(tonumber(v) or 1)
        else
            local i, t = tonumber(k), tonumber(v)
            if i and t then widget.times[math.floor(i)] = t end
        end
    end
end

local function resetAll(widget)
    widget.times = {}
    widget.running = false
    widget.elapsed = 0
    widget.current = 1
    widget.lastIdx = nil
    saveResults(widget)
    lcd.invalidate()
end

---------------------------------------------------------------- lifecycle

local function create()
    return {
        -- configuration
        startSw = nil, resetSw = nil,
        rounds = 4, flyoff = true,
        maxTime = 600, foMax = 3600,
        minCall = true, maxAlert = true, minTime = 3, dropWorst = true,
        motorTime = 90, motorWarn = 10, cMotor = lcd.RGB(255, 140, 0),
        cBg = lcd.RGB(20, 24, 32), cText = lcd.RGB(230, 230, 230),
        cRun = lcd.RGB(80, 220, 120), cOver = lcd.RGB(255, 80, 60), cSel = lcd.RGB(255, 200, 40),
        -- runtime state
        times = {}, current = 1,
        running = false, startClock = 0, elapsed = 0, lastSec = -1,
        lastStart = nil, lastReset = nil,
        rows = {},
    }
end

local function startTiming(widget)
    if widget.current > totalRounds(widget) then return end
    widget.running = true
    widget.startClock = os.clock()
    widget.elapsed = 0
    widget.lastSec = 0
    widget.alerted = false
    widget.motorAlerted = false
    widget.lastIdx = nil
    system.playTone(1200, 150, 0)
end

local function stopTiming(widget)
    widget.running = false
    local t = os.clock() - widget.startClock
    widget.elapsed = t
    system.playTone(800, 300, 0)
    if t < widget.minTime then return end -- accidental switch flip, not recorded
    widget.times[widget.current] = t
    widget.lastIdx = widget.current
    widget.current = firstEmpty(widget, widget.current + 1)
    if widget.current > totalRounds(widget) then
        widget.current = firstEmpty(widget, 1)
    end
    saveResults(widget)
end

local function wakeup(widget)
    if not widget.loaded then
        widget.loaded = true
        loadResults(widget)
        lcd.invalidate()
    end

    -- start/stop switch: react to edges only
    local st = swState(widget.startSw)
    if widget.lastStart == nil then widget.lastStart = st end -- don't start by itself at power-up
    if st ~= widget.lastStart then
        widget.lastStart = st
        if st and not widget.running then
            startTiming(widget)
        elseif not st and widget.running then
            stopTiming(widget)
        end
        lcd.invalidate()
    end

    -- reset switch (only while stopped)
    local rs = swState(widget.resetSw)
    if widget.lastReset == nil then widget.lastReset = rs end
    if rs ~= widget.lastReset then
        widget.lastReset = rs
        if rs and not widget.running then
            resetAll(widget)
            system.playHaptic(". .")
        end
    end

    if widget.running then
        local t = os.clock() - widget.startClock
        widget.elapsed = t
        local sec = math.floor(t)
        -- refresh every half second to flash the "MOTOR OFF!" message
        local half = math.floor(t * 2)
        if widget.motorTime > 0 and t >= widget.motorTime and t < widget.motorTime + 5 and half ~= widget.lastHalf then
            widget.lastHalf = half
            lcd.invalidate()
        end
        if sec ~= widget.lastSec then
            widget.lastSec = sec
            local mx = maxFor(widget, widget.current)
            -- motor run: pre-warning in the last seconds, separate alert when it ends
            local mt = widget.motorTime
            if mt > 0 and not widget.motorAlerted then
                if sec >= mt then
                    widget.motorAlerted = true
                    system.playHaptic("- -")
                    system.playTone(2000, 700, 0)
                elseif mt - sec <= widget.motorWarn then
                    system.playTone(1000, 80, 0)
                end
            end
            if widget.maxAlert and not widget.alerted and sec >= mx then
                widget.alerted = true
                system.playHaptic("- . -")
                system.playTone(1500, 600, 0)
            elseif widget.minCall and sec > 0 and sec % 60 == 0 and not (mt > 0 and sec >= mt - widget.motorWarn and sec <= mt) then
                if UNIT_MINUTE then
                    system.playNumber(sec // 60, UNIT_MINUTE, 0)
                else
                    system.playTone(1000, 100, 0)
                end
            end
            lcd.invalidate()
        end
    end
end

---------------------------------------------------------------- drawing

local function drawTable(widget, x, y, w, h)
    local t = tr()
    local n = totalRounds(widget)
    local rowH = math.floor(h / (n + 2))
    local cLabel, cTime, cPts, cMark = x + 6, x + w * 0.22, x + w * 0.70, x + w - 6

    lcd.font(FONT_S)
    lcd.color(widget.cText)
    lcd.drawText(cLabel, y, t.round, LEFT)
    lcd.drawText(cTime, y, "mm:ss", LEFT)
    lcd.drawText(cPts, y, t.points, RIGHT)
    lcd.drawLine(x, y + rowH - 2, x + w, y + rowH - 2)

    lcd.font(FONT_STD)
    local sum = 0
    local drop = droppedRound(widget)
    local cDim = lcd.RGB(120, 120, 120)
    widget.rows = {}
    for i = 1, n do
        local ry = y + i * rowH
        widget.rows[i] = { y = ry, h = rowH }
        local tm = widget.times[i]
        local live = widget.running and i == widget.current
        if live then tm = widget.elapsed end
        local pts = pointsFor(widget, i, tm)
        local over = tm and tm > maxFor(widget, i)

        if i == widget.current then
            lcd.color(widget.cSel)
            lcd.drawRectangle(x, ry - 1, w, rowH - 1)
        end
        if isFlyoff(widget, i) then
            lcd.color(widget.cText)
            lcd.drawLine(x, ry - 3, x + w, ry - 3)
        end

        local dropped = (i == drop)
        lcd.color(dropped and cDim or (live and widget.cRun or widget.cText))
        lcd.drawText(cLabel, ry + 2, roundLabel(widget, i), LEFT)
        -- a time over the max (maxed out) is shown in red
        lcd.color(dropped and cDim or (over and widget.cOver or (live and widget.cRun or widget.cText)))
        lcd.drawText(cTime, ry + 2, fmtTime(tm), LEFT)
        lcd.color(dropped and cDim or (over and widget.cOver or (live and widget.cRun or widget.cText)))
        lcd.drawText(cPts, ry + 2, pts and tostring(pts) or "-", RIGHT)
        if dropped then
            -- strike-through: this round does not count towards the total
            lcd.drawLine(cTime, ry + rowH / 2, cPts, ry + rowH / 2)
        end
        if over then
            lcd.font(FONT_S_BOLD)
            lcd.drawText(cMark, ry + 4, "MAX", RIGHT)
            lcd.font(FONT_STD)
        end
        if pts and not isFlyoff(widget, i) and not live and not dropped then sum = sum + pts end
    end

    local ty = y + (n + 1) * rowH
    lcd.color(widget.cText)
    lcd.drawLine(x, ty - 2, x + w, ty - 2)
    lcd.font(FONT_STD_BOLD or FONT_STD)
    lcd.drawText(cLabel, ty + 2, t.total, LEFT)
    lcd.drawText(cPts, ty + 2, tostring(sum), RIGHT)
end

local function drawTimer(widget, x, y, w, h)
    local t = tr()
    local n = totalRounds(widget)
    local cur = widget.current
    local done = cur > n

    -- current round title
    lcd.font(FONT_L_BOLD or FONT_L)
    lcd.color(widget.cSel)
    local title
    if done then
        title = t.done
    elseif isFlyoff(widget, cur) then
        title = t.flyoff
    else
        title = string.format("%s %d / %d", t.round, cur, widget.rounds)
    end
    lcd.drawText(x + w / 2, y, title, CENTERED)
    local _, th = lcd.getTextSize(title)

    -- motor run line: counts down while running, "MOTOR OFF!" when it ends
    if widget.motorTime > 0 then
        lcd.font(FONT_STD_BOLD or FONT_STD)
        local mtxt
        if widget.running then
            local rem = widget.motorTime - widget.elapsed
            if rem > 0 then
                mtxt = t.motor .. "  " .. fmtTime(math.ceil(rem))
                lcd.color(widget.cMotor)
            else
                mtxt = t.motorOff
                -- flashes for the first 5 seconds after the motor run ends
                local blink = (-rem) < 5 and (math.floor(widget.elapsed * 2) % 2 == 0)
                lcd.color(blink and widget.cText or widget.cMotor)
            end
        else
            mtxt = t.motorIdle .. "  " .. widget.motorTime .. " s"
            lcd.color(widget.cText)
        end
        lcd.drawText(x + w / 2, y + th + 2, mtxt, CENTERED)
        local _, mh = lcd.getTextSize(mtxt)
        th = th + mh + 2
    end

    -- big timer: live time while running, the just-recorded flight after stopping
    local idx = widget.running and cur or (widget.lastIdx or cur)
    local mx = maxFor(widget, math.min(idx, n))
    local tm
    if widget.running then tm = widget.elapsed else tm = widget.times[idx] end
    local over = tm and tm > mx
    lcd.font(FONT_XXL)
    lcd.color(over and widget.cOver or (widget.running and widget.cRun or widget.cText))
    local big = fmtTime(tm or 0)
    local _, bh = lcd.getTextSize(big)
    local by = y + th + (h - th - bh) * 0.25
    lcd.drawText(x + w / 2, by, big, CENTERED)

    -- points + max marker
    lcd.font(FONT_L)
    local pts = tm and math.min(math.floor(tm), mx) or 0
    local ptxt = pts .. " " .. t.points .. (over and "  MAX" or "")
    local py = by + bh + 2
    lcd.drawText(x + w / 2, py, ptxt, CENTERED)
    local _, ph = lcd.getTextSize(ptxt)

    -- progress bar relative to the max time
    local barY = py + ph + 6
    local barH = math.max(8, math.floor(h * 0.06))
    if barY + barH + 4 < y + h then
        local bx, bw = x + w * 0.08, w * 0.84
        lcd.color(widget.cText)
        lcd.drawRectangle(bx, barY, bw, barH)
        local frac = math.min((tm or 0) / mx, 1)
        lcd.color(over and widget.cOver or widget.cRun)
        if frac > 0 then lcd.drawFilledRectangle(bx + 1, barY + 1, (bw - 2) * frac, barH - 2) end
        -- motor run section in its own color + marker line
        local mt = widget.motorTime
        if mt > 0 and mt < mx then
            local mfrac = mt / mx
            local mf = math.min(frac, mfrac)
            lcd.color(widget.cMotor)
            if mf > 0 and not over then lcd.drawFilledRectangle(bx + 1, barY + 1, (bw - 2) * mf, barH - 2) end
            local mxp = bx + 1 + (bw - 2) * mfrac
            lcd.drawLine(mxp, barY - 4, mxp, barY + barH + 3)
        end
        -- status
        lcd.font(FONT_S)
        lcd.color(widget.running and widget.cRun or widget.cText)
        local stTxt = widget.running and t.running or t.stopped
        if not widget.running and widget.lastIdx then
            stTxt = stTxt .. "   [" .. roundLabel(widget, widget.lastIdx) .. "]"
        end
        lcd.drawText(x + w / 2, barY + barH + 4, stTxt .. "   max " .. fmtTime(mx), CENTERED)
    end
end

local function paint(widget)
    local w, h = lcd.getWindowSize()
    lcd.color(widget.cBg)
    lcd.drawFilledRectangle(0, 0, w, h)

    local m = 6
    if not widget.startSw then
        lcd.font(FONT_STD)
        lcd.color(widget.cOver)
        lcd.drawText(w / 2, m, tr().noSwitch, CENTERED)
    end

    if w > h * 1.3 then
        -- landscape: timer on the left, table on the right
        local lw = math.floor(w * 0.52)
        drawTimer(widget, m, m + (widget.startSw and 0 or 24), lw - 2 * m, h - 2 * m)
        lcd.color(widget.cText)
        lcd.drawLine(lw, m, lw, h - m)
        drawTable(widget, lw + m, m, w - lw - 2 * m, h - 2 * m)
        widget.tableX = lw
    else
        -- portrait / narrow: timer on top, table below
        local th = math.floor(h * 0.45)
        drawTimer(widget, m, m + (widget.startSw and 0 or 24), w - 2 * m, th - m)
        drawTable(widget, m, th + m, w - 2 * m, h - th - 2 * m)
        widget.tableX = 0
    end
end

---------------------------------------------------------------- interaction

-- tap a row to select a round (e.g. to re-fly it), only while stopped
local function event(widget, category, value, x, y)
    if category == EVT_TOUCH and value == TOUCH_END and not widget.running then
        if x and x >= (widget.tableX or 0) then
            for i, r in pairs(widget.rows) do
                if y >= r.y and y < r.y + r.h then
                    widget.current = i
                    widget.lastIdx = nil
                    saveResults(widget)
                    lcd.invalidate()
                    return true
                end
            end
        end
    end
    return false
end

local function menu(widget)
    local t = tr()
    if widget.running then return {} end
    return {
        { t.mReset, function() resetAll(widget) end },
        { t.mPrev, function()
            if widget.current > 1 then widget.current = widget.current - 1 end
            widget.lastIdx = nil
            saveResults(widget)
            lcd.invalidate()
        end },
        { t.mNext, function()
            if widget.current < totalRounds(widget) then widget.current = widget.current + 1 end
            widget.lastIdx = nil
            saveResults(widget)
            lcd.invalidate()
        end },
    }
end

---------------------------------------------------------------- configuration

local function configure(widget)
    local t = tr()
    local line

    line = form.addLine(t.cfgSwitch)
    form.addSwitchField(line, nil, function() return widget.startSw end, function(v) widget.startSw = v; widget.lastStart = nil end)

    line = form.addLine(t.cfgReset)
    form.addSwitchField(line, nil, function() return widget.resetSw end, function(v) widget.resetSw = v; widget.lastReset = nil end)

    line = form.addLine(t.cfgRounds)
    form.addNumberField(line, nil, 1, 10, function() return widget.rounds end, function(v) widget.rounds = v end)

    line = form.addLine(t.cfgFlyoff)
    form.addBooleanField(line, nil, function() return widget.flyoff end, function(v) widget.flyoff = v end)

    line = form.addLine(t.cfgMax)
    local f = form.addNumberField(line, nil, 10, 3600, function() return widget.maxTime end, function(v) widget.maxTime = v end)
    f:suffix("s")
    f:step(10)

    line = form.addLine(t.cfgFoMax)
    f = form.addNumberField(line, nil, 10, 3600, function() return widget.foMax end, function(v) widget.foMax = v end)
    f:suffix("s")
    f:step(10)

    line = form.addLine(t.cfgMotor)
    f = form.addNumberField(line, nil, 0, 600, function() return widget.motorTime end, function(v) widget.motorTime = v end)
    f:suffix("s")

    line = form.addLine(t.cfgMotorWarn)
    f = form.addNumberField(line, nil, 0, 30, function() return widget.motorWarn end, function(v) widget.motorWarn = v end)
    f:suffix("s")

    line = form.addLine(t.cfgDrop)
    form.addBooleanField(line, nil, function() return widget.dropWorst end, function(v) widget.dropWorst = v end)

    line = form.addLine(t.cfgMinTime)
    f = form.addNumberField(line, nil, 0, 60, function() return widget.minTime end, function(v) widget.minTime = v end)
    f:suffix("s")

    line = form.addLine(t.cfgMinCall)
    form.addBooleanField(line, nil, function() return widget.minCall end, function(v) widget.minCall = v end)

    line = form.addLine(t.cfgMaxAlert)
    form.addBooleanField(line, nil, function() return widget.maxAlert end, function(v) widget.maxAlert = v end)

    local panel = form.addExpansionPanel(t.cfgColors)
    local colors = { { t.cfgBg, "cBg" }, { t.cfgText, "cText" }, { t.cfgRun, "cRun" }, { t.cfgOver, "cOver" }, { t.cfgSel, "cSel" }, { t.cfgMotorCol, "cMotor" } }
    for _, c in ipairs(colors) do
        local key = c[2]
        line = panel:addLine(c[1])
        form.addColorField(line, nil, function() return widget[key] end, function(v) widget[key] = v end)
    end
end

-- Keep the key order identical in read and write; add new keys at the end only!
local function read(widget)
    widget.startSw = storage.read("startSw")
    widget.resetSw = storage.read("resetSw")
    widget.rounds = storage.read("rounds") or 4
    local fo = storage.read("flyoff"); if fo ~= nil then widget.flyoff = fo end
    widget.maxTime = storage.read("maxTime") or 600
    widget.foMax = storage.read("foMax") or 3600
    widget.minTime = storage.read("minTime") or 3
    local mc = storage.read("minCall"); if mc ~= nil then widget.minCall = mc end
    local ma = storage.read("maxAlert"); if ma ~= nil then widget.maxAlert = ma end
    widget.cBg = storage.read("cBg") or widget.cBg
    widget.cText = storage.read("cText") or widget.cText
    widget.cRun = storage.read("cRun") or widget.cRun
    widget.cOver = storage.read("cOver") or widget.cOver
    widget.cSel = storage.read("cSel") or widget.cSel
    local dw = storage.read("dropWorst"); if dw ~= nil then widget.dropWorst = dw end
    widget.motorTime = storage.read("motorTime") or 90
    widget.motorWarn = storage.read("motorWarn") or 10
    widget.cMotor = storage.read("cMotor") or widget.cMotor
    widget.lastStart, widget.lastReset = nil, nil
end

local function write(widget)
    storage.write("startSw", widget.startSw)
    storage.write("resetSw", widget.resetSw)
    storage.write("rounds", widget.rounds)
    storage.write("flyoff", widget.flyoff)
    storage.write("maxTime", widget.maxTime)
    storage.write("foMax", widget.foMax)
    storage.write("minTime", widget.minTime)
    storage.write("minCall", widget.minCall)
    storage.write("maxAlert", widget.maxAlert)
    storage.write("cBg", widget.cBg)
    storage.write("cText", widget.cText)
    storage.write("cRun", widget.cRun)
    storage.write("cOver", widget.cOver)
    storage.write("cSel", widget.cSel)
    storage.write("dropWorst", widget.dropWorst)
    storage.write("motorTime", widget.motorTime)
    storage.write("motorWarn", widget.motorWarn)
    storage.write("cMotor", widget.cMotor)
end

local function init()
    system.registerWidget({
        key = "samt", name = name, create = create, wakeup = wakeup, paint = paint,
        configure = configure, read = read, write = write, event = event, menu = menu,
        title = false,
    })
end

return { init = init }
