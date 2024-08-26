function love.load()
    love.window.setMode(800, 600)
    font = love.graphics.newFont(20)
    resetGame()
end

function resetGame()
    player = {x = 400, y = 570, size = 30, score = 0}
    lanes = {}
    for i = 1, 5 do
        table.insert(lanes, {y = i * 100 + 50, speed = math.random(100, 300), direction = math.random(0, 1) == 0 and -1 or 1, cars = {}})
    end
    for _, lane in pairs(lanes) do
        for j = 1, math.random(2, 4) do
            local carWidth = math.random(50, 100)
            local carX = lane.direction == 1 and math.random(-800, -100) or math.random(800, 1600)
            table.insert(lane.cars, {x = carX, y = lane.y, width = carWidth, height = 30})
        end
    end
    gameOver = false
    timer = 0
end

function love.update(dt)
    if gameOver then
        if love.keyboard.isDown("space") then
            resetGame()
        end
        return
    end

    if love.keyboard.isDown('up') and player.y > 0 then
        player.y = player.y - 200 * dt
    end
    if love.keyboard.isDown('down') and player.y < 570 then
        player.y = player.y + 200 * dt
    end
    if love.keyboard.isDown('left') and player.x > 0 then
        player.x = player.x - 200 * dt
    end
    if love.keyboard.isDown('right') and player.x < 770 then
        player.x = player.x + 200 * dt
    end

    for _, lane in pairs(lanes) do
        for _, car in pairs(lane.cars) do
            car.x = car.x + lane.speed * dt * lane.direction
            if lane.direction == 1 and car.x > 800 then
                car.x = -car.width
            elseif lane.direction == -1 and car.x < -car.width then
                car.x = 800
            end
            if checkCollision(player, car) then
                gameOver = true
            end
        end
    end

    if player.y < 0 then
        player.score = player.score + 1
        player.y = 570
        increaseDifficulty()
    end
end

function increaseDifficulty()
    for _, lane in pairs(lanes) do
        lane.speed = lane.speed + 20
    end
end

function love.draw()
    love.graphics.setFont(font)
    if gameOver then
        love.graphics.printf("Game Over! Score: " .. player.score, 0, 250, 800, "center")
        love.graphics.printf("Press Space to Restart", 0, 300, 800, "center")
        return
    end

    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)
    love.graphics.setColor(1, 0, 0)
    for _, lane in pairs(lanes) do
        for _, car in pairs(lane.cars) do
            love.graphics.rectangle("fill", car.x, car.y, car.width, car.height)
        end
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. player.score, 10, 10)
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.size > b.x and
           a.y < b.y + b.height and
           a.y + a.size > b.y
end
