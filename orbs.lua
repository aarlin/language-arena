-- Orbs data and functions
local logger = require("logger")

local Orbs = {}

-- List of Chinese characters with their meanings
local chineseCharacters = {
    {
        character = "爱",
        meaning = "Love",
        characterType = "chinese"
    },
    {
        character = "家",
        meaning = "Home/Family",
        characterType = "chinese"
    },
    {
        character = "好",
        meaning = "Good",
        characterType = "chinese"
    },
    {
        character = "人",
        meaning = "Person",
        characterType = "chinese"
    },
    {
        character = "大",
        meaning = "Big",
        characterType = "chinese"
    },
    {
        character = "小",
        meaning = "Small",
        characterType = "chinese"
    },
    {
        character = "中",
        meaning = "Middle/China",
        characterType = "chinese"
    },
    {
        character = "国",
        meaning = "Country",
        characterType = "chinese"
    },
    {
        character = "我",
        meaning = "I/Me",
        characterType = "chinese"
    },
    {
        character = "你",
        meaning = "You",
        characterType = "chinese"
    }
}

-- Function to get a random Chinese character
function Orbs.getRandomChineseCharacter()
    local index = love.math.random(1, #chineseCharacters)
    return chineseCharacters[index]
end

-- Function to create a poop orb
function Orbs.createPoopOrb()
    return {
        character = "💩",
        meaning = "Poop",
        characterType = "poop"
    }
end

return Orbs 