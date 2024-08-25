function love.load()
    love.window.setMode(800, 600)
    player = {x = 100, y = 300, size = 30}
    cars = {}
    for i = 1, 5 do
        table.insert(cars, {x = i * 160, y = math.random(100, 500), width = 60, height = 30, speed = math.random(100, 200)})
    end
    timer = 0
end

function love.update(dt)
    player.y = player.y + 200 * dt
    if love.keyboard.isDown('up') then
        player.y = player.y - 200 * dt
    end
    if love.keyboard.isDown('down') then
        player.y = player.y + 200 * dt
    end
    if love.keyboard.isDown('left') then
        player.x = player.x - 200 * dt
    end
    if love.keyboard.isDown('right') then
        player.x = player.x + 200 * dt
    end
    for _, car in pairs(cars) do
        car.x = car.x + car.speed * dt
        if car.x > 800 then
            car.x = -car.width
            car.y = math.random(100, 500)
        end
        if checkCollision(player, car) then
            love.load()
        end
    end
end

function love.draw()
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)
    love.graphics.setColor(1, 0, 0)
    for _, car in pairs(cars) do
        love.graphics.rectangle("fill", car.x, car.y, car.width, car.height)
    end
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.size > b.x and
           a.y < b.y + b.height and
           a.y + a.size > b.y
end
