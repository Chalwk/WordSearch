-- Word Search Game - Love2D
-- License: MIT
-- Copyright (c) 2025 Jericho Crosby (Chalwk)

local math_random = math.random
local math_min = math.min
local math_floor = math.floor
local table_insert = table.insert
local table_remove = table.remove

local WordBank = {}
WordBank.__index = WordBank

function WordBank.new()
    local instance = setmetatable({}, WordBank)
    instance.words = {
        easy = {
            general = {
                "LOVE", "GAME", "CODE", "FISH", "BOOK", "STAR", "MOON", "TREE", "FROG", "BIRD",
                "CAKE", "SNOW", "RAIN", "FIRE", "WIND", "SAND", "GOLD", "TIME", "LIFE", "HOME",
                "BALL", "ROAD", "SHIP", "KING", "QUEEN", "HEART", "LIGHT", "SHELL", "DREAM", "SMILE",
                "HAND", "PART", "CASE", "SHOW", "AREA", "HIGH", "CALL", "FEEL", "SEEM", "NEED",
                "WORK", "MEAN", "TELL", "WANT", "FIND", "LOOK", "GOOD", "GIVE", "COME", "YEAR",
                "TAKE", "MAKE", "HAVE", "ASK", "OLD", "PUT", "DAY", "MAN", "USE", "WAY",
                "NEW", "SEE", "GET", "SAY", "MR", "GO", "DO", "BE"
            },
            animals = {
                "CAT", "DOG", "BEAR", "LION", "FROG", "FISH", "BIRD", "WOLF", "DEER", "DUCK",
                "GOAT", "SEAL", "CRAB", "SNAIL", "WHALE", "SQUID", "EAGLE", "MOUSE", "SNAKE", "TIGER"
            },
            science = {
                "ATOM", "CELL", "GENE", "ACID", "BASE", "MATH", "DATA", "WAVE", "HEAT", "MASS",
                "FORCE", "SPACE", "EARTH", "WATER", "LIGHT", "SOUND", "PLANT", "HUMAN", "METAL", "SOLAR",
                "FACT", "FOSSIL", "WEATHER", "SCALE", "RESEARCH"
            },
            geography = {
                "MAP", "CITY", "TOWN", "LAKE", "RIVER", "HILL", "ISLAND", "BEACH", "OCEAN", "MOUNTAIN",
                "DESERT", "FOREST", "VALLEY", "COUNTRY", "CAPITAL", "BORDER", "CLIMATE", "WEATHER", "VOLCANO", "GLACIER",
                "POLAR", "ATLAS", "COMPASS"
            }
        },

        medium = {
            general = {
                "COMPUTER", "PROGRAM", "MYSTERY", "JOURNEY", "TREASURE", "VICTORY", "FREEDOM", "WONDERFUL",
                "ADVENTURE", "DISCOVER", "CREATIVE", "SOLUTION", "CHALLENGE", "PRESIDENT", "UNIVERSE", "HAPPINESS",
                "GOVERNMENT", "SERVICE", "PROBLEM", "COMPANY", "NUMBER", "SYSTEM", "BECOME", "PEOPLE",
                "PARTY", "PLACE", "HOUSE", "WORLD", "GROUP", "WOMAN", "GREAT", "LEAVE", "CHILD", "THERE", "THING",
                "THINK"
            },
            animals = {
                "ELEPHANT", "KANGAROO", "DOLPHIN", "BUTTERFLY", "CROCODILE", "ALLIGATOR", "PORCUPINE", "PLATYPUS",
                "CHAMELEON", "ARMADILLO", "WOODPECKER", "HIPPOPOTAMUS", "RHINOCEROS", "OCTOPUS", "PENGUIN", "GIRAFFE"
            },
            science = {
                "CHEMISTRY", "PHYSICS", "BIOLOGY", "ELECTRON", "QUANTUM", "GRAVITY", "ECOSYSTEM", "EVOLUTION",
                "MOLECULE", "TELESCOPE", "MICROSCOPE", "LABORATORY", "EXPERIMENT", "HYPOTHESIS", "THEORY", "OBSERVATION",
                "CHEMICAL", "WEATHER", "FOSSIL", "RETORT", "SCALE"
            },
            geography = {
                "CONTINENT", "PENINSULA", "ARCHIPELAGO", "WATERFALL", "MOUNTAIN", "LONGITUDE", "LATITUDE",
                "HORIZON", "ATLANTIC", "PACIFIC", "EQUATOR", "HEMISPHERE", "TERRITORY", "POPULATION", "RESOURCE",
                "ENVIRONMENT", "RAINFOREST", "WETLANDS", "CORAL REEFS", "FOOD WEBS", "ECOSYSTEM", "PHYSICAL", "DESERTS"
            }
        },

        hard = {
            general = {
                "EXTRAORDINARY", "IMAGINATION", "CELEBRATION", "DETERMINATION", "INVESTIGATION", "COMMUNICATION",
                "OPPORTUNITY", "RECOGNITION", "RESPONSIBILITY", "UNDERSTANDING", "ORGANIZATION", "REVOLUTIONARY"
            },
            animals = {
                "CHINCHILLA", "PLATYPUS", "ARMADILLO", "HIPPOPOTAMUS", "RHINOCEROS", "KOMODO DRAGON", "ANTEATER",
                "PORCUPINE", "WALRUS", "ALBATROSS", "FLAMINGO", "PELICAN", "CHAMELEON", "SALAMANDER", "TARANTULA"
            },
            science = {
                "ASTROPHYSICS", "BIOCHEMISTRY", "ELECTROMAGNETIC", "PHOTOSYNTHESIS", "CRYSTALLOGRAPHY",
                "THERMODYNAMICS", "PALEONTOLOGY", "ARCHAEOLOGY", "MICROBIOLOGY", "NEUROSCIENCE", "BIOINFORMATICS",
                "NANOTECHNOLOGY"
            },
            geography = {
                "CARTOGRAPHY", "TOPOGRAPHY", "METEOROLOGY", "OCEANOGRAPHY", "DEMOGRAPHY", "GEOMORPHOLOGY",
                "BIODIVERSITY", "SUSTAINABILITY", "URBANIZATION", "GLOBALIZATION", "INFRASTRUCTURE", "ENVIRONMENTAL",
                "DEFORESTATION", "LITHOSPHERE", "HYDROSPHERE", "BIOSPHERE", "ATMOSPHERE"
            }
        }
    }
    return instance
end

function WordBank:getWordList(difficulty, category, gridSize)
    local size = tonumber(gridSize) or 10
    local baseWords = self.words[difficulty][category] or self.words.medium.general

    -- Filter words based on grid size
    local filteredWords = {}
    local maxWordLength = size - 2 -- Leave some space for placement

    for _, word in ipairs(baseWords) do
        if #word <= maxWordLength then
            table_insert(filteredWords, word)
        end
    end

    -- Select appropriate number of words based on grid size
    local targetCount = math_min(#filteredWords, math_floor(size * 0.8))
    local selectedWords = {}

    for _ = 1, targetCount do
        if #filteredWords > 0 then
            local randomIndex = math_random(#filteredWords)
            table_insert(selectedWords, table_remove(filteredWords, randomIndex))
        end
    end

    return selectedWords
end

return WordBank
