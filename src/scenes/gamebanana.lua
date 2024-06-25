local ui, uiu, uie = require("ui").quick()
local utils = require("utils")
local threader = require("threader")
local config = require("config")
local alert = require("alert")
local modinstaller = require("modinstaller")

local scene = {
    name = "GameBanana",
    sort = "latest",
    itemtypeFilter = {}
}

local sortOptions = {
    { text = "Most Recent", data = "latest" },
    { text = "Most Downloaded", data = "downloads" },
    { text = "Most Viewed", data = "views" },
    { text = "Most Liked", data = "likes" }
}

-- this will be the type filter dropdown content until the type list is loaded through the API.
local itemtypeOptionsTemp = {
    { text = "All", data = "" }
}

local function generateModColumns(self)
    local listcount = math.max(1, math.min(6, math.floor(love.graphics.getWidth() / 350)))
    if self.listcount == listcount then
        return nil
    end
    self.listcount = listcount

    local lists = {}
    for i = 1, listcount do
        lists[i] = uie.column({
        }):with({
            style = {
                spacing = 2
            },
            cacheable = false
        }):with(uiu.fillWidth(1 / listcount + 1)):with(uiu.at((i == 1 and 0 or 1) + (i - 1) / listcount, 0)):as("mods" .. tostring(i))
    end

    return lists
end


local root = uie.column({

    uie.scrollbox(
        uie.column({
            uie.dynamic():with({
                cacheable = false,
                generate = generateModColumns
            }):with(uiu.fillWidth):as("modColumns")
        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.fillWidth)
    ):with({
        style = {
            barPadding = 16,
        },
        clip = false,
        cacheable = false
    }):with(uiu.fillWidth):with(uiu.fillHeight(59)):with(uiu.at(0, 59)),

    uie.paneled.column({
        uie.group():with({
            height = 32
        }),

        uie.row({

            uie.button(
                uie.row({
                    uie.icon("browser"):with({ scale = 24 / 256 }),
                    uie.label("Go to gamebanana.com"):with({ y = 2 })
                }),
                function()
                    utils.openURL("https://gamebanana.com/games/6460")
                end
            ):as("openGameBananaButton"),

            uie.row({
                uie.button(uie.icon("back"):with({ scale = 24 / 256 }), function()
                    scene.loadPage(scene.page - 1)
                end):as("pagePrev"),
                uie.label("Page #?", ui.fontBig):with({
                    y = 4
                }):as("pageLabel"),
                uie.button(uie.icon("forward"):with({ scale = 24 / 256 }), function()
                    scene.loadPage(scene.page + 1)
                end):as("pageNext"),

            }):with({
                style = {
                    spacing = 24
                },
                cacheable = false,
                clip = false
            }):hook({
                layoutLateLazy = function(orig, self)
                    -- Always reflow this child whenever its parent gets reflowed.
                    self:layoutLate()
                    self:repaint()
                end,

                layoutLate = function(orig, self)
                    orig(self)
                    if scene.searchLast ~= "" then
                        -- there is a search: center the title relative to the window.
                        self.x = math.floor(self.parent.innerWidth * 0.5 - self.width * 0.5)
                        self.realX = math.floor(self.parent.width * 0.5 - self.width * 0.5)
                    else
                        -- there is no search so the dropdowns are shown: center the title between the "open GB" button and the dropdowns.
                        local openGameBananaButton = scene.root:findChild("openGameBananaButton")
                        local rightRow = scene.root:findChild("rightRow")
                        local width = self.parent.innerWidth - openGameBananaButton.width - rightRow.width
                        self.x = math.floor(width * 0.5 - self.width * 0.5 + openGameBananaButton.width)
                        self.realX = math.floor(width * 0.5 - self.width * 0.5 + openGameBananaButton.width)
                    end
                end
            }),

            uie.row({
                uie.dropdown(
                    sortOptions,
                    function(self, value)
                        if value ~= scene.sort then
                            scene.sort = value
                            scene.loadPage(1)
                        end
                    end
                ):as("sort"),

                uie.dropdownWithSubmenu(
                    itemtypeOptionsTemp,
                    function(self, value)
                        if value ~= scene.itemtypeFilter then
                            scene.itemtypeFilter = value
                            scene.loadPage(1)
                        end
                    end
                ):as("itemtypeFilter"),

                uie.field(
                    "",
                    function(self, value, prev)
                        if scene.loadPage and value == prev then
                            scene.loadPage(value)
                        end
                    end
                ):with({
                    width = 200,
                    height = 24,
                    placeholder = "Search"
                }):as("searchBox"),
                uie.button(uie.icon("search"):with({ scale = 24 / 256 }), function()
                    scene.loadPage(scene.root:findChild("searchBox").text)
                end):as("searchBtn"),

            }):with({
                style = {
                    spacing = 8
                },
                cacheable = false,
                clip = false
            }):with(uiu.rightbound):as("rightRow")

        }):with({
            cacheable = false,
            clip = false
        }):with(uiu.fillWidth)
    }):with({
        style = {
            patch = "ui:patches/topbar",
            spacing = 0
        }
    }):with(uiu.at(0, -32)):with(uiu.fillWidth),

}):with({
    style = {
        spacing = 2
    },
    cacheable = false,
    _fullroot = true
})
scene.root = root


scene.cache = {}


scene.searchLast = ""

function scene.loadPage(page)
    if scene.loadingPage then
        return scene.loadingPage
    end

    page = page or scene.page
    if scene.searchLast == page then
        return threader.routine(function() end)
    end

    if page == "" then
        scene.searchLast = ""
        page = scene.page
    end

    scene.loadingPage = threader.routine(function()
        local lists, pagePrev, pageLabel, pageNext, sortDropdown, itemtypeFilterDropdown = root:findChild("modColumns", "pagePrev", "pageLabel", "pageNext", "sort", "itemtypeFilter")

        local errorPrev = root:findChild("error")
        if errorPrev then
            errorPrev:removeSelf()
        end

        local isQuery = type(page) == "string"

        if not isQuery then
            scene.searchLast = ""
            if page < 0 then
                page = 0
            end
        end

        lists.all = {}

        pagePrev.enabled = false
        pageNext.enabled = false
        sortDropdown.enabled = false
        sortDropdown.visible = not isQuery
        itemtypeFilterDropdown.enabled = false
        itemtypeFilterDropdown.visible = not isQuery
        pagePrev:reflow()
        pageNext:reflow()
        sortDropdown:reflow()
        itemtypeFilterDropdown:reflow()

        if not isQuery then
            if page == 0 then
                pageLabel.text = "Featured"
            else
                pageLabel.text = "Page #" .. tostring(page)
            end
            scene.page = page
        else
            pageLabel.text = page
            scene.searchLast = page
        end

        local loading = uie.paneled.row({
            uie.label("Loading"),
            uie.spinner():with({
                width = 16,
                height = 16
            })
        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.bottombound(16)):with(uiu.rightbound(16)):as("loadingMods")
        scene.root:addChild(loading)

        local entries, entriesError
        if not isQuery then
            if page == 0 then
                entries, entriesError = scene.downloadFeaturedEntries()
            else
                entries, entriesError = scene.downloadSortedEntries(page, scene.sort, scene.itemtypeFilter)
            end
        else
            entries, entriesError = scene.downloadSearchEntries(page)
        end

        -- 1/ the previous page button is disabled if there is a search (search does not have pagination)
        -- 2/ if a filter is active, the first page is 1
        -- 3/ if no filter is active (itemtypeFilter is an empty table), the first page is 0 (featured entries)
        local hasPreviousPage = not isQuery and page > 0 and ((scene.sort == "latest" and next(scene.itemtypeFilter) == nil) or page > 1)

        if not entries then
            loading:removeSelf()
            root:addChild(uie.paneled.row({
                uie.label("Error downloading mod list: " .. tostring(entriesError)),
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound(16)):with(uiu.rightbound(16)):as("error"))
            scene.loadingPage = nil
            pagePrev.enabled = hasPreviousPage
            pageNext.enabled = not isQuery
            sortDropdown.enabled = not isQuery
            itemtypeFilterDropdown.enabled = not isQuery
            pagePrev:reflow()
            pageNext:reflow()
            sortDropdown:reflow()
            itemtypeFilterDropdown:reflow()
            return
        end

        for i = 1, #entries do
            lists.next:addChild(scene.item(entries[i]))
        end

        loading:removeSelf()
        scene.loadingPage = nil
        -- "Featured" should be inaccessible if there is a sort or a filter
        pagePrev.enabled = hasPreviousPage
        pageNext.enabled = not isQuery
        sortDropdown.enabled = not isQuery
        itemtypeFilterDropdown.enabled = not isQuery
        pagePrev:reflow()
        pageNext:reflow()
        sortDropdown:reflow()
        itemtypeFilterDropdown:reflow()
    end)
    return scene.loadingPage
end


local function refreshSubcategories(categoryData)
    local categoryDataRequests = {}

    for i, category in ipairs(categoryData) do
        if category.data.itemtype then
            -- Fetch the subcategories of each category
            table.insert(
                categoryDataRequests,
                threader.wrap("utils").downloadYAML("https://maddie480.ovh/celeste/gamebanana-subcategories"
                    .. "?itemtype=" .. category.data.itemtype
                    .. (category.data.categoryid and "&categoryId=" .. category.data.categoryid or "")
                )
            )
        end
    end

    local index = 1
    for _, category in ipairs(categoryData) do
        if category.data.itemtype then
            -- Fetch the subcategory list corresponding to the category
            data, msg = categoryDataRequests[index]:result()
            index = index + 1

            if not data then
                -- Error while calling the API
                root:addChild(uie.paneled.row({
                    uie.label("Error downloading subcategories list: " .. tostring(msg)),
                }):with({
                    clip = false,
                    cacheable = false
                }):with(uiu.bottombound(16)):with(uiu.rightbound(16)):as("error"))

                return false

            elseif #data > 1 then
                -- Convert the list retrieved from the API to a dropdown option list, and assign it to the category as a submenu
                local allTypes = {}
                for _, subcategory in ipairs(data) do
                    table.insert(allTypes, {
                        -- The text includes the count, except for the "All" option
                        text = subcategory.name .. (subcategory.id and " (" .. subcategory.count .. ")" or ""),
                        -- The subcategory id is used as a category filter instead if the parent category only filters on itemtype
                        data = {
                            itemtype = category.data.itemtype,
                            categoryid = category.data.categoryid and category.data.categoryid or subcategory.id,
                            subcategoryid = category.data.categoryid and subcategory.id
                        },
                        -- If selecting the "All" option, the dropdown should use the category's label instead
                        dropdownText = not subcategory.id and category.text
                    })
                end

                category.submenu = allTypes
            end
        end
    end

    return true
end

function scene.load()
    scene.loadPage(0)

    -- Load the categories / item types list upon entering the GameBanana screen
    threader.routine(function()
        local data, msg = threader.wrap("utils").downloadYAML("https://maddie480.ovh/celeste/gamebanana-categories"):result()

        if not data then
            -- Error while calling the API
            root:addChild(uie.paneled.row({
                uie.label("Error downloading categories list: " .. tostring(msg)),
            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.bottombound(16)):with(uiu.rightbound(16)):as("error"))
        else
            -- Convert the list retrieved from the API to a dropdown option list
            local allTypes = {}
            for _, category in ipairs(data) do
                table.insert(allTypes, {
                    text = category.formatted .. " (" .. category.count .. ")",
                    data = {
                        itemtype = category.itemtype,
                        categoryid = category.categoryid
                    }
                })
            end

            if not refreshSubcategories(allTypes) then
                -- An error occurred while fetching a subcategory!
                return
            end

            -- Refresh the dropdown
            local itemtypeFilterDropdown = scene.root:findChild("itemtypeFilter")
            itemtypeFilterDropdown._itemsCache = {}
            itemtypeFilterDropdown.data = allTypes
            itemtypeFilterDropdown:setSelected(itemtypeFilterDropdown:getItem(1))
            itemtypeFilterDropdown:reflow()
        end
    end)


end


function scene.enter()

end

function scene.downloadFeaturedEntries()
    local url = "https://maddie480.ovh/celeste/gamebanana-featured"
    local data = scene.cache[url]
    if data ~= nil then
        return data
    end

    local msg
    data, msg = threader.wrap("utils").downloadJSON(url):result()
    if data then
        scene.cache[url] = data
    end
    return data, msg
end

function scene.downloadSearchEntries(query)
    local url = "https://maddie480.ovh/celeste/gamebanana-search?q=" .. utils.toURLComponent(query)
    local data = scene.cache[url]
    if data ~= nil then
        return data
    end

    local msg
    data, msg = threader.wrap("utils").downloadJSON(url):result()
    if data then
        scene.cache[url] = data
    end
    return data, msg
end

function scene.downloadSortedEntries(page, sort, itemtypeFilter)
    local url = string.format("https://maddie480.ovh/celeste/gamebanana-list?page=%s&sort=%s", page, sort)

    -- apply optional filters
    if itemtypeFilter.itemtype then
        url = url .. "&type=" .. itemtypeFilter.itemtype
    end
    if itemtypeFilter.categoryid then
        url = url .. "&category=" .. itemtypeFilter.categoryid
    end
    if itemtypeFilter.subcategoryid then
        url = url .. "&subcategory=" .. itemtypeFilter.subcategoryid
    end

    local data = scene.cache[url]
    if data ~= nil then
        return data
    end

    local msg
    data, msg = threader.wrap("utils").downloadJSON(url):result()
    if data then
        scene.cache[url] = data
    end
    return data, msg
end

function scene.item(info)
    local name = info.Name
    local owner = info.Author
    local date = info.CreatedDate
    local description = info.Description
    local text = info.Text
    local views = info.Views
    local likes = info.Likes
    local downloads = info.Downloads
    local screenshots = info.MirroredScreenshots
    local files = info.Files
    local website = info.PageURL

    local containsEverestYaml = false

    for _, file in pairs(files) do
        if file.HasEverestYaml then
            containsEverestYaml = true
        end
    end

    local item = uie.group({
        uie.group({
        }):with({
            clip = false,
            cacheable = false
        }):with(uiu.fill):as("bgholder"),

        uie.panel({
        }):hook({
            layoutLateLazy = function(orig, self)
                -- Always reflow this child whenever its parent gets reflowed.
                self:layoutLate()
                self:repaint()
            end,

            layoutLate = function(orig, self)
                orig(self)
                local style = self.style
                style.bg = nil
                local boxBG = style.bg
                -- FIXME: blur is very taxing!
                style.bg = { boxBG[1], boxBG[2], boxBG[3], 0.95 }
            end
        }):with({
            style = {
                padding = 0,
                radius = 0,
                patch = false
            },
            clip = false,
            cacheable = false
        }):with(uiu.fill):as("bgdarken"),

        uie.group({

            uie.column({

                uie.column({

                    uie.column({

                        uie.label({ { 1, 1, 1, 1 }, name, { 1, 1, 1, 0.5 }, "\n" .. owner }):as("title"),

                        uie.row({
                            uie.group({
                                uie.spinner():with({ time = love.math.random() }),
                            }):as("imgholder"),

                            uie.column({
                                uie.label({ { 1, 1, 1, 0.5 }, os.date("%Y-%m-%d %H:%M:%S", date) .. "\n" .. uiu.countformat(views, "%d view", "%d views") .. " ∙ " .. uiu.countformat(likes, "%d like", "%d likes") .. "\n" .. uiu.countformat(downloads, "%d download", "%d downloads"), }):as("stats"),
                            }):with(uiu.fillWidth(16, true))

                        }):with({ style = { spacing = 16 } }):with(uiu.fillWidth),

                        description and #description ~= 0 and uie.label(description):with({ wrap = true }):as("description"),

                    }):with({
                        clip = false,
                        cacheable = false
                    }):with(uiu.fillWidth),

                    uie.row({

                        uie.button(
                            uie.icon("browser"):with({ scale = 24 / 256 }),
                            function()
                                utils.openURL(website)
                            end
                        ),

                        uie.button(
                            uie.icon("article"):with({ scale = 24 / 256 }),
                            function()
                                alert({
                                    title = name,
                                    body = uie.scrollbox(
                                        uie.label(utils.cleanHTML(text)):with({
                                            wrap = true
                                        })
                                    ):with(uiu.fillWidth):with(uiu.fillHeight(true)),
                                    buttons = {
                                        {
                                            "Open in browser",
                                            function()
                                                utils.openURL(website)
                                            end
                                        },
                                        { "Close" }
                                    },
                                    init = function(container)
                                        container:findChild("box"):with({
                                            width = 800
                                        }):with(uiu.fillHeight(64))
                                        container:findChild("buttons"):with(uiu.bottombound)
                                    end
                                })
                            end
                        ),

                        uie.buttonGreen(
                            uie.icon("download"):with({ scale = 24 / 256 }),
                            function()
                                local btns = {}

                                for _, file in ipairs(files) do
                                    if file.HasEverestYaml then
                                        btns[#btns + 1] = file
                                    end
                                end

                                for i = 1, #btns do
                                    local file = btns[i]
                                    btns[i] = uie[i == 1 and "buttonGreen" or "button"](
                                        { { 1, 1, 1, 1 }, file.Name, { 1, 1, 1, 0.5 }, " ∙ " .. os.date("%Y-%m-%d %H:%M:%S", file.CreatedDate) .. " ∙ " .. uiu.countformat(file.Downloads, "%d download", "%d downloads"), { 1, 1, 1, 0.5 }, "\n" .. file.Description},
                                        function(self)
                                            modinstaller.install(file.URL)
                                            self:getParent("container"):close("OK")
                                        end
                                    )
                                end

                                if #btns == 0 then
                                    return
                                end

                                alert({
                                    title = name,
                                    body = uie.scrollbox(uie.column(btns)),
                                    init = function(container)
                                        btns[#btns + 1] = uie.button("Close", function()
                                            container:close("Close")
                                        end)
                                        container:findChild("buttons"):removeSelf()

                                        local body = container:findChild("body")

                                        if #btns < 6 then
                                            body:with({
                                                calcSize = uie.group.calcSize
                                            })
                                            container:hook({
                                                awake = function(orig, self)
                                                    orig(self)
                                                    self:layoutLazy()
                                                    self:layoutLateLazy()
                                                    if self:findChild("title").width > body.width then
                                                        body:with(uiu.fillWidth)
                                                        local el = body.children[1]
                                                        el:with(uiu.fillWidth)
                                                        local children = el.children
                                                        for i = 1, #children do
                                                            children[i]:with(uiu.fillWidth)
                                                        end
                                                    else
                                                        local el = body.children[1]
                                                        local children = el.children
                                                        local widest = 0
                                                        for i = 1, #children do
                                                            local width = children[i].width
                                                            if width > widest then
                                                                widest = width
                                                            end
                                                        end
                                                        for i = 1, #children do
                                                            if children[i].width < widest then
                                                                children[i]:with(uiu.fillWidth):reflow()
                                                            end
                                                        end
                                                    end
                                                    self:reflowDown()
                                                    self:reflow()
                                                end
                                            })

                                        else
                                            body:with(uiu.fillWidth):with(uiu.fillHeight(true))
                                            local el = body.children[1]
                                            el:with(uiu.fillWidth)
                                            local children = el.children
                                            for i = 1, #children do
                                                children[i]:with(uiu.fillWidth)
                                                children[i].label.wrap = true
                                            end
                                            container:findChild("box"):with({
                                                width = 800
                                            }):with(uiu.fillHeight(64))
                                        end
                                    end
                                })
                            end
                        ):with({
                            clip = false,
                            cacheable = false
                        }):with({
                            enabled = containsEverestYaml
                        })

                    }):with({
                        clip = false,
                        cacheable = false
                    }):with(uiu.rightbound)

                }):with({
                    clip = false,
                    cacheable = false
                }):with(uiu.fillWidth),

            }):with({
                clip = false,
                cacheable = false
            }):with(uiu.fillWidth):as("content"),

        }):with({
            style = {
                padding = 16
            },
            clip = false,
            cacheable = false
        }):with(uiu.fillWidth)

    }):with({
        cacheForce = true,
        cachePadding = 0,
        clip = false,
        cacheable = false
    }):with(uiu.fillWidth)

    threader.routine(function()
        local utilsAsync = threader.wrap("utils")

        local bgholder = item:findChild("bgholder")
        local imgholder = item:findChild("imgholder")

        local bg, img

        local function downloadImage(url)
            local img = scene.cache[url]
            if img ~= nil then
                local status, rv = pcall(love.graphics.newImage, img)
                return status and rv
            end

            img = utilsAsync.download(url):result()
            if not img then
                return false
            end

            img = love.filesystem.newFileData(img, url)
            scene.cache[url] = img
            local status, rv = pcall(love.graphics.newImage, img)
            return status and rv
        end

        img = downloadImage(screenshots[1])

        if screenshots[2] then
            bg = downloadImage(screenshots[2])
        end

        bg = bg or img

        imgholder.children[1]:removeSelf()
        if bg then
            local effect = ui.root:findChild("bg").effect
            bg = uie.image(bg):with({
                cacheForce = true,
                cachePadding = 0
            }):hook({
                update = function(orig, self)
                    local image = self._image
                    local width, height = image:getWidth(), image:getHeight()
                    local fwidth, fheight = love.graphics.getWidth(), love.graphics.getHeight()

                    if width >= height then
                        self.scale = (fwidth + 512) / width

                    else
                        self.scale = (fheight + 512) / height
                    end

                    self.ix = fwidth * 0.5 - width * self.scale * 0.5 - (ui.mouseX - fwidth * 0.5) * 0.013 * config.parallax
                    self.iy = fheight * 0.5 - height * self.scale * 0.5 - (ui.mouseY - fheight * 0.5) * 0.013 * config.parallax

                    if orig then
                        orig(self)
                    end
                end,

                drawBG = function(orig, self)
                    if not self.ix then
                        self:update()
                    end
                    love.graphics.draw(self._image, self.ix - self.screenX * 0.8, self.iy - self.screenY * 0.8, 0, self.scale, self.scale)
                end,

                draw = function(orig, self)
                    if not config.quality.bg then
                        return
                    end

                    love.graphics.push()
                    love.graphics.origin()

                    love.graphics.setColor(1, 1, 1, 1)

                    -- FIXME: blur is very taxing!
                    if false and (not ui.debug.draw and config.quality.bgBlur) then
                        effect(self.drawBG, self)
                    else
                        self:drawBG()
                    end

                    love.graphics.pop()

                    uiu.resetColor()
                end
            }):with(uiu.fill)
            bgholder:addChild(bg)
        end
        if img then
            img = uie.image(img):with({
                scaleRoundAuto = "auto"
            })
            if img.image:getWidth() > 100 then
                img.scale = 100 / img.image:getWidth()
            end
            imgholder:addChild(img)
        end
        item:reflowDown()
    end)

    return item
end


return scene
