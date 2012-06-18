require 'lib.middleclass'
require 'lib.middleclass-extras'

require 'lua.gamestate'
require "lua.imgsfnts"

socket = require "socket"

function love.load()
   math.randomseed(os.time())

   new_turn_sound = love.audio.newSource("/snd/turn.wav")
   buy_sound = love.audio.newSource("/snd/buy.wav")
   attack_sound = love.audio.newSource("/snd/attack.wav")

   gamestate = Gamestate:new()
   gamestate:gotoState('Menu')
end

function love.update(dt)
   gamestate:update(dt)
end

function love.draw()
   gamestate:draw()
end

function love.focus(f)
   gamestate:focus(f)
end

function love.joystickpressed(joystick, button)
   gamestate:joystickpressed(joystick, button)
end

function love.joystickreleased(joystick, button)
   gamestate:joystickreleased(joystick, button)
end

function love.keypressed(key, unicode)
   gamestate:keypressed(key, unicode)
end

function love.keyreleased(key)
   gamestate:keyreleased(key)
end

function love.mousepressed(x, y, button)
   gamestate:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
   gamestate:mousereleased(x, y, button)
end

function love.quit()
   gamestate:quit()
end