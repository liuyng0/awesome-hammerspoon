--- @class Frame
--- @field x number
--- @field y number
--- @field w number
--- @field h number

--- @class Space
--- @field id number
--- @field uuid string
--- @field index number
--- @field label string
--- @field type string
--- @field display number
--- @field windows number[]
--- @field first-window number
--- @field last-window number
--- @field has-focus boolean
--- @field is-visible boolean
--- @field is-native-fullscreen boolean

--- @class Display
--- @field id number
--- @field uuid string
--- @field index number
--- @field label string
--- @field frame Frame
--- @field spaces number[]
--- @field has-focus boolean

--- @class Window
--- @field id number
--- @field pid number
--- @field app string
--- @field title string
--- @field scratchpad string
--- @field frame Frame
--- @field role string
--- @field subrole string
--- @field root-window boolean
--- @field display number
--- @field space number
--- @field level number
--- @field sub-level number
--- @field layer string
--- @field sub-layer string
--- @field opacity number
--- @field split-type string
--- @field split-child string
--- @field stack-index number
--- @field can-move boolean
--- @field can-resize boolean
--- @field has-focus boolean
--- @field has-shadow boolean
--- @field has-parent-zoom boolean
--- @field has-fullscreen-zoom boolean
--- @field has-ax-reference boolean
--- @field is-native-fullscreen boolean
--- @field is-visible boolean
--- @field is-minimized boolean
--- @field is-hidden boolean
--- @field is-floating boolean
--- @field is-sticky boolean
--- @field is-grabbed boolean

---@class Focus
---@field windowId number
---@field spaceIndex number
---@field displayIndex number
---@field frame Frame
---@field app string
---@field title string
