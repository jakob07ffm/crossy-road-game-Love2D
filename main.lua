function love.load()
    love.window.setMode(800, 600)
    font = love.graphics.newFont(20)
    menuFont = love.graphics.newFont(30)
    love.graphics.setFont(font)
    state = "menu"
    resetGame()
    createSounds()
end

function createSounds()
    beepSound = love.audio.newSource(love.sound.newSoundData(0.1, 44100, 16, 1), "static")
    beepSound:setPitch(2)
    gameOverSound = love.audio.newSource(love.sound.newSoundData(0.3, 44100, 16, 1), "static")
end

function resetGame()
    player = {x = 400, y = 570, size = 30, score = 0, lives = 3}
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
    paused = false
end

function love.update(dt)
    if state == "menu" then
        if love.keyboard.isDown("space") then
            state = "game"
        end
        return
    elseif state == "game" then
        if paused then
            if love.keyboard.isDown("p") then
                paused = false
            end
            return
        else
            if love.keyboard.isDown("p") then
                paused = true
                return
            end
        end

        if gameOver then
            if love.keyboard.isDown("space") then
                resetGame()
            end
            return
        end

        movePlayer(dt)
        updateLanes(dt)
        checkCollisions()

        if player.y < 0 then
            levelUp()
        end
    end
end

function movePlayer(dt)
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
end

function updateLanes(dt)
    for _, lane in pairs(lanes) do
        for _, car in pairs(lane.cars) do
            car.x = car.x + lane.speed * dt * lane.direction
            if lane.direction == 1 and car.x > 800 then
                car.x = -car.width
            elseif lane.direction == -1 and car.x < -car.width then
                car.x = 800
            end
        end
    end
end

function checkCollisions()
    for _, lane in pairs(lanes) do
        for _, car in pairs(lane.cars) do
            if checkCollision(player, car) then
                player.lives = player.lives - 1
                love.audio.play(beepSound)
                if player.lives <= 0 then
                    love.audio.play(gameOverSound)
                    gameOver = true
                else
                    player.y = 570
                end
                return
            end
        end
    end
end

function levelUp()
    player.score = player.score + 1
    player.y = 570
    increaseDifficulty()
end

function increaseDifficulty()
    for _, lane in pairs(lanes) do
        lane.speed = lane.speed + 20
        local newCar = {x = lane.direction == 1 and -100 or 800, y = lane.y, width = math.random(50, 100), height = 30}
        table.insert(lane.cars, newCar)
    end
end

function love.draw()
    if state == "menu" then
        drawMenu()
    elseif state == "game" then
        if gameOver then
            drawGameOver()
        else
            drawGame()
        end
    end
end

function drawMenu()
    love.graphics.setFont(menuFont)
    love.graphics.printf("Crossy Road Clone", 0, 200, 800, "center")
    love.graphics.setFont(font)
    love.graphics.printf("Press Space to Start", 0, 300, 800, "center")
end

function drawGame()
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
    love.graphics.print("Lives: " .. player.lives, 10, 30)
    if paused then
        love.graphics.printf("Paused", 0, 250, 800, "center")
    end
end

function drawGameOver()
    love.graphics.printf("Game Over! Score: " .. player.score, 0, 250, 800, "center")
    love.graphics.printf("Press Space to Restart", 0, 300, 800, "center")
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           a.x + a.size > b.x and
           a.y < b.y + b.height and
           a.y + a.size > b.y
end
