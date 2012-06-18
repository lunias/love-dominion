Gamestate = class('Gamestate'):include(Stateful)

require 'lua.Menu'
require 'lua.Server_Wait'
require 'lua.Server'
require 'lua.Type_IP'
require 'lua.Client_Wait'
require 'lua.Client'

function Gamestate:initialize()
end

function Gamestate:update(dt)
end

function Gamestate:draw()
end

function Gamestate:focus(f)
end

function Gamestate:joystickpressed(joystick, button)
end

function Gamestate:joystickreleased(joystick, button)
end

function Gamestate:keypressed(key, unicode)
end

function Gamestate:keyreleased(key)
end

function Gamestate:mousepressed(x, y, button)
end

function Gamestate:mousereleased(x, y, button)
end

function Gamestate:quit()
end