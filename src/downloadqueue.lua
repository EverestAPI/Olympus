local log = require("logger")("downloadqueue")

local fs = require("fs")
local config = require("config")
local threader = require("threader")
local sharp = require("sharp")

local downloadqueue = {}

-- Task objects appended to this array.
-- They are never reordered or removed, except by clearFinished().
local tasks = {}
local running = false
local changeHandler

-- State machine:
--   queued -> downloading -> done
--   queued -> paused -> queued
--   downloading -> paused -> downloading (resumes the same sharp task)
--   queued / paused / downloading -> canceled
--   downloading -> failed


local function emit()
    if changeHandler then
        local ok, err = pcall(changeHandler)
        if not ok then
            log.warning("downloadqueue change handler error:", err)
        end
    end
end


function downloadqueue.setChangeHandler(cb)
    changeHandler = cb
end


function downloadqueue.getTasks()
    return tasks
end

function downloadqueue.getCount()
    return #tasks
end

local function isActive(task)
    local state = task.state
    return state == "queued" or state == "downloading" or state == "paused"
end

function downloadqueue.getActiveCount()
    local count = 0
    for i = 1, #tasks do
        if isActive(tasks[i]) then
            count = count + 1
        end
    end
    return count
end

function downloadqueue.getQueuedCount()
    local count = 0
    for i = 1, #tasks do
        if tasks[i].state == "queued" then
            count = count + 1
        end
    end
    return count
end

function downloadqueue.getFinishedCount()
    local count = 0
    for i = 1, #tasks do
        local state = tasks[i].state
        if state == "done" or state == "failed" or state == "canceled" then
            count = count + 1
        end
    end
    return count
end


local function deriveName(url)
    if type(url) ~= "string" then
        return ""
    end
    local scheme, rest = url:match("^(%a[%w+.-]*)://(.*)$")
    if scheme == "file" then
        return fs.filename(url) or url
    end
    if scheme == "http" or scheme == "https" then
        -- Fall back to the last path segment (minus any query/fragment) so a
        -- direct link shows a short label instead of the whole URL.
        local path = rest:match("^[^/]*(/.*)$") or "/"
        local tail = path:match("([^/]+)$")
        if tail then
            tail = tail:match("^([^?#]+)") or tail
            if tail ~= "" then
                return tail
            end
        end
    end
    return url
end


-- Enqueues a new mod download.
-- opts: { name = display name, autoclose = quit when it has finished }
function downloadqueue.enqueue(url, mirrorName, opts)
    opts = opts or {}
    local task = {
        url = url,
        mirrorName = mirrorName or "",
        name = opts.name or deriveName(url),
        autoclose = opts.autoclose and true or false,

        state = "queued",
        status = "",
        progress = false, -- number 0..1, or false for indeterminate
        interruptRequest = nil, -- "pause" or "cancel"
        sharpTask = false,
    }
    tasks[#tasks + 1] = task
    emit()
    downloadqueue.ensureRunning()
    return task
end


local function nextQueuedTask()
    for i = 1, #tasks do
        if tasks[i].state == "queued" then
            return tasks[i]
        end
    end
    return nil
end


function downloadqueue.ensureRunning()
    if running then
        return
    end
    running = true
    threader.routine(function()
        downloadqueue.pump()
    end)
end


-- Single pump which processes one task at a time in the background.
function downloadqueue.pump()
    local ok, err = pcall(function()
        while true do
            local task = nextQueuedTask()
            if not task then
                return
            end

            local pok, perr = pcall(downloadqueue.processTask, task)
            if not pok then
                log.error("downloadqueue.processTask failed:", perr)
                task.state = "failed"
                task.status = tostring(perr)
                task.progress = false
                task.sharpTask = false
                emit()
            end
        end
    end)

    running = false
    emit()

    if not ok then
        log.error("downloadqueue.pump died:", err)
    end
end


-- Runs the actual download for one task. Executed inside a threader.routine.
function downloadqueue.processTask(task)
    -- A task that was paused keeps its sharp task around, so we resume the same
    -- download instead of starting it over from scratch.
    local sharpTask = task.sharpTask

    task.state = "downloading"
    task.interruptRequest = nil
    if not sharpTask then
        task.status = ""
        task.progress = false
    end
    emit()

    local install = config.installs[config.install]
    install = install and install.path
    if not install then
        error("no install path configured")
    end

    if sharpTask then
        local status = sharp.resumeTask(sharpTask):result()
        if not status then
            -- The sharp task disappeared (for example, sharp restarted), so the
            -- partial download is gone too: fall back to a fresh install.
            sharpTask = false
            task.sharpTask = false
            task.status = ""
            task.progress = false
        end
    end

    if not sharpTask then
        sharpTask = sharp.installMod(install, task.url, task.mirrorName, config.mirrorPreferences):result()
        task.sharpTask = sharpTask
    end

    local batch
    local last
    repeat
        if task.interruptRequest == "pause" then
            -- Park the sharp task instead of freeing it: its state (open stream,
            -- partially downloaded file) is kept so resuming continues it.
            sharp.pauseTask(sharpTask):result()

            if task.interruptRequest == "cancel" then
                -- Canceled while we were pausing.
                sharp.free(sharpTask):result()
                task.sharpTask = false
                task.state = "canceled"
                task.interruptRequest = nil
                emit()
                return
            end

            task.state = "paused"
            task.interruptRequest = nil
            emit()
            return

        elseif task.interruptRequest == "cancel" then
            sharp.free(sharpTask):result()
            task.sharpTask = false
            task.state = "canceled"
            task.interruptRequest = nil
            emit()
            return
        end

        batch = sharp.pollWaitBatch(sharpTask):result()
        local all = batch[3]
        if all then
            for i = 1, #all do
                local update = all[i]
                if update ~= nil then
                    last = update
                    task.status = update[1]
                    if type(update[2]) == "number" then
                        task.progress = update[2]
                    else
                        task.progress = false
                    end
                end
            end
        end
        emit()
    until batch[1] ~= "running" and batch[2] == 0

    local status = sharp.free(sharpTask):result()
    task.sharpTask = false

    if task.interruptRequest == "pause" then
        task.state = "paused"
        task.interruptRequest = nil
        emit()
        return
    elseif task.interruptRequest == "cancel" then
        task.state = "canceled"
        task.interruptRequest = nil
        emit()
        return
    end

    if status == "error" then
        task.state = "failed"
        task.status = task.status or "error"
        task.progress = false
        emit()
        return
    end

    task.state = "done"
    task.progress = 1
    emit()

    if task.autoclose then
        threader.sleep(2)
        love.event.quit()
    end
end


function downloadqueue.pause(task)
    if task.state == "queued" then
        task.state = "paused"
        emit()
    elseif task.state == "downloading" then
        task.interruptRequest = "pause"
    end
    return task
end

function downloadqueue.resume(task)
    if task.state == "paused" then
        task.state = "queued"
        emit()
        downloadqueue.ensureRunning()
    end
    return task
end

function downloadqueue.cancel(task)
    if task.state == "downloading" then
        task.interruptRequest = "cancel"
    elseif task.state == "queued" or task.state == "paused" then
        if task.sharpTask then
            -- A paused task keeps its sharp task parked; release it now.
            sharp.free(task.sharpTask):result()
            task.sharpTask = false
        end
        task.state = "canceled"
        emit()
    end
    return task
end

function downloadqueue.clearFinished()
    local removed = false
    for i = #tasks, 1, -1 do
        local task = tasks[i]
        local state = task.state
        if state == "done" or state == "failed" or state == "canceled" then
            if task.sharpTask then
                sharp.free(task.sharpTask):result()
                task.sharpTask = false
            end
            table.remove(tasks, i)
            removed = true
        end
    end
    if removed then
        emit()
    end
end


return downloadqueue