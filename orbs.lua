-- Orb definitions for the game

local Orbs = {}

-- Chinese characters for falling objects (orbs)
Orbs.CHINESE = {
    {character = "猫", meaning = "Cat", language = "chinese", color = {1, 0.5, 0}},
    {character = "犬", meaning = "Dog", language = "chinese", color = {0.5, 0.5, 0.5}},
    {character = "鳥", meaning = "Bird", language = "chinese", color = {0, 0.8, 1}},
    {character = "魚", meaning = "Fish", language = "chinese", color = {0, 0.5, 1}},
    {character = "熊", meaning = "Bear", language = "chinese", color = {0.6, 0.3, 0}},
    {character = "兔", meaning = "Rabbit", language = "chinese", color = {1, 1, 1}},
    {character = "虎", meaning = "Tiger", language = "chinese", color = {1, 0.5, 0}},
    {character = "龍", meaning = "Dragon", language = "chinese", color = {1, 0, 0}},
    {character = "馬", meaning = "Horse", language = "chinese", color = {0.5, 0.25, 0}},
    {character = "羊", meaning = "Sheep", language = "chinese", color = {0.9, 0.9, 0.9}},
    {character = "蛇", meaning = "Snake", language = "chinese", color = {0, 0.8, 0}},
    {character = "雞", meaning = "Rooster", language = "chinese", color = {1, 0.8, 0}},
    {character = "豬", meaning = "Pig", language = "chinese", color = {1, 0.7, 0.7}},
    {character = "牛", meaning = "Ox", language = "chinese", color = {0.5, 0.25, 0}},
    {character = "猴", meaning = "Monkey", language = "chinese", color = {0.6, 0.3, 0}},
    {character = "鼠", meaning = "Mouse", language = "chinese", color = {0.7, 0.7, 0.7}}
}

-- Function to get a random Chinese character orb
function Orbs.getRandomChineseCharacter()
    return Orbs.CHINESE[love.math.random(1, #Orbs.CHINESE)]
end

-- Function to create a poop orb
function Orbs.createPoopOrb()
    return {
        character = "💩",
        meaning = "Poop",
        language = "emoji",
        color = {0.5, 0.25, 0}
    }
end

return Orbs 