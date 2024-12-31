enum MsType {
    Bool = 1,
    Int = 2,
    Float = 3,

    String = 5,

    Vec2 = 9,
    Vec3 = 0xA,

    Int2 = 0xE,
    Int3 = 0xF,

    // Are these always the same?
    TextArray = 0x227,

    IntArray = 0x2e7,
    // IntArray = 0x467,
    TextArrayByInt = 0x4A7,
    TextArrayByText = 0x6A7,
    IntArrayByText = 0xE27,
    TextArrayArrayByText = 0x1E47,
    IntArrayByIntArrayByText = 0xD4A7,

    RealArray = 0x24A7,
}

string x = """
0x9 = Vec2
0xA = Vec3

0xE = Int2
0xF = Int3

0x227 = net Text[]
0x2e7 = Integer[]

0x467 = Integer[]
0x4a7 = Text[Integer]

0x6a7 = Text[Text]

0xd647 = (net) UIModules_Common::ComponentModeLibsUIModules_K_ModuleProperties[Text]

Net_TMGame_ScoresTable_CustomTimes
0xe27 = net Integer[Text]

0x1e47 = Text[][Text]

// Net_TMGame_ScoresTable_Trophies
0xd4a7 = Integer[Integer][Text]

0xd787
0xd727 = K_Net_GhostData[]

for structs:
buffer at 0x78 (to kv paris?)
    - 0x0: ix
    - 0x10: string (login or something? key?)
      0x20: ff
""";
