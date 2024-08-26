function love.load()
    love.window.setMode(800, 600)
    font = love.graphics.newFont(20)
    menuFont = love.graphics.newFont(30)
    love.graphics.setFont(font)
    state = "menu"
    highScores = loadHighScores()
    resetGame()
    createSounds()
    loadBackgroundMusic()
end

function loadHighScores()
    local scores = {0, 0, 0, 0, 0}
    if love.filesystem.getInfo("highscores.txt") then
        local contents = love.filesystem.read("highscores.txt")
        scores = {}
        for score in string.gmatch(contents, "%d+") do
            table.insert(scores, tonumber(score))
        end
    end
    return scores
end

function saveHighScores()
    table.sort(highScores, function(a, b) return a > b end)
    local contents = table.concat(highScores, "\n")
    love.filesystem.write("highscores.txt", contents)
end

function createSounds()
    beepSound = love.audio.newSource(love.sound.newSoundData(0.1, 44100, 16, 1), "static")
    beepSound:setPitch(2)
    gameOverSound = love.audio.newSource(love.sound.newSoundData(0.3, 44100, 16, 1), "static")
    levelUpSound = love.audio.newSource(love.sound.newSoundData(0.2, 44100, 16, 1), "static")
    powerUpSound = love.audio.newSource(love.sound.newSoundData(0.2, 44100, 16, 1), "static")
end

function loadBackgroundMusic()
    music = love.audio.newSource("background_music.mp3", "stream")
    music:setLooping(true)
    love.audio.play(music)
end

function resetGame()
    player = {x = 400, y = 570, size = 30, score = 0, lives = 3, invincible = false, speed = 200, flashTimer = 0}
    lanes = {}
    createLanes()
    powerUps = {}
    hazards = {}
    addRandomPowerUp()
    addRandomHazard()
    gameOver = false
    paused = false
    flashTimer = 0
    screenShake = 0
    level = 1
    levelTheme = "day"
end

function createLanes()
    for i = 1, 5 do
        table.insert(lanes, {y = i * 100 + 50, speed = math.random(100, 300), direction = math.random(0, 1) == 0 and -1 or 1, cars = {}})
    end
    for _, lane in pairs(lanes) do
        for j = 1, math.random(2, 4) do
            local carWidth = math.random(50, 100)
            local carX = lane.direction == 1 and math.random(-800, -100) or math.random(800, 1600)
            table.insert(lane.cars, {x = carX, y = lane.y, width = carWidth, height = 30, color = {math.random(), math.random(), math.random()}})
        end
    end
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

        if screenShake > 0 then
            screenShake = screenShake - dt
        end

        movePlayer(dt)
        updateLanes(dt)
        checkCollisions()
        updatePowerUps(dt)
        updateHazards(dt)

        if player.y < 0 then
            levelUp()
        end

        if player.flashTimer > 0 then
            player.flashTimer = player.flashTimer - dt
        end
    end
end

function movePlayer(dt)
    local speed = player.speed
    if love.keyboard.isDown('up') and player.y > 0 then
        player.y = player.y - speed * dt
    end
    if love.keyboard.isDown('down') and player.y < 570 then
        player.y = player.y + speed * dt
    end
    if love.keyboard.isDown('left') and player.x > 0 then
        player.x = player.x - speed * dt
    end
    if love.keyboard.isDown('right') and player.x < 770 then
        player.x = player.x + speed * dt
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
                if not player.invincible then
                    player.lives = player.lives - 1
                    player.flashTimer = 0.5
                    love.audio.play(beepSound)
                    screenShake = 0.3
                    player.invincible = true
                    if player.lives <= 0 then
                        love.audio.play(gameOverSound)
                        gameOver = true
                        table.insert(highScores, player.score)
                        saveHighScores()
                    end
                    return
                end
            end
        end
    end
end

function updatePowerUps(dt)
    for i, powerUp in ipairs(powerUps) do
        if checkCollision(player, powerUp) then
            applyPowerUp(powerUp.type)
            table.remove(powerUps, i)
            love.audio.play(powerUpSound)
        end
    end
end

function applyPowerUp(type)
    if type == "life" then
        player.lives = player.lives + 1
    elseif type == "speed" then
        player.speed = player.speed + 50
    elseif type == "shield" then
        player.invincible = true
        player.flashTimer = 2
    end
end

function updateHazards(dt)
    for i, hazard in ipairs(hazards) do
        if checkCollision(player, hazard) then
            applyHazardEffect(hazard.type)
            table.remove(hazards, i)
        end
    end
end

function applyHazardEffect(type)
    if type == "pothole" then
        player.speed = player.speed - 50
    elseif type == "oil" then
        player.x = player.x + math.random(-50, 50)
    end
end

function addRandomPowerUp()
    table.insert(powerUps, {x = math.random(100, 700), y = math.random(50, 550), type = "life"})
end

function addRandomHazard()
    table.insert(hazards, {x = math.random(100, 700), y = math.random(50, 550), type = "pothole"})
end

function levelUp()
    player.score = player.score + 1
    player.y = 570
    increaseDifficulty()
    level = level + 1
    updateLevelTheme()
    if player.score % 5 == 0 then
        addRandomPowerUp()
    end
    player.invincible = false
    love.audio.play(levelUpSound)
end

function increaseDifficulty()
    for _, lane in pairs(lanes) do
        lane.speed = lane.speed + 20
        local newCar = {x = lane.direction == 1 and -100 or 800, y = lane.y, width = math.random(50, 100), height = 30, color = {math.random(), math.random(), math.random()}}
        table.insert(lane.cars, newCar)
    end
end

function updateLevelTheme()
    if level % 5 == 0 then
        if levelTheme == "day" then
            levelTheme = "night"
        elseif levelTheme == "night" then
            levelTheme = "rain"
        elseif levelTheme == "rain" then
            levelTheme = "day"
        end
    end
end

function love.draw()
    if state == "menu" then
        drawMenu()
    elseif state == "game" then
        if gameOver then
            drawGameOver()
        else
            love.graphics.push()
            if screenShake > 0 then
                love.graphics.translate(math.random(-5, 5), math.random(-5, 5))
            end
            drawGame()
            love.graphics.pop()
        end
    end
end

function drawMenu()
    love.graphics.setFont(menuFont)
    love.graphics.printf("Advanced Crossy Road", 0, 150, 800, "center")
    love.graphics.setFont(font)
    love.graphics.printf("Press Space to Start", 0, 250, 800, "center")
    drawHighScores()
end

function drawHighScores()
    love.graphics.setFont(font)
    love.graphics.printf("High Scores", 0, 350, 800, "center")
    for i, score in ipairs(highScores) do
        love.graphics.printf(i .. ". " .. score, 0, 350 + i * 20, 800, "center")
    end
end

function drawGame()
    love.graphics.clear(0.1, 0.1, 0.1)
    drawBackground()

    if player.flashTimer > 0 and math.floor(player.flashTimer * 10) % 2 == 0 then
        love.graphics.setColor(1, 1, 0)
    else
        love.graphics.setColor(0, 1, 0)
    end

    love.graphics.rectangle("fill", player.x, player.y, player.size, player.size)

    for _, lane in pairs(lanes) do
        for _, car in pairs(lane.cars) do
            love.graphics.setColor(car.color)
            love.graphics.rectangle("fill", car.x, car.y, car.width, car.height)
        end
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. player.score, 10, 10)
    love.graphics.print("Lives: " .. player.lives, 10, 30)
    love.graphics.print("Level: " .. level .. " (" .. levelTheme .. ")", 10, 50)

    for _, powerUp in pairs(powerUps) do
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", powerUp.x, powerUp.y, 15)
    end

    for _, hazard in pairs(hazards) do
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.circle("fill", hazard.x, hazard.y, 15)
    end

    if paused then
        love.graphics.printf("Paused", 0, 250, 800, "center")
    end
end

function drawBackground()
    if levelTheme == "day" then
        love.graphics.setColor(0.5, 0.8, 1)
    elseif levelTheme == "night" then
        love.graphics.setColor(0.1, 0.1, 0.2)
    elseif levelTheme == "rain" then
        love.graphics.setColor(0.3, 0.4, 0.5)
    end
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 50, 800, 500)

    love.graphics.setColor(0.4, 0.4, 0.4)
    for i = 0, 4 do
        love.graphics.rectangle("fill", 0, 50 + i * 100, 800, 5)
    end
end

function drawGameOver()
    love.graphics.printf("Game Over! Score: " .. player.score, 0, 250, 800, "center")
    love.graphics.printf("Press Space to Restart", 0, 300, 800, "center")
end

function checkCollision(a, b)
    return a.x < b.x + (b.width or 30) and
           a.x + a.size > b.x and
           a.y < b.y + (b.height or 30) and
           a.y + a.size > b.y
end
