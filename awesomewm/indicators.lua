-------------------------------------------------
-- Simple indicators widget
-------------------------------------------------

local UPDATE_TIME = 1 -- Seconds
local MIN_SIZE = 10

local json = require("json")

local wibox = require("wibox")  -- Provides the widgets
local awful = require("awful")  -- For command execution

-- Create the background widget
local indicators = wibox.widget {
  spacing = 1,
  spacing_widget = {
    color  = '#000000',
    widget = wibox.widget.separator,
  },
  layout = wibox.layout.ratio.horizontal
}

local existing_indicators = {}

function update_indicators()
  local ok, file = pcall(function() return io.open("/tmp/indicators.json", "r+" ) end)
  if not ok then
    return false
  end

  local ok, contents = pcall(function() return json.decode(file:read( "*a" )) end)
  if not ok then
    return false
  end
  io.close(file)

  local width = 0
  local count = 0

  -- Update widgets with contents
  for key, value in pairs(contents) do
    if existing_indicators[key] == nil then
      -- Create new widget
      local text = wibox.widget{
        font = "Roboto 9",
        widget = wibox.widget.textbox,
        align = "center",
      }

      text:set_text(key)

      -- Create the background widget
      local background = wibox.container.background()
      background:set_widget(text)
      background.width = text.width
      background:set_fg("#000000")

      existing_indicators[key] = {background, text}
      indicators:add(background)
    end

    existing_indicators[key][1]:set_bg(value)

    local size = existing_indicators[key][2]:get_preferred_size(1)
    if size < MIN_SIZE then
      size = MIN_SIZE
    end

    width = width + size
    count = count + 1
  end

  -- Assign space ratios
  for key, value in pairs(contents) do
    local size = existing_indicators[key][2]:get_preferred_size(1)
    if size < MIN_SIZE then
      size = MIN_SIZE
    end

    local ratio = size / width
    indicators:set_widget_ratio(existing_indicators[key][1], ratio)
  end

  -- Remove widgets no longer present
  for key, value in pairs(existing_indicators) do
    if contents[key] == nil then
      indicators:remove_widgets(existing_indicators[key][1])
      existing_indicators[key] = nil
    end
  end

  indicators.forced_width = width + count * 6
  indicators:emit_signal("widget::updated")
  return true
end

-- Prepare file for usage

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

local filename = "/tmp/indicators.json"

if not file_exists(filename) then
   f, err = io.open(filename,"w")
   local t = f:write("{}")
   f:close()
end


-- Mechanism taken from : https://github.com/elenapan/dotfiles/blob/4a3f73a35035576970117f661bfcc358259cd6c2/config/awesome/evil/brightness.lua

-- Requires inotify-tools
local indicator_subscribe_script = [[
   bash -c "
   while (inotifywait -e modify /tmp/indicators.json -qq) do echo; done
"]]


local wait_for_indicator_info = function()
    awful.spawn.with_line_callback(indicator_subscribe_script, {
        stdout = function(line)
          local ok, result = pcall(function() return update_indicators() end)
        end
    })
end

-- Run once to initialize widgets
wait_for_indicator_info()

-- Export the widget
return indicators
