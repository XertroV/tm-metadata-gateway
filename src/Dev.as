// From E++

// MARK: Dev Functions

// get an offset from class name & member name
uint16 GetOffset(const string &in className, const string &in memberName) {
    // throw exception when something goes wrong.
    auto ty = Reflection::GetType(className);
    auto memberTy = ty.GetMember(memberName);
    if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
    return memberTy.Offset;
}


// get an offset from a nod and member name
uint16 GetOffset(CMwNod@ obj, const string &in memberName) {
    if (obj is null) return 0xFFFF;
    // throw exception when something goes wrong.
    auto ty = Reflection::TypeOf(obj);
    if (ty is null) throw("could not find a type for object");
    auto memberTy = ty.GetMember(memberName);
    if (memberTy is null) throw(ty.Name + " does not have a child called " + memberName);
    if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
    return memberTy.Offset;
}

uint64[]@ Dev_GetOffsetBytes(CMwNod@ nod, uint offset, uint length) {
    auto bs = array<uint64>();
    for (uint i = 0; i < length; i += 0x8) {
        bs.InsertLast(Dev::GetOffsetUint64(nod, offset + i));
    }
    return bs;
}
uint64[]@ Dev_GetBytes(uint64 ptr, uint length) {
    auto bs = array<uint64>();
    for (uint i = 0; i < length; i += 0x8) {
        bs.InsertLast(Dev::ReadUInt64(ptr + i));
    }
    return bs;
}

void Dev_SetOffsetBytes(CMwNod@ nod, uint offset, uint64[]@ bs) {
    for (uint i = 0; i < bs.Length; i++) {
        Dev::SetOffset(nod, offset + i * 0x8, bs[i]);
    }
    return;
}

uint64[]@ Dev_ReadBytes(uint64 ptr, uint length) {
    auto bs = array<uint64>();
    for (uint i = 0; i < length; i += 0x8) {
        bs.InsertLast(Dev::ReadUInt64(ptr + i));
    }
    return bs;
}

void Dev_WriteBytes(uint64 ptr, uint64[]@ bs) {
    for (uint i = 0; i < bs.Length; i++) {
        Dev::Write(ptr + i * 0x8, bs[i]);
    }
    return;
}

// void Dev_UpdateMwSArrayCapacity(uint64 ptr, uint newSize, uint elsize, bool reduceFromFront = false) {
//     bool isExpanding = Dev::ReadUInt32(ptr + 0x8) < newSize;
//     while (Dev::ReadUInt32(ptr + 0x8) < newSize) {
//         Dev_DoubleMwSArray(ptr, elsize);
//     }
//     Dev_ReduceMwSArray(ptr, newSize, !isExpanding && reduceFromFront, int(elsize));
// }

void Dev_ReduceMwSArray(uint64 ptr, float newSizeProp) {
    if (newSizeProp > 1.0) throw("out of range+ newSizeProp");
    if (newSizeProp < 0.0) throw("out of range- newSizeProp");
    auto len = Dev::ReadUInt32(ptr + 0x8);
    uint32 newSize = uint32(float(len) * newSizeProp);
    newSize = Math::Min(len, newSize);
    Dev::Write(ptr + 0x8, newSize);
}

void Dev_ReduceMwSArray(uint64 ptr, uint newSize, bool reduceFromFront = false, int elSize = -1) {
    auto len = Dev::ReadUInt32(ptr + 0x8);
    auto capacity = Dev::ReadUInt32(ptr + 0xC);
    if (newSize > len) throw("only reduces");
    newSize = Math::Min(len, newSize);
    Dev::Write(ptr + 0x8, newSize);

    if (reduceFromFront) {
        if (elSize < 1) throw("invalid elSize for reducing from front");
        if (capacity >= len) capacity = newSize;
        Dev::Write(ptr + 0xC, capacity);
        Dev::Write(ptr, Dev::ReadUInt64(ptr) + uint64(elSize) * (len - newSize));
    }
}

// void Dev_DoubleMwSArray(uint64 ptr, uint elSize) {
//     print("Dev_DoubleMwSArray: " + Text::FormatPointer(ptr) + ", sz: " + elSize);
//     // return;
//     auto len = Dev::ReadUInt32(ptr + 0x8);
//     if (len == 0) return;
//     auto buf = Dev::ReadUInt64(ptr);
//     auto bs_len = elSize * len;
//     uint mag = 2;
//     print("len: " + len);
//     print("bs_len: " + bs_len);
//     print("ptr: " + Text::FormatPointer(ptr));
//     // Dev_SetOffsetBytes(item, 0x0, Dev_GetOffsetBytes(origItem, 0x0, ItemItemModelOffset + 0x8));
//     auto newBuf = RequestMemory(bs_len * mag);
//     for (uint loopN = 0; loopN < mag; loopN++) {
//         for (uint b = 0; b < bs_len - 1; b += 4) {
//             auto offset = b + loopN * bs_len;
//             Dev::Write(newBuf + offset, Dev::ReadUInt32(buf + b));
//         }
//     }
//     Dev::Write(ptr, newBuf);
//     Dev::Write(ptr + 0x8, len * mag);
// }


void Dev_CopyArrayStruct(uint64 sBufPtr, int sIx, uint64 dBufPtr, int dIx, uint16 elSize, uint16 nbElements = 1) {
    auto bytes = Dev_ReadBytes(sBufPtr + elSize * sIx, elSize * nbElements);
    Dev_WriteBytes(dBufPtr + elSize * dIx, bytes);
    trace("Copied bytes: " + bytes.Length + 0x8);
}

const uint64 BASE_ADDR_END = Dev::BaseAddressEnd();

const bool HAS_Z_DRIVE_WINE_INDICATOR = IO::FolderExists("Z:\\etc\\");

[Setting category="General" name="Force disable linux-wine check if you have a Z:\\ drive with an etc folder"]
bool S_ForceDisableLinuxWineCheck = false;

bool Dev_PointerLooksBad(uint64 ptr) {
    // ! testing
    if (HAS_Z_DRIVE_WINE_INDICATOR && !S_ForceDisableLinuxWineCheck) {
        // dev_trace('Has Z drive / ptr: ' + Text::FormatPointer(ptr) + ' < 0x100000000 = ' + tostring(ptr < 0x100000000));
        // dev_trace('base addr end: ' + Text::FormatPointer(BASE_ADDR_END));
        if (ptr < 0x1000000) return true;
    } else {
        // dev_trace('Windows (no Z drive or forced skip) / ptr: ' + Text::FormatPointer(ptr));
        if (ptr < 0x10000000000) return true;
    }
    // todo: something like this should fix linux (also in Dev_GetNodFromPointer)
    // if (ptr < 0x4fff08D0) return true;
    if (ptr % 8 != 0) return true;
    if (ptr == 0) return true;

    // base address is very low under wine (`0x0000000142C3D000`)
    if (!HAS_Z_DRIVE_WINE_INDICATOR || S_ForceDisableLinuxWineCheck) {
        if (ptr > BASE_ADDR_END) return true;
    }
    return false;
}


CMwNod@ Dev_GetOffsetNodSafe(CMwNod@ target, uint16 offset) {
    if (target is null) return null;
    auto ptr = Dev::GetOffsetUint64(target, offset);
    if (Dev_PointerLooksBad(ptr)) return null;
    return Dev::GetOffsetNod(target, offset);
}



namespace NodPtrs {
    void InitializeTmpPointer() {
        g_TmpPtrSpace = Dev::Allocate(0x1000);
        auto nod = CMwNod();
        uint64 tmp = Dev::GetOffsetUint64(nod, 0);
        Dev::SetOffset(nod, 0, g_TmpPtrSpace);
        @g_TmpSpaceAsNod = Dev::GetOffsetNod(nod, 0);
        Dev::SetOffset(nod, 0, tmp);
    }

    uint64 g_TmpPtrSpace = 0;
    CMwNod@ g_TmpSpaceAsNod = null;

    void Free() {
        @g_TmpSpaceAsNod = null;
        if (g_TmpPtrSpace != 0) {
            Dev::Free(g_TmpPtrSpace);
            g_TmpPtrSpace = 0;
        }
    }
}

CMwNod@ Dev_GetArbitraryNodAt(uint64 ptr) {
    if (NodPtrs::g_TmpPtrSpace == 0) {
        NodPtrs::InitializeTmpPointer();
    }
    if (ptr == 0) throw('null pointer passed');
    Dev::SetOffset(NodPtrs::g_TmpSpaceAsNod, 0, ptr);
    return Dev::GetOffsetNod(NodPtrs::g_TmpSpaceAsNod, 0);
}

uint64 Dev_GetPointerForNod(CMwNod@ nod) {
    if (NodPtrs::g_TmpPtrSpace == 0) {
        NodPtrs::InitializeTmpPointer();
    }
    if (nod is null) return 0;
    Dev::SetOffset(NodPtrs::g_TmpSpaceAsNod, 0, nod);
    return Dev::GetOffsetUint64(NodPtrs::g_TmpSpaceAsNod, 0);
}

const bool IS_MEMORY_ALWAYS_ALIGNED = true;
CMwNod@ Dev_GetNodFromPointer(uint64 ptr) {
    // if linux
    // if (ptr < 0xFFFFFFF || ptr % 8 != 0) {
    //     return null;
    // }
    // return Dev_GetArbitraryNodAt(ptr);
    // ! testing
    if (HAS_Z_DRIVE_WINE_INDICATOR && !S_ForceDisableLinuxWineCheck) {
        print("get nod from ptr: " + Text::FormatPointer(ptr));
        if (ptr < 0x1000000 || (IS_MEMORY_ALWAYS_ALIGNED && ptr % 8 != 0) || ptr >> 48 > 0) {
            print("get nod from ptr failed: " + Text::FormatPointer(ptr));
            return null;
        }
    } else if (ptr < 0xFFFFFFFF || (IS_MEMORY_ALWAYS_ALIGNED && ptr % 8 != 0) || ptr >> 48 > 0) {
        print("get nod from ptr failed: " + Text::FormatPointer(ptr));
        return null;
    }
    return Dev_GetArbitraryNodAt(ptr);
}


string UintToBytes(uint x) {
    NodPtrs::InitializeTmpPointer();
    Dev::Write(NodPtrs::g_TmpPtrSpace, x);
    return Dev::Read(NodPtrs::g_TmpPtrSpace, 4);
}

CGameItemModel@ tmp_ItemModelForMwIdSetting;

uint32 GetMwId(const string &in name) {
    if (tmp_ItemModelForMwIdSetting is null) {
        @tmp_ItemModelForMwIdSetting = CGameItemModel();
    }
    tmp_ItemModelForMwIdSetting.IdName = name;
    return tmp_ItemModelForMwIdSetting.Id.Value;
}

string GetMwIdName(uint id) {
    return MwId(id).GetName();
}
