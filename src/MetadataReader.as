const uint16 O_MAP_SCRIPTMD = GetOffset("CGameCtnChallenge", "ScriptMetadata");

const uint SZ_METADATA_ROW = 0x88;

const uint O_MD_NAME = 0x0;
const uint O_MD_TYPE = 0x10;
const uint O_MD_STR_VALUE = 0x28;
const uint O_MD_BUF_VALUE = 0x68;

// NetWrite
MetadataReader@ CreateMDReaderForTeam(CGameTeamProfile@ team) {
    try {
        // will throw if clientSmdPtr is null
        return MetadataReader(team);
    } catch {
        return null;
    }
}

// NetWrite, but the writing side mb? (and non alt is reading side?)
MetadataReader@ CreateAltMTReaderForTeam(CGameTeamProfile@ team) {
    try {
        auto ptr = Dev::GetOffsetUint64(team, 0x30);
        if (ptr == 0) return null;
        return MetadataReader(ptr + 0x10);
    } catch {
        return null;
    }
}

MetadataReader@ CreateMDReaderForScore(CGamePlaygroundScore@ score) {
    try {
        return MetadataReader(score);
    } catch {
        return null;
    }
}

class MetadataReader {
    uint64 bufLocation;
    uint64 ptr;
    uint32 len;
    MetadataReader(uint64 bufLocation) {
        InitFromBufLoc(bufLocation);
    }
    void InitFromBufLoc(uint64 bufLocation) {
        this.bufLocation = bufLocation;
        if (bufLocation == 0) throw("MetadataReader: bufLocation is null");
        Refresh();
    }

    void Refresh() {
        this.ptr = Dev::ReadUInt64(bufLocation);
        this.len = Dev::ReadUInt32(bufLocation + 8);
    }

    // MetadataReader(uint64 bufPtr, uint32 len) {
    //     this.bufPtr = bufPtr;
    //     this.len = len;
    // }

    MetadataReader(CGameCtnChallenge@ map) {
        if (map.ScriptMetadata is null) throw("MetadataReader: map.ScriptMetadata is null");
        auto scriptMdLoc = Dev::GetOffsetUint64(map, O_MAP_SCRIPTMD);
        InitFromBufLoc(scriptMdLoc + 0x28);
    }

    MetadataReader(CGameTeamProfile@ team) {
        // client script metadata ptr -- Might
        auto clientSmdPtr = Dev::GetOffsetUint64(team, 0x38);
        if (clientSmdPtr == 0) throw("MetadataReader: clientSmdPtr is null");
        bufLocation = clientSmdPtr + 0x10;
        InitFromBufLoc(bufLocation);
    }

    MetadataReader(CGamePlaygroundScore@ score) {
        auto clientSmdPtr = Dev::GetOffsetUint64(score, 0x38);
        if (clientSmdPtr == 0) throw("MetadataReader: clientSmdPtr is null");
        bufLocation = clientSmdPtr + 0x10;
        InitFromBufLoc(bufLocation);
    }

    MetadataReader(CGameScriptPlayer@ player) {
        auto clientSmdPtr = Dev::GetOffsetUint64(player, 0x38);
        if (clientSmdPtr == 0) throw("MetadataReader: clientSmdPtr is null");
        bufLocation = clientSmdPtr + 0x10;
        InitFromBufLoc(bufLocation);
    }

    MetadataReader(CGameScriptPlayer@ player, bool alt = false) {
        auto clientSmdPtr = alt
            ? Dev::GetOffsetUint64(player, 0x20)
            : Dev::GetOffsetUint64(player, 0x38);
        if (clientSmdPtr == 0) throw("MetadataReader: clientSmdPtr is null");
        bufLocation = clientSmdPtr + 0x10;
        InitFromBufLoc(bufLocation);
    }

    // void InitFromScriptMetadata(CScriptTraitsMetadata@ md) {
    //     this.bufPtr = Dev::GetOffsetUint64(md, 0x28);
    //     this.len = Dev::GetOffsetUint32(md, 0x30);
    // }

    MetadataRow[]@ GetAllMetadataEntries() {
        MetadataRow[] rows;
        rows.Resize(len);
        for (uint i = 0; i < len; i++) {
            rows[i].ptr = ptr + i * SZ_METADATA_ROW;
        }
        return rows;
    }
}

class MetadataRow {
    MetadataRow() {}

    uint64 ptr;
    MetadataRow(uint64 ptr) {
        this.ptr = ptr;
    }

    void _check() {
        if (ptr == 0) throw("MetadataRow: ptr is null");
    }

    uint64 get_Ptr() {
        return ptr;
    }

    string get_Name() {
        _check();
        // name offset is at 0
        return ReadStringAt(ptr);
    }

    uint get_TypeRaw() {
        _check();
        return Dev::ReadUInt32(ptr + 0x10);
    }

    MsType get_Type() {
        return MsType(TypeRaw);
    }

    void _check_type(MsType ty) {
        if (Type != ty) throw("MetadataRow: type mismatch | expected: " + tostring(ty) + " | got: " + tostring(Type));
    }

    string get_ValueStr() {
        _check_type(MsType::String);
        return ReadStringAt(ptr + 0x28);
    }

    bool get_ValueBool() {
        _check_type(MsType::Bool);
        return Dev::ReadInt32(ptr + 0x18) >= 1;
    }

    int get_ValueInt() {
        _check_type(MsType::Int);
        return Dev::ReadInt32(ptr + 0x18);
    }

    uint get_ValueUInt() {
        _check_type(MsType::Int);
        return Dev::ReadUInt32(ptr + 0x18);
    }

    float get_ValueFloat() {
        _check_type(MsType::Float);
        return Dev::ReadFloat(ptr + 0x18);
    }

    vec2 get_ValueVec2() {
        _check_type(MsType::Vec2);
        return Dev::ReadVec2(ptr + 0x18);
    }

    vec3 get_ValueVec3() {
        _check_type(MsType::Vec3);
        return Dev::ReadVec3(ptr + 0x18);
    }

    int2 get_ValueInt2() {
        _check_type(MsType::Int2);
        return Dev::ReadInt2(ptr + 0x18);
    }

    int3 get_ValueInt3() {
        _check_type(MsType::Int3);
        return Dev::ReadInt3(ptr + 0x18);
    }

    int[]@ get_ValueIntArray() {
        _check_type(MsType::IntArray);
        auto el0Ptr = Dev::ReadUInt64(ptr + 0x68);
        auto bufLen = Dev::ReadUInt32(ptr + 0x70);
        if (bufLen == 0 || el0Ptr == 0) return {};
        int[] arr;
        arr.Resize(bufLen);
        uint64 elPtr;
        for (uint i = 0; i < bufLen; i++) {
            elPtr = Dev::ReadUInt64(el0Ptr + 8 + i * 0x10);
            arr[i] = Dev::ReadInt32(elPtr);
        }
        return arr;
    }

    KV[]@ get_ValueTextArrayByText() {
        _check_type(MsType::TextArrayByText);
        auto el0Ptr = Dev::ReadUInt64(ptr + 0x68);
        auto bufLen = Dev::ReadUInt32(ptr + 0x70);
        if (bufLen == 0 || el0Ptr == 0) return {};
        KV[] arr;
        arr.Resize(bufLen);
        uint64 kvPtr, keyPtr, elPtr;
        for (uint i = 0; i < bufLen; i++) {
            kvPtr = el0Ptr + i * 0x10;
            keyPtr = Dev::ReadUInt64(kvPtr);
            elPtr = Dev::ReadUInt64(kvPtr + 0x8);
            arr[i].Set(ReadStringAt(keyPtr + 0x10), ReadStringAt(elPtr + 0x10));
        }
        return arr;
    }

    string get_ValueToString() {
        switch (Type) {
            case MsType::String: return ValueStr;
            case MsType::Int: return tostring(ValueInt);
            case MsType::Float: return tostring(ValueFloat);
            case MsType::Bool: return tostring(ValueBool);
            case MsType::Vec2: return ValueVec2.ToString();
            case MsType::Vec3: return ValueVec3.ToString();
            case MsType::Int2: return ValueInt2.ToString();
            case MsType::Int3: return ValueInt3.ToString();
            case MsType::IntArray: return Json::Write(ValueIntArray.ToJson());
            case MsType::TextArrayByText: return Json::Write(ValueTextArrayByText.ToJson());
            default: return "< Cannot process type: " + tostring(Type) + ">";
        }
    }

    uint get_x18() {
        return Dev::ReadUInt32(Ptr + 0x18);
    }

    uint get_x1C() {
        return Dev::ReadUInt32(Ptr + 0x1C);
    }

    uint64 get_x20() {
        return Dev::ReadUInt64(Ptr + 0x20);
    }

    uint get_x24() {
        return Dev::ReadUInt32(Ptr + 0x24);
    }

    uint get_x28() {
        return Dev::ReadUInt32(Ptr + 0x28);
    }

    uint get_x2C() {
        return Dev::ReadUInt32(Ptr + 0x2C);
    }

    // maybe time since init when last set? (but not always updated)
    uint get_x30() {
        return Dev::ReadUInt32(Ptr + 0x30);
    }

    uint get_x34() {
        return Dev::ReadUInt32(Ptr + 0x34);
    }

    uint get_x38() {
        return Dev::ReadUInt32(Ptr + 0x38);
    }

    uint get_x3C() {
        return Dev::ReadUInt32(Ptr + 0x3C);
    }

}

class KV {
    string key;
    string value;
    KV(){}
    KV(const string &in key, const string &in value) {
        this.key = key;
        this.value = value;
    }
    void Set(const string &in key, const string &in value) {
        this.key = key;
        this.value = value;
    }

    Json::Value@ ToJson() const {
        Json::Value jv = Json::Object();
        jv["key"] = key;
        jv["value"] = value;
        return jv;
    }
}


string ReadStringAt(uint64 ptr) {
    if (ptr == 0) throw("ReadStringAt: ptr is null");
    auto len = Dev::ReadUInt32(ptr + 0xC);
    if (len == 0) return "";
    // if there's a ptr
    if (Dev::ReadUInt8(ptr + 0xB) & 1 == 1) {
        return Dev::ReadCString(Dev::ReadUInt64(ptr), len);
    }
    if (len > 11) throw("ReadStringAt: name string is too long");
    return Dev::ReadCString(ptr, len);
}
