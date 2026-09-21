local ui, uiu, uie = require("ui").quick()
local utf8 = require("utf8")
local lang = require("lang")
local downloadqueue = require("downloadqueue")

-- Progress bar element.
uie.add("downloadProgressBar", {
    cacheable = false,

    width = 0,
    height = 8,

    style = {
        bg = { 1, 1, 1, 0.08 },
        border = { 1, 1, 1, 0.18, 1 },
        color = { 0.35, 0.63, 0.95, 1 },
        radius = 4,
    },

    -- false (indeterminate) or a number between 0 and 1.
    progress = false,

    time = 0,

    update = function(self, dt)
        if not self.progress then
            self.time = (self.time + dt * 1.5) % 1
            self:repaint()
        end
    end,

    draw = function(self)
        local x = self.screenX
        local y = self.screenY
        local w = self.width
        local h = self.height
        local radius = self.style.radius

        local bg = self.style.bg
        if bg and bg[4] and bg[4] ~= 0 and uiu.setColor(bg) then
            love.graphics.rectangle("fill", x, y, w, h, radius, radius)
        end

        if not uiu.setColor(self.style.color) then
            return
        end

        local prog = self.progress
        if prog then
            prog = math.max(0, math.min(1, prog))
            local fillWidth = math.floor(w * prog)
            if fillWidth > 0 then
                love.graphics.rectangle("fill", x, y, fillWidth, h, radius, radius)
            end
        else
            local t = self.time
            local sweep = math.max(math.floor(w * 0.33), 16)
            if sweep > w then
                sweep = w
            end
            -- Slide the highlight fully inside the track: the old formula
            -- (which started at -sweep, one third of the bar width to the
            -- left) let the blue band poke out of the bar and spill over the
            -- surrounding rows / panel edge while a step like
            -- "Parsing everest.yaml" was animating.
            local offs = math.floor((w - sweep) * t)
            love.graphics.rectangle("fill", x + offs, y, sweep, h, radius, radius)
        end

        local border = self.style.border
        if border and border[4] and border[4] ~= 0 and border[5] ~= 0 and uiu.setColor(border) then
            love.graphics.setLineWidth(border[5] or 1)
            love.graphics.rectangle("line", x, y, w, h, radius, radius)
        end
    end
})


local downloadqueueui = {}

local initialized = false
local panel
local listInner
local clearButton
local indicatorEl

local rowMap = {}
local prevState = {}

local dirty = false
local lastTick = 0

-- Width of the download panel's content area. It is a bit wider than strictly
-- necessary so long words (French "Téléchargement..." in the per-task state
-- label) still fit inside the panel.
local PANEL_WIDTH = 420

-- When the user closes the panel (×), it stays hidden for the current
-- download; downloading a NEW mod brings it back on top automatically.
local userClosed = false

-- Total task count at the last change, used to detect that a new mod was
-- enqueued (a new download) so the panel pops back up immediately.
local lastCount = 0


local stateKeys = {
    queued = "download_queued",
    downloading = "download_downloading",
    paused = "download_paused",
    done = "download_done",
    failed = "download_failed_state",
    canceled = "download_canceled",
}


local function cap(text, max)
    text = tostring(text or "")
    local len = utf8.len(text)
    if not len then
        len = #text
    end
    if len <= max then
        return text
    end
    local byte = max
    local ok, offset = utf8.offset(text, max + 1)
    if ok and type(offset) == "number" then
        byte = offset - 1
    end
    return text:sub(1, byte) .. "…"
end


-- Trims text to fit within maxWidth pixels using the label's font, appending an
-- ellipsis when trimmed. Used for the mod name so that the state label next to
-- it never gets pushed out of the panel, no matter the language.
local function capToWidth(text, font, maxWidth)
    text = tostring(text or "")
    if not font or maxWidth <= 0 then
        return ""
    end
    if font:getWidth(text) <= maxWidth then
        return text
    end

    local ell = "…"
    local budget = maxWidth - font:getWidth(ell)
    if budget <= 0 then
        return ell
    end

    local len = utf8.len(text)
    if not len then
        len = #text
    end

    -- Names are short (a few dozen codepoints at most), so trimming one
    -- codepoint at a time is plenty fast.
    for n = len - 1, 1, -1 do
        local byte = n
        local ok, offset = utf8.offset(text, n + 1)
        if ok and type(offset) == "number" then
            byte = offset - 1
        end
        if font:getWidth(text:sub(1, byte)) <= budget then
            return text:sub(1, byte) .. ell
        end
    end
    return ell
end


local function showToast(title, body)
    local notify = require("notify")
    if notify and notify.root then
        notify.show({ title = title, body = body })
    end
end


local function openPanel()
    userClosed = false
    if not panel then
        return
    end
    panel.visible = true
    panel.interactive = 1
    if ui.root then
        ui.root:recollect()
    end
end

local function closePanel()
    userClosed = true
    if not panel then
        return
    end
    panel.visible = false
    panel.interactive = -1
    if ui.root then
        ui.root:recollect()
    end
end

local function togglePanel()
    if panel and panel.visible then
        closePanel()
    else
        openPanel()
    end
end


local emptyLabel = uie.label(lang.get("no_downloads")):with({
    style = {
        color = { 1, 1, 1, 0.45 }
    }
})


local function makeRow(task)
    local nameLabel = uie.label(cap(task.name, 30))
    local stateLabel = uie.label("")
    local statusLabel = uie.label("")
    local progressBar = uie.downloadProgressBar():with(uiu.fillWidth)

    local pauseButton = uie.button(lang.get("pause"), function()
        if task.state == "paused" then
            downloadqueue.resume(task)
        else
            downloadqueue.pause(task)
        end
    end)

    local cancelButton = uie.button(lang.get("cancel_download"), function()
        downloadqueue.cancel(task)
    end)

    local refs = {
        name = nameLabel,
        state = stateLabel,
        status = statusLabel,
        progress = progressBar,
        pause = pauseButton,
        cancel = cancelButton,
    }

    local row = uie.paneled.column({
        uie.row({
            nameLabel:with({
                style = {
                    color = { 1, 1, 1, 1 }
                }
            }),
            stateLabel:with({
                style = {
                    color = { 1, 1, 1, 0.6 }
                }
            }),
        }):with(uiu.fillWidth),
        statusLabel:with({
            style = {
                color = { 1, 1, 1, 0.55 }
            },
            wrap = false,
        }),
        progressBar,
        uie.row({
            pauseButton:with({
                style = {
                    padding = 4
                }
            }),
            cancelButton:with({
                style = {
                    padding = 4
                }
            }),
        }),
    }):with({
        cacheable = false,
        style = {
            bg = { 0.1, 0.1, 0.1, 0.55 },
            border = { 1, 1, 1, 0.06, 1 },
            padding = 8,
            spacing = 5,
            radius = 4,
        },
    }):with(uiu.fillWidth)

    row._refs = refs
    row._task = task
    return row
end


local function refreshRow(task, row)
    if not row then
        return
    end

    local refs = row._refs

    local stateText = lang.get(stateKeys[task.state] or "download_queued")
    refs.state:setText(stateText)

    -- Keep the mod name short enough that the state label stays inside the
    -- panel for every language. 16 = the row's own padding, 8 = spacing before
    -- the state label, 8 = reserve for the scrollbox scrollbar.
    local nameFont = refs.name.style.font
    local stateFont = refs.state.style.font
    local stateWidth = stateFont and stateFont:getWidth(stateText) or 0
    local maxNameWidth = PANEL_WIDTH - 16 - 8 - 8 - stateWidth
    refs.name:setText(capToWidth(task.name, nameFont, maxNameWidth))

    refs.status:setText(cap(task.status, 42))

    local progress = refs.progress
    if task.state == "done" then
        progress.progress = 1
    elseif task.state == "downloading" and type(task.progress) == "number" then
        progress.progress = task.progress
    elseif task.state == "downloading" then
        progress.progress = false
    else
        progress.progress = 0
    end
    progress:repaint()

    local paused = task.state == "paused"
    local terminal = task.state == "done" or task.state == "failed" or task.state == "canceled"
    refs.pause:setText(paused and lang.get("resume") or lang.get("pause"))
    refs.pause:setEnabled(not terminal)
    refs.cancel:setEnabled(not terminal)

    local prev = prevState[task]
    if prev ~= task.state then
        if task.state == "done" and not task.autoclose then
            showToast(lang.get("download_complete_title"), string.format(lang.get("download_complete"), task.name))
        elseif task.state == "failed" and not task.autoclose then
            showToast(lang.get("download_failed_title"), string.format(lang.get("download_failed"), task.name))
        end
        prevState[task] = task.state
    end
end


local function refreshList()
    local tasks = downloadqueue.getTasks()
    local n = #tasks

    local seen = {}
    local expected = {}
    for i = 1, n do
        local task = tasks[i]
        local row = rowMap[task]
        if not row then
            row = makeRow(task)
            rowMap[task] = row
            prevState[task] = task.state
        end
        seen[task] = true
        expected[i] = row
    end

    for task in pairs(rowMap) do
        if not seen[task] then
            rowMap[task] = nil
            prevState[task] = nil
        end
    end

    if n == 0 then
        if #listInner.children ~= 1 or listInner.children[1] ~= emptyLabel then
            listInner.children = { emptyLabel }
            listInner:reflow()
        end

    else
        local changed = #listInner.children ~= n
        if not changed then
            for i = 1, n do
                if listInner.children[i] ~= expected[i] then
                    changed = true
                    break
                end
            end
        end
        if changed then
            listInner.children = expected
            listInner:reflow()
        end

        for i = 1, n do
            refreshRow(tasks[i], expected[i])
        end
    end

    if clearButton then
        clearButton:setEnabled(downloadqueue.getFinishedCount() > 0)
    end
end


local function refreshIndicator()
    local el = indicatorEl
    if not el then
        return
    end

    local total = downloadqueue.getCount()
    if total == 0 then
        el.visible = false
        el:setEnabled(false)
        return
    end

    el.visible = true
    el:setEnabled(true)
    local active = downloadqueue.getActiveCount()
    if active > 0 then
        el:setText(string.format("%s (%d)", lang.get("downloads"), active))
    else
        el:setText(lang.get("downloads"))
    end
end


local function refresh()
    refreshList()
    refreshIndicator()

    if downloadqueue.getActiveCount() > 0 and not userClosed and panel and not panel.visible then
        openPanel()
    end
end


local function tick()
    if not dirty then
        return
    end
    local now = love.timer.getTime()
    if now - lastTick >= 0.1 then
        lastTick = now
        dirty = false
        refresh()
    end
end


local function buildPanel()
    local titleLabel = uie.label(lang.get("download_queue"), ui.fontMedium):with({
        style = {
            color = { 1, 1, 1, 1 }
        }
    })

    local closeButton = uie.button("×", function()
        closePanel()
    end):with({
        style = {
            padding = 4
        }
    })

    listInner = uie.column({}):with({
        clip = false,
        cacheable = false,
        style = {
            spacing = 8,
        },
    }):with(uiu.fillWidth)

    local scrollbox = uie.scrollbox(listInner):with({
        height = 220,
        cacheable = false,
    }):with(uiu.fillWidth)

    clearButton = uie.button(lang.get("clear_finished"), function()
        downloadqueue.clearFinished()
    end):with({
        enabled = false,
        style = {
            padding = 5
        }
    }):with(uiu.fillWidth)

    panel = uie.paneled.column({
        uie.row({
            titleLabel,
            closeButton,
        }):with({
            style = {
                spacing = 8
            }
        }):with(uiu.fillWidth),
        scrollbox,
        clearButton,
    }):with({
        width = PANEL_WIDTH,
        visible = false,
        interactive = -1,
        style = {
            bg = { 0.05, 0.05, 0.05, 0.96 },
            border = { 1, 1, 1, 0.1, 1 },
            padding = 12,
            spacing = 8,
            radius = 6,
        },
    }):hook({
        layoutLateLazy = function(orig, self)
            -- Always reflow this child whenever its parent gets reflowed.
            -- Without this, `main`'s column layoutChildren resets this panel
            -- back to its flow position (top-left) on scene reflows, and the
            -- anchor in layoutLate below would only re-run on queue updates,
            -- leaving the panel jumping between both corners.
            self:layoutLate()
            self:repaint()
        end,

        layoutLate = function(orig, self)
            local parent = self.parent
            if parent then
                if self._dragX then
                    -- User has dragged the panel; keep it where they put it,
                    -- clamped inside the parent.
                    local px, py = parent.screenX, parent.screenY
                    local maxX = math.max(px, px + parent.width - self.width)
                    local maxY = math.max(py, py + parent.height - self.height)
                    local x = math.max(px, math.min(maxX, self._dragX))
                    local y = math.max(py, math.min(maxY, self._dragY))
                    self.realX = math.floor(x - px)
                    self.realY = math.floor(y - py)
                else
                    -- Default anchor: top-right corner.
                    self.realX = math.floor(parent.width - self.width - 12)
                    self.realY = 12
                end
            end
            orig(self)
        end,

        -- Drag the panel by its background / header. Buttons and the scrollbox
        -- capture their own presses, so this only fires for the panel itself.
        onPress = function(orig, self, x, y, button)
            if button == 1 then
                self._dragOffsetX = self.screenX - x
                self._dragOffsetY = self.screenY - y
            end
        end,

        onDrag = function(orig, self, x, y, dx, dy)
            if not self._dragOffsetX then
                self._dragOffsetX = self.screenX - x
                self._dragOffsetY = self.screenY - y
            end
            self._dragX = x + self._dragOffsetX
            self._dragY = y + self._dragOffsetY
            self:layoutLate()
            self:repaint()
        end,

        update = function(orig, self, dt)
            orig(self, dt)
            tick()
        end
    })
end


function downloadqueueui.init(main)
    if initialized then
        return
    end
    initialized = true

    buildPanel()
    main:addChild(panel)

    downloadqueue.setChangeHandler(function()
        local count = downloadqueue.getCount()
        if count > lastCount and downloadqueue.getActiveCount() > 0 then
            -- A new mod download started: bring the queue back on top even if
            -- the user dismissed it while an earlier download was still running.
            userClosed = false
        end
        lastCount = count
        dirty = true
    end)

    refresh()
end


function downloadqueueui.makeIndicator()
    local el = uie.menuItem("", function()
        togglePanel()
    end)
    indicatorEl = el
    refreshIndicator()
    return el
end


return downloadqueueui