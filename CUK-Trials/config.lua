-- config.lua
Config = {}

Config.Trials = {
    [1] = {
        name     = "Sandy Airfield",
        enabled  = true,
        radius   = 24.0,
        blipSprite = 315,
        blipColor  = 5,
        start    = vector3(1718.0, 3254.5, 40.5),
        checkpoints = {
            vector3(1472.0715, 3188.8779, 39.7291),
            vector3(1073.3435, 3043.9104, 40.5283),
            vector3(1337.2256, 3082.1672, 39.8508),
            vector3(1598.4370, 3195.6440, 39.8470)
        }
    },
    [2] = {
        name     = "Airport Drag Race",
        enabled  = true,
        radius   = 24.0,
        blipSprite = 315,
        blipColor  = 5,
        start    = vector3(-1355.0, -2245.0, 13.5),
        checkpoints = {
            vector3(-1455.0, -2419.0, 13.5),
            vector3(-1555.0, -2593.0, 13.5)
        }
    },
    [3] = {
        name     = "O'Neil Road",
        enabled  = true,
        radius   = 24.0,
        blipSprite = 315,
        blipColor  = 5,
        start    = vector3(2400.1382, 5151.0801, 46.9285),
        checkpoints = {
            vector3(2600.3806, 5101.9668, 44.1726),
            vector3(2768.2275, 4420.4233, 48.0649),
            vector3(2510.9192, 4134.8555, 37.9959),
            vector3(2483.4768, 4503.8516, 34.1821),
            vector3(2141.4436, 4753.4580, 40.6244),
            vector3(1846.9159, 4579.8159, 35.6108),
            vector3(1692.0725, 4721.8071, 41.7316),
            vector3(1801.5488, 5050.4375, 58.3084),
            vector3(1967.2104, 5138.5728, 42.5401),
            vector3(2302.9138, 5190.9360, 59.2534),
            vector3(2381.9133, 5217.8511, 55.8796),
            vector3(2403.7300, 5151.2573, 46.7974),
            vector3(2540.9971, 5089.4922, 43.5812)
        }
    },
    [4] = {
        name     = "Over the Top",
        enabled  = true,
        radius   = 24.0,
        blipSprite = 315,
        blipColor  = 5,
        start    = vector3(1178.1985, -2573.3577, 34.8973),
        checkpoints = {
            vector3(1346.9572, -2582.7239, 47.9459),
            vector3(1531.6864, -2571.3789, 53.0571),
            vector3(1656.5781, -2503.1436, 78.2562),
            vector3(1653.5034, -2386.2979, 94.8075),
            vector3(1651.2596, -2213.8870, 109.0045), 
            vector3(1715.4561, -2049.4941, 107.7310), 
            vector3(1751.0236, -1876.6288, 116.5088),
            vector3(1734.2050, -1755.0023, 113.0107), 
            vector3(1794.5992, -1591.4960, 116.1253),
            vector3(1820.7549, -1449.1586, 121.2188), 
            vector3(1909.2003, -1324.2413, 133.9068), 
            vector3(1940.3629, -1097.6450, 96.4702),
            vector3(1972.4012, -924.4039, 78.5570),
            vector3(1832.9508, -1071.9407, 79.1539),
            vector3(1651.6014, -1334.7135, 82.9846),
            vector3(1458.6472, -1510.4987, 63.4533),
            vector3(1313.5192, -1549.0616, 49.1035)
        }
    },
    [5] = {
        name     = "Vinewood Bowl",
        enabled  = true,
        radius   = 24.0,
        blipSprite = 315,
        blipColor  = 5,
        start    = vector3(710.3251, 622.5551, 128.2398),
        checkpoints = {
            vector3(1024.4368, 494.6828, 96.1300),
            vector3(1140.8284, 662.7961, 122.4556),
            vector3(1049.8397, 724.5434, 156.8524),
            vector3(954.9582, 823.6811, 197.3171),
            vector3(833.7482, 971.9541, 239.9411), 
            vector3(473.4324, 872.1322, 197.4613), 
            vector3(288.5445, 836.7230, 191.7222),
            vector3(113.8687, 730.8050, 208.7480), 
            vector3(-101.6796, 612.0336, 207.5748),
            vector3(-318.5784, 992.4427, 232.7029), 
            vector3(176.3327, 916.2803, 208.3232), 
            vector3(309.4906, 1003.9328, 209.8645),
            vector3(469.4000, 872.4069, 197.4653),
            vector3(881.8857, 986.7014, 238.5698),
            vector3(977.2272, 644.5900, 164.0875),
            vector3(1155.4371, 724.5887, 139.8257),
            vector3(1025.2395, 495.6943, 96.1089),
            vector3(659.8735, 652.9045, 128.2375)
        }
    },
    [6] = {
        name     = "Airport Circuit",
        enabled  = true,
        radius   = 24.0,
        blipSprite = 315,
        blipColor  = 5,
        start    = vector3(-1483.8513, -2466.4463, 13.2373),
        checkpoints = {
            vector3(-1680.8256, -2878.8699, 13.2351),
            vector3(-1470.9576, -3065.8904, 13.2450),
            vector3(-1208.2522, -3304.4534, 13.2312),
            vector3(-1042.4713, -3443.3386, 13.2375),
            vector3(-873.1010,  -3418.6194, 13.2361),
            vector3(-830.0990,  -3206.4260, 13.2369),
            vector3(-1018.3535, -3061.9873, 13.2375),
            vector3(-1414.3126, -2730.6306, 13.2376),
            vector3(-1208.3099, -2401.0974, 13.2387),
            vector3(-1119.1400, -2341.2305, 13.2362),
            vector3(-1266.2938, -2207.6152, 13.2372),
            vector3(-1483.8513, -2466.4463, 13.2373)
        }
    },
   [7] = {
        name       = "Mission Row Survival",
        enabled    = true,
        isSurvival = true,
        radius     = 5.0,
        blipSprite = 433,
        blipColor  = 1,
        start      = vector3(400.9550, -1000.6096, 28.7996), -- Mission Row PD
        checkpoints = {}
    },
    [8] = {
        name       = "Sandy Shores Survival",
        enabled    = true,
        isSurvival = true,
        radius     = 5.0,
        blipSprite = 433,
        blipColor  = 1,
        start      = vector3(1860.2522, 3668.1748, 33.3411), -- Sandy Shores Sheriff
        checkpoints = {}
    },
    [9] = {
        name       = "Military Base Survival",
        enabled    = true,
        isSurvival = true,
        radius     = 6.0,
        blipSprite = 433,
        blipColor  = 1,
        start      = vector3(-2342.3721, 3418.6885, 28.8896), -- Fort Zancudo Entrance
        checkpoints = {}
    },
    [10] = {
        name     = "Stab City",
        enabled  = true,
        radius   = 24.0,
        blipSprite = 315,
        blipColor  = 5,
        start    = vector3(189.5607, 3395.3032, 37.6479),
        checkpoints = {
            vector3(71.1117, 3586.0212, 39.3582),
            vector3(-223.1476, 3856.3494, 38.7880),
            vector3(-244.1755, 4063.9749, 35.5181),
            vector3(-54.8303, 4402.0317, 55.9127),
            vector3(201.4598, 4442.5386, 71.6541),
            vector3(458.5135, 4362.7559, 62.3263),
            vector3(785.6384, 4264.9688, 56.0036),
            vector3(858.1647, 4296.7441, 50.7078),
            vector3(1086.3335, 4436.7109, 60.6000),
            vector3(1549.8192, 4563.5317, 50.0401),
            vector3(2133.5554, 4749.7817, 40.7893),
            vector3(2427.0823, 4616.7627, 36.4873) -- Finish
        }
    },
    [11] = {
        name     = "Chiliad Ascension",
        enabled  = true,
        radius   = 24.0,
        blipSprite = 315,
        forcedVehicle = "sanchez", 
        blipColor  = 5,
        start    = vector3(2510.4734, 5169.9824, 66.8857),
        checkpoints = {
            vector3(491.2883, 5589.4873, 793.6509) -- Too of chiliad Finish
        }
    }
}