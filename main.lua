function love.load()
    love.window.setMode(800, 600)
    font = love.graphics.newFont(20)
    menuFont = love.graphics.newFont(30)
    love.graphics.setFont(font)
    state = "menu"
    highScores = loadHighScores()
    achievements = {}
    unlockedAchievements = {}
    resetGame()
    createSounds()
end

function loadHighScores()
    local scores = {0, 0, 0, 0, 0}
    return scores
end

function saveHighScores()
end

function createSounds()
    beepSound = love.audio.newSource(love.sound.newSoundData(0.1, 44100, 16, 1), "static")
    beepSound:setPitch(2)
    honkSound = love.audio.newSource(love.sound.newSoundData(0.2, 44100, 16, 1), "static")
    gameOverSound = love.audio.newSource(love.sound.newSoundData(0.3, 44100, 16, 1), "static")
    levelUpSound = love.audio.newSource(love.sound.newSoundData(0.2, 44100, 16, 1), "static")
    powerUpSound = love.audio.newSource(love.sound.newSoundData(0.2, 44100, 16, 1), "static")
    sprintSound = love.audio.newSource(love.sound.newSoundData(0.2, 44100, 16, 1), "static")
end

function resetGame()
    player = {x = 400, y = 570, size = 30, score = 0, lives = 3, invincible = false, speed = 200, flashTimer = 0, stamina = 100, maxStamina = 100, sprinting = false}
    lanes = {}
    createLanes()
    powerUps = {}
    hazards = {}
    addRandomPowerUp()
    addRandomHazard()
    weather = "clear"
    weatherTimer = 0
    achievementsUnlocked = {}
    gameOver = false
    paused = false
    flashTimer = 0
    screenShake = 0
    level = 1
    levelTheme = "day"
    updateAchievements()
end

function createLanes()
    for i = 1, 5 do
        table.insert(lanes, {y = i * 100 + 50, speed = math.random(100, 300), direction = math.random(0, 1) == 0 and -1 or 1, cars = {}, carChangeTimer = 0})
    end
    for _, lane in pairs(lanes) do
        for j = 1, math.random(2, 4) do
            local carWidth = math.random(50, 100)
            local carX = lane.direction == 1 and math.random(-800, -100) or math.random(800, 1600)
            table.insert(lane.cars, {x = carX, y = lane.y, width = carWidth, height = 30, color = {math.random(), math.random(), math.random()}, type = "normal"})
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
        updateWeather(dt)
        updateAchievements()

        if player.y < 0 then
            levelUp()
        end

        if player.flashTimer > 0 then
            player.flashTimer = player.flashTimer - dt
        end

        if player.sprinting then
            player.stamina = player.stamina - 50 * dt
            if player.stamina <= 0 then
                player.sprinting = false
            end
        else
            player.stamina = math.min(player.stamina + 20 * dt, player.maxStamina)
        end
    end
end

function movePlayer(dt)
    local speed = player.sprinting and player.speed * 1.5 or player.speed
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
    if love.keyboard.isDown('space') and player.stamina > 0 then
        player.sprinting = true
        love.audio.play(sprintSound)
    else
        player.sprinting = false
    end
end

function updateLanes(dt)
    for _, lane in pairs(lanes) do
        lane.carChangeTimer = lane.carChangeTimer - dt
        if lane.carChangeTimer <= 0 then
            for _, car in pairs(lane.cars) do
                if math.random() < 0.2 then
                    car.type = car.type == "normal" and "aggressive" or "normal"
                end
            end
            lane.carChangeTimer = math.random(5, 10)
        end
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
    if type == "shield" then
        player.invincible = true
        player.flashTimer = 2
    elseif type == "boost" then
        player.speed = player.speed * 1.5
    elseif type == "points" then
        player.score = player.score + 50
    elseif type == "timefreeze" then
    end
end

function updateHazards(dt)
    for i, hazard in ipairs(hazards) do
        if checkCollision(player, hazard) then
            if hazard.type == "pothole" then
                player.speed = player.speed * 0.5
            elseif hazard.type == "oil" then
                player.speed = player.speed * 0.3
                player.stamina = player.stamina - 20
            end
            table.remove(hazards, i)
        end
    end
end

function updateWeather(dt)
    weatherTimer = weatherTimer - dt
    if weatherTimer <= 0 then
        weather = math.random() < 0.5 and "clear" or (math.random() < 0.5 and "rain" or "fog")
        weatherTimer = math.random(20, 40)
    end

    if weather == "rain" then
        love.graphics.setColor(0.7, 0.7, 1)
        for i = 1, 100 do
            local x = math.random(0, 800)
            local y = math.random(0, 600)
            love.graphics.line(x, y, x + math.random(-5, 5), y + math.random(10, 20))
        end
    elseif weather == "fog" then
        love.graphics.setColor(0.9, 0.9, 0.9, 0.5)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
    end
end

function updateAchievements()
    local achievementList = {
        {name = "Road Runner", condition = function() return player.score >= 100 end},
        {name = "Survivor", condition = function() return player.lives == 3 end},
        {name = "Speed Demon", condition = function() return player.speed > 300 end},
    }

    for _, achievement in pairs(achievementList) do
        if achievement.condition() and not achievementsUnlocked[achievement.name] then
            achievementsUnlocked[achievement.name] = true
            table.insert(achievements, achievement.name)
        end
    end
end

function levelUp()
    level = level + 1
    player.score = player.score + 100
    player.y = 570
    createLanes()
    if level % 5 == 0 then
        updateLevelTheme()
    end
    love.audio.play(levelUpSound)
end

function updateLevelTheme()
    if level % 5 == 0 then
        if levelTheme == "day" then
            levelTheme = "night"
        elseif levelTheme == "night" then
            levelTheme = "rain"
        elseif levelTheme == "rain" then
            levelTheme = "fog"
        elseif levelTheme == "fog" then
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
    elseif levelTheme == "fog" then
        love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
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

function addRandomPowerUp()
    local types = {"shield", "boost", "points", "timefreeze"}
    local type = types[math.random(#types)]
    table.insert(powerUps, {x = math.random(30, 770), y = math.random(100, 570), type = type})
end

function addRandomHazard()
    local types = {"pothole", "oil"}
    local type = types[math.random(#types)]
    table.insert(hazards, {x = math.random(30, 770), y = math.random(100, 570), type = type})
end
