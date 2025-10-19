-- Tyre Wear Configuration File

TyreWearConfig = {
    -- Core Settings
    MAX_TYRE_HEALTH = 100.0,
    DEGRADATION_RATE = 0.000009, -- ~30 hours of driving at 100kph
    
    -- Feature Toggles
    ENABLE_DIFFERENTIAL_WEAR = true, -- Front/rear wear based on drivetrain
    ENABLE_OFFROAD_WEAR = true,
    ENABLE_TYRE_REPAIR = true,
    
    -- Multipliers
    OFFROAD_WEAR_MULTIPLIER = 2.5,
    
    -- Repair Areas Configuration
    REPAIR_AREAS = {
        {
            name = "Autopia parkway",
            coords = vector3(-439.89, -2179.19, 9.84),
            radius = 5.0,
            blip = {
                enabled = true,
                sprite = 488, -- Tire icon
                color = 5, -- Yellow
                scale = 0.8
            }
        },
        {
            name = "Algonquin Blvd",
            coords = vector3(1372.23, 3618.15, 34.4),
            radius = 5.0,
            blip = {
                enabled = true,
                sprite = 488, -- Tire icon
                color = 5, -- Yellow
                scale = 0.8
            }
        },
          {
            name = "Plaice Pl",
            coords = vector3(-229.45, -2657.4, 5.51),
            radius = 5.0,
            blip = {
                enabled = true,
                sprite = 488, -- Tire icon
                color = 5, -- Yellow
                scale = 0.8
            }
        },
        {
            name = "Paleto Blvd",
            coords = vector3(-79.37, 6421.06, 31.0),
            radius = 5.0,
            blip = {
                enabled = true,
                sprite = 488, -- Tire icon
                color = 5, -- Yellow
                scale = 0.8
            }
        },
        {
            name = "Power Street",
            coords = vector3(-30.05, -1090.64, 25.94),
            radius = 5.0,
            blip = {
                enabled = true,
                sprite = 488, -- Tire icon
                color = 5, -- Yellow
                scale = 0.8
            }
        },
        {
            name = "San Andreas Ave",
            coords = vector3(819.8, -821.08, 25.7),
            radius = 5.0,
            blip = {
                enabled = true,
                sprite = 488, -- Tire icon
                color = 5, -- Yellow
                scale = 0.8
            }
        },
        {
            name = "Elgin Avennue",
            coords = vector3(535.89, -182.24, 53.86),
            radius = 5.0,
            blip = {
                enabled = true,
                sprite = 488,
                color = 5,
                scale = 0.8
            }
        }
    },
    
    -- Repair Area Settings
    REPAIR_COST = 500, -- Set to 0 for free repairs, or nil to disable cost
    REPAIR_TIME = 5000, -- Time in milliseconds (5 seconds)
    SHOW_REPAIR_BLIPS = true,
    REPAIR_PROMPT_KEY = 38, -- E key (https://docs.fivem.net/docs/game-references/controls/)
    
    -- Prompt Text
    REPAIR_PROMPT_TEXT = "Press ~INPUT_CONTEXT~ to change tyres",
    REPAIR_IN_PROGRESS_TEXT = "Changing tyres...",
    REPAIR_COMPLETE_TEXT = "Tyres changed successfully!",
    REPAIR_INSUFFICIENT_FUNDS_TEXT = "Insufficient funds for tyre change!"
}

