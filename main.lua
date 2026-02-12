love.graphics.setDefaultFilter("nearest", "nearest")

local gameState = "menu" 
local score, lives, timer = 0, 5, 0
local highScore = 0
local isNight = false
local cycleTimer = 0
local difficulty = 1.0  -- تبدأ الصعوبة من 1.0 وتزيد تدريجياً
local gameTime = 0
local cherryCount = 0 
local objects = {}
local imgs = {}
local font_big, font_med, font_small, font_ui

function love.load()
    -- ضبط الخطوط بأحجام مناسبة للأندرويد لمنع التداخل
    font_big = love.graphics.newFont(40)      
    font_med = love.graphics.newFont(24)      
    font_small = love.graphics.newFont(18)    -- خط صغير لعناصر الواجهة الجانبية
    font_ui = love.graphics.newFont(20)       
    
    love.graphics.setFont(font_small)

    -- تحميل الصور
    imgs.player = love.graphics.newImage("glass.png")
    imgs.bgDay = love.graphics.newImage("background.png")
    imgs.bgNight = love.graphics.newImage("night_background.png")
    imgs.life = love.graphics.newImage("life.png")
    imgs.btnPlay = love.graphics.newImage("button_play.png")
    imgs.btnInfo = love.graphics.newImage("button_info.png")
    imgs.ice = love.graphics.newImage("ice.png")
    imgs.cherry = love.graphics.newImage("cherry.png")
    imgs.coffee = love.graphics.newImage("coffee.png")

    SW = love.graphics.getWidth()
    SH = love.graphics.getHeight()

    player = { x = SW/2, y = SH - 150, speed = 800, w = imgs.player:getWidth(), h = imgs.player:getHeight() }

    loadHighScore() -- تحميل النتيجة المسجلة من ملف txt
end

function loadHighScore()
    if love.filesystem.getInfo("highscore.txt") then
        local content = love.filesystem.read("highscore.txt")
        highScore = tonumber(content) or 0
    end
end

function saveScore()
    -- مقارنة النتيجة الحالية مع أعلى نتيجة وحفظها إذا تم تخطيها
    if score > highScore then
        highScore = score
        love.filesystem.write("highscore.txt", tostring(highScore))
    end
end

function drawBackground()
    local bg = isNight and imgs.bgNight or imgs.bgDay
    love.graphics.draw(bg, 0, 0, 0, SW / bg:getWidth(), SH / bg:getHeight())
end

function love.draw()
    drawBackground()

    if gameState == "menu" then
        local btnW = imgs.btnPlay:getWidth()
        local btnX = (SW - btnW) / 2
        love.graphics.draw(imgs.btnPlay, btnX, SH * 0.45)
        love.graphics.draw(imgs.btnInfo, btnX, SH * 0.60) 
        
        -- عرض أعلى سكور في القائمة الرئيسية
        love.graphics.setFont(font_big)
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.printf("BEST SCORE", 0, SH * 0.18, SW, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(highScore, 0, SH * 0.25, SW, "center")

    elseif gameState == "info" then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 10, SH * 0.20, SW - 20, SH * 0.6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Developed by: Mamdouh Ibrahim Qasim", 0, SH * 0.45, SW, "center")
        love.graphics.printf("TAP ANYWHERE TO GO BACK", 0, SH * 0.72, SW, "center")

    elseif gameState == "play" then
        -- شريط UI علوي شفاف
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, SW, 110)
        love.graphics.setColor(1, 1, 1)
        
        -- 1. القلوب: صغيرة وفي أقصى اليسار
        local heartSpacing = 35
        for i = 1, 5 do
            local heartX = 20 + (i-1) * heartSpacing
            if i <= lives then
                love.graphics.draw(imgs.life, heartX, 15, 0, 1.3, 1.3)
            else
                love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
                love.graphics.rectangle("fill", heartX + 5, 20, 20, 20)
                love.graphics.setColor(1, 1, 1)
            end
        end
        
        -- 2. السكور: (الحالي / الأعلى) بخط صغير على اليسار
        love.graphics.setFont(font_small)
        love.graphics.print("SCORE: " .. score .. " / " .. highScore, 20, 50)
        
        -- 3. الكرز: تحت السكور مباشرة
        love.graphics.print("CHERRY: " .. cherryCount .. "/4", 20, 75)
        
        -- 4. NIGHT MODE: يظهر في أقصى اليمين
        if isNight then
            love.graphics.setColor(1, 0.2, 0.2)
            love.graphics.printf("NIGHT MODE", 0, 15, SW - 20, "right")
            love.graphics.setColor(1, 1, 1)
        end
        
        -- رسم اللاعب والكائنات
        love.graphics.draw(imgs.player, player.x - player.w/2, player.y)
        for _, o in ipairs(objects) do
            love.graphics.draw(o.img, o.x, o.y)
        end
    end
end

function love.update(dt)
    if love.mouse.isDown(1) then
        local mx, my = love.mouse.getPosition()
        local btnW = imgs.btnPlay:getWidth()
        local btnX = (SW - btnW) / 2

        if gameState == "menu" then
            if mx > btnX and mx < btnX + btnW and my > SH*0.45 and my < SH*0.45 + imgs.btnPlay:getHeight() then
               resetGame()
               gameState = "play"
            elseif mx > btnX and mx < btnX + btnW and my > SH*0.60 and my < SH*0.60 + imgs.btnInfo:getHeight() then
               gameState = "info"
            end
        elseif gameState == "info" then
            gameState = "menu"
        end
    end

    if gameState == "play" then
        updateGame(dt)
    end
end

function updateGame(dt)
    gameTime = gameTime + dt
    
    -- نظام الصعوبة التدريجية: تزيد بنسبة 0.001 كل ثانية
    -- تم وضع حد أقصى للصعوبة عند 1.8 لضمان عدم خروج السرعة عن السيطرة
    difficulty = math.min(1 + (gameTime * 0.001), 1.8) 
    
    cycleTimer = cycleTimer + dt
    if cycleTimer > 15 then 
        isNight = not isNight; 
        cycleTimer = 0 
    end

    -- تحريك اللاعب
    if love.mouse.isDown(1) then
        local mx = love.mouse.getX()
        if mx < SW/2 then 
            player.x = player.x - player.speed * dt
        else 
            player.x = player.x + player.speed * dt 
        end
    end
    player.x = math.max(player.w/2, math.min(SW - player.w/2, player.x))

    -- إنشاء الأجسام بناءً على الصعوبة المتوازنة
    local baseChance = isNight and 0.08 or 0.04
    local spawnChance = baseChance * difficulty
    if math.random() < math.min(spawnChance, 0.15) then 
        spawnObject() 
    end

    for i = #objects, 1, -1 do
        local o = objects[i]
        -- السرعة تزيد بنعومة مع مرور الوقت
        o.y = o.y + (o.speed * difficulty) * dt 

        if checkCollision(o, player) then
            if o.type == "coffee" then 
                score = math.max(0, score - 5)
            elseif o.type == "cherry" then
                score = score + o.points
                cherryCount = cherryCount + 1
                if cherryCount >= 4 then
                    lives = math.min(lives + 1, 5)
                    cherryCount = 0
                end
            else 
                score = score + o.points 
            end
            table.remove(objects, i)
        elseif o.y > SH then
            if not isNight and o.type == "ice" then
                lives = lives - 1
                if lives <= 0 then 
                    saveScore() -- حفظ ومقارنة النتيجة عند الخسارة
                    gameState = "menu" 
                end
            end
            table.remove(objects, i)
        end
    end
end

function spawnObject()
    local o = { x = math.random(40, SW-60), y = -60 }
    if isNight then
        o.type = "coffee"; o.img = imgs.coffee; o.speed = 500; o.points = -5
    else
        local r = math.random()
        if r < 0.1 then 
            o.type = "cherry"; o.img = imgs.cherry; o.speed = 420; o.points = 25
        elseif r < 0.4 then 
            o.type = "coffee"; o.img = imgs.coffee; o.speed = 380; o.points = -5
        else 
            o.type = "ice"; o.img = imgs.ice; o.speed = 320; o.points = 5 
        end
    end
    o.w, o.h = o.img:getWidth(), o.img:getHeight()
    table.insert(objects, o)
end

function checkCollision(o, p)
    return o.x < p.x + p.w/2 and o.x + o.w > p.x - p.w/2 and o.y < p.y + p.h and o.y + o.h > p.y
end

function resetGame()
    score, lives, cycleTimer, isNight, difficulty, objects, cherryCount, gameTime = 0, 5, 0, false, 1.0, {}, 0, 0
    loadHighScore()
end