-- 2014-02-24 by eXpander
--2026 by cest73

---------------- USER CONFIGURATION ----------------

-- Diameter in pixels of the outermost ring. Raise it to make the whole widget
-- bigger. It is a floor, not a cap: the rings grow past it on their own when
-- the temperature bars need more room, and everything shrinks together if the
-- conky window in start_conky is smaller than the result.
-- some 200 less than size in conky.conf --
widget_size = 1240 
--widget_size = 824
--widget_size = 568

-- Colors
HTML_colors = "#000000"
HTML_colors_current = "#FFDD88"
transparency = 0.35 -- From 0 to 1

-- Scaled relative position from middle. Positive x and y means left and up,
-- negative x and y means right and down.
x_rel_pos = 0
y_rel_pos = 0

---------------- DON'T EDIT BELOW IF YOU DO NOT KNOW WHAT YOU ARE DOING ----------------

require 'cairo'
-- Conky moved cairo_xlib_surface_create into its own module; older builds
-- still export it from 'cairo', so a missing module here is harmless.
pcall(require, 'cairo_xlib')

-- Newer Conky hands out a cached surface for its own window and keeps ownership
-- of it; older builds need an xlib surface made (and freed) on every draw. The
-- second return value says whether this code is responsible for destroying it.
local function conky_window_surface()
  if type(conky_surface) == "function" then
    return conky_surface(), false
  end
  return cairo_xlib_surface_create(conky_window.display, conky_window.drawable,
                                   conky_window.visual, conky_window.width,
                                   conky_window.height), true
end

local function hex2rgb(hex)
  hex = hex:gsub("#", "")
  return tonumber("0x" .. hex:sub(1, 2)) / 255,
         tonumber("0x" .. hex:sub(3, 4)) / 255,
         tonumber("0x" .. hex:sub(5, 6)) / 255
end

local r, g, b = hex2rgb(HTML_colors)
local r_c, g_c, b_c = hex2rgb(HTML_colors_current)

-- Conky yields an empty string for a sensor or mount point that is not there.
-- Without this, one missing reading would abort the whole draw and the widget
-- would simply vanish.
local function number_or(value, default)
  return tonumber(value) or default
end

-- Day 0 of next month is the last day of this one.
local function days_in_current_month()
  local now = os.date("*t")
  return os.date("*t", os.time({year = now.year, month = now.month + 1, day = 0, hour = 12})).day
end

-- Reusing one extents struct avoids allocating per label per redraw.
local extents
local function measure(cr, text)
  extents = extents or cairo_text_extents_t:create()
  cairo_text_extents(cr, text, extents)
  return extents
end

--   operator -- cairo operator used while drawing the labels
local function create_circle(cr, w, h, members, distance_between_members,
                             radius, line_width, operator, baseline_shift_for_text, pointer,
                             days, shift_days_distance,arc_label)

  cairo_set_line_width(cr, line_width)
  -- General case pointer is direct

  local current = pointer
  -- Special case pointer is offset
  if days[1] == "00" then 
    current = pointer + 1
  end
  -- The rounded ends are a function of arc width
  local arc_round = line_width / 2
  local angle_of_arc_round = math.atan(arc_round / radius)
  local angle_of_members = (360 - (members * distance_between_members)) / members
  local start_angle = 270
  local end_angle = 270 + ((current - 1 + .5) * (angle_of_members + distance_between_members )) + (angle_of_arc_round / math.pi * 180 / 8)
  local text_radius = radius + baseline_shift_for_text

  cairo_new_path(cr)

  --Render arc_label
  cairo_set_source_rgba(cr, r, g, b, transparency)
  local label_size = measure(cr, arc_label)
  cairo_set_operator(cr, operator)
  cairo_move_to(cr, w / 2 + ((text_radius) * math.cos((start_angle * (math.pi / 180.0)) + angle_of_arc_round / 2)) - label_size.width - (arc_round * 2) ,
                    h / 2 + ((text_radius) * math.sin((start_angle * (math.pi / 180.0)) + angle_of_arc_round / 2)))
  cairo_show_text(cr, arc_label)
  cairo_fill(cr)

  cairo_set_source_rgba(cr, r_c, g_c, b_c, transparency)
  --Rounded start
  if current ~= members then
  cairo_set_operator(cr, operator)
  cairo_set_line_width(cr, 0)
  cairo_arc(cr, w / 2 + ((radius) * math.cos((start_angle * (math.pi / 180.0))) + angle_of_arc_round / 2),
                h / 2 + ((radius) * math.sin((start_angle * (math.pi / 180.0))) + angle_of_arc_round / 2), arc_round , 0, 2 * math.pi)
  cairo_fill(cr)
  end

  -- The ARC segement
  cairo_set_operator(cr, operator)
  cairo_set_line_width(cr, line_width)
  if current == members then
    cairo_set_line_width(cr, line_width)
    cairo_arc(cr, w / 2, h / 2, radius, 0, 2 * math.pi)
  else
    cairo_set_line_width(cr, line_width)
    cairo_arc(cr, w / 2, h / 2, radius, start_angle * math.pi / 180, end_angle * math.pi / 180)
  end
  cairo_stroke(cr)

  -- Labels
  start_angle = 270
  cairo_set_operator(cr, operator)
  cairo_set_source_rgba(cr, r_c, g_c, b_c, transparency)

  for i = 1, members do
  local run_angle = 270 + ((i - 1) * (angle_of_members + distance_between_members))
  cairo_set_source_rgba(cr, r, g, b, transparency)
    if i == current then
      cairo_set_source_rgba(cr, r_c, g_c, b_c, transparency)
    end

    local label = days[i]
    -- Wider labels start further into their segment so they stay centred.
    local text_offset = math.abs(angle_of_members - shift_days_distance) / 2
    local extra_rotation = 4

    if text_offset then
      local text_angle = (run_angle + text_offset)
      local arc_angle =  (run_angle + text_offset)
      local rotation = (text_offset + (angle_of_members + distance_between_members) * (i - 1) + extra_rotation)

      if i == current then
        cairo_arc(cr,  w / 2 + ((radius) * math.cos((arc_angle * (math.pi / 180.0)) + angle_of_arc_round / 2)),
                       h / 2 + ((radius) * math.sin((arc_angle * (math.pi / 180.0)) + angle_of_arc_round / 2)), arc_round , 0, 2 * math.pi)
        cairo_set_operator(cr, operator)
        cairo_fill(cr)
        cairo_arc(cr,  w / 2 + ((radius) * math.cos((arc_angle * (math.pi / 180.0)) + angle_of_arc_round / 2)),
                       h / 2 + ((radius) * math.sin((arc_angle * (math.pi / 180.0)) + angle_of_arc_round / 2)), arc_round * 0.83, 0, 2 * math.pi)
        cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR)
        cairo_fill(cr)
      end
    
      cairo_move_to(cr, w / 2 + (text_radius * math.cos(text_angle * (math.pi / 180.0))),
                        h / 2 + (text_radius * math.sin(text_angle * (math.pi / 180.0))))
      cairo_rotate(cr, rotation * math.pi / 180.0)
      cairo_set_operator(cr, operator)
      -- Don't show labels under the arc
      if i == current then cairo_show_text(cr, label) end
      cairo_rotate(cr, -rotation * math.pi / 180.0)
    end
  cairo_close_path(cr)
  end
end

-- Every length below is expressed against this design size and multiplied by
-- the scale worked out in layout_for(); angles are of course scale-free.
local BASE_DIAMETER = 450   -- outermost ring at scale 1, i.e. the original look
local INNER_RADIUS  = 130   -- usable space inside the innermost ring, with margin

-- A gauge is a 10-block column 15 wide and 48 tall with a labelled dot beneath
-- it, and the block of them starts GAUGE_TOP below the centre of the rings.
-- The dot hangs GAUGE_DOT_GAP under the column so the circles keep clear of the
-- bars; DOT_RADIUS_MAX budgets the height a dot may take, which is what lets the
-- gauge box be measured before the labels are known.
local GAUGE_WIDTH = 5
local GAUGE_COLUMN_HEIGHT = 48
local GAUGE_DOT_GAP = 16
local DOT_RADIUS_MAX = 10
local GAUGE_DOT_Y = GAUGE_COLUMN_HEIGHT + GAUGE_DOT_GAP + DOT_RADIUS_MAX
local GAUGE_HEIGHT = GAUGE_DOT_Y + DOT_RADIUS_MAX
local GAUGE_PITCH_X = 30
local GAUGE_PITCH_Y = GAUGE_HEIGHT + 8
local GAUGE_TOP = 25

-- Wrap the gauges into the grid whose furthest corner sits closest to the
-- centre, so the rings have to grow as little as possible. For 32 gauges this
-- picks 16 x 2; for the original 4 it picks a single row, leaving the classic
-- layout untouched.
local function grid_for(count)
  local best
  for columns = 1, count do
    local rows = math.ceil(count / columns)
    local width = GAUGE_PITCH_X * (columns - 1) + GAUGE_WIDTH
    local height = GAUGE_PITCH_Y * (rows - 1) + GAUGE_HEIGHT
    local reach = math.sqrt((width / 2) ^ 2 + (GAUGE_TOP + height) ^ 2)
    if best == nil or reach < best.reach then
      best = {columns = columns, rows = rows, reach = reach}
    end
  end
  return best
end

-- Rings and gauges deliberately do not share a scale. Scaling both together
-- would enlarge the block by exactly the factor the rings grew by, so it would
-- never come to fit; instead the gauges keep the size asked for and the rings
-- grow around them.
local grid, ring_growth, laid_out_for

local function layout_for(count)
  if laid_out_for == count then return end
  laid_out_for = count
  grid = grid_for(count)
  ring_growth = 1, 130
   --math.max(1, grid.reach / INNER_RADIUS)
end

local warned = false
local function warn_once(count, available, needed)
  if warned then return end
  warned = true
  io.stderr:write(string.format(
    "conky lua_widgets: %d gauges need a %dpx window; this one is %dpx, so the widget " ..
    "has been scaled down. Raise minimum_width/minimum_height in start_conky.\n",
    count, math.ceil(needed), math.floor(available)))
end

--[[
   ==============================================================================

   Main function here:

   ==============================================================================
--]]
local function draw_function(cr)
  local w, h = conky_window.width, conky_window.height
  local width, height = w - x_rel_pos, h - y_rel_pos
  local center_x, center_y = width / 2, height / 2
  -- The stepping of arcs
  local inside = 80
  local thick = 25
  local gap = 2
  local step = thick + gap
  local arc = 5 -- five arcs in total
  
  -- Never draw larger than the window; shrinking everything by one factor keeps
  layout_for(2)
  local operator = CAIRO_OPERATOR_SOURCE
  --local operator = CAIRO_OPERATOR_XOR
  --local operator = CAIRO_OPERATOR_OVER
  local base = widget_size / BASE_DIAMETER
  local needed = BASE_DIAMETER * base * ring_growth
  local available = math.min(width, height)
  local fit = math.min(1, available / needed)
  if fit < 0.99 then warn_once(count, available, needed) end

  local gauge_scale = base * fit
  local scale = base * ring_growth * fit   -- everything positioned off the rings

  cairo_set_line_width(cr, 3 * scale)
  cairo_set_font_size(cr, 10 * scale)
  cairo_select_font_face(cr, "Dejavu Sans Condensed", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL)

  -- Seconds
  local seconds = {"00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59"}
  create_circle(cr, width, height, #seconds, 3, (inside + (step * arc)) * scale, thick * scale,
                operator, -3.5 * scale, tonumber(os.date("%S")), seconds, 0, "Seconds:")

  arc = arc - 1
  -- Minutes
  local minutes = seconds -- TODO add text
  create_circle(cr, width, height, #minutes, 3, (inside + (step * arc)) * scale, thick * scale,
                operator, -3.5 * scale, tonumber(os.date("%M")), minutes, 0, "Minutes:")

  arc = arc - 1
    -- Hours
  local hours = {"00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23"}
  create_circle(cr, width, height, #hours, 3, (inside + (step * arc)) * scale, thick * scale,
                operator, -3.5 * scale, tonumber(os.date("%H")), hours, 0, "Hours:")

  arc = arc - 1
  -- Day in the current month
  local days ={"01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31"}
  create_circle(cr, width, height, days_in_current_month(), 3, (inside + (step * arc)) * scale, thick * scale,
                operator, -3.5 * scale, tonumber(os.date("%d")), days, 0, "Day:")

  arc = arc - 1
  -- Day in week
  local days = {"Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"}
  create_circle(cr, width, height, #days, 3, (inside + (step * arc)) * scale, thick * scale,
                operator, -3.5 * scale, tonumber(os.date("%u")), days, 0, "Weekday:")

  arc = arc - 1
  -- Month
  local months = {"Ja", "Fe", "Mr", "Ap", "My", "Jn", "Jl", "Au", "Se", "Oc", "No", "De"}
  create_circle(cr, width, height, #months, 3, (inside + (step * arc)) * scale, thick * scale,
                operator, -3.5 * scale, tonumber(os.date("%m")), months, 0, "Month:")

  -- Year
  cairo_set_source_rgba(cr, r_c, g_c, b_c, transparency)
  cairo_set_font_size(cr, 30 * scale)
  local clock = os.date("%H:%M:%S")
  local clock_size = measure(cr, clock)
  cairo_move_to(cr, center_x - clock_size.width / 2 - clock_size.x_bearing, center_y)
  cairo_show_text(cr, clock)
  --cairo_set_font_size(cr, 10 * scale)

end

function conky_start_widgets()
  if conky_window == nil then return end

  local cs, owns_surface = conky_window_surface()
  local cr = cairo_create(cs)

  -- Check that Conky has been running for at least 5s
  if number_or(conky_parse('${updates}'), 0) > 5 then
    draw_function(cr)
  end

  cairo_destroy(cr)
  if owns_surface then cairo_surface_destroy(cs) end
end
