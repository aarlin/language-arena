local Orbs = {}

-- Chinese characters and their meanings
local chineseCharacters = {
    {character = "爱", meaning = "love"},
    {character = "和平", meaning = "peace"},
    {character = "快乐", meaning = "happiness"},
    {character = "希望", meaning = "hope"},
    {character = "勇气", meaning = "courage"}
}

-- Japanese characters and their meanings
local japaneseCharacters = {
    {character = "愛", meaning = "love"},
    {character = "平和", meaning = "peace"},
    {character = "幸せ", meaning = "happiness"},
    {character = "希望", meaning = "hope"},
    {character = "勇気", meaning = "courage"}
}

function Orbs.getRandomChineseCharacter()
    return chineseCharacters[love.math.random(#chineseCharacters)]
end

function Orbs.getRandomJapaneseCharacter()
    return japaneseCharacters[love.math.random(#japaneseCharacters)]
end

function Orbs.createPoopOrb()
    return {
        character = "💩",
        meaning = "poop",
        isPoop = true
    }
end

return Orbs 