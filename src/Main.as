const string PluginName = Meta::ExecutingPlugin().Name;
const string MenuIconColor = "\\$f5d";
const string PluginIcon = Icons::Cogs;
const string MenuTitle = MenuIconColor + PluginIcon + "\\$z " + PluginName;

[Setting hidden]
bool g_WindowOpen = true;

void OnDestroyed() {
    NodPtrs::Free();
}

void Render() {
#if SIG_DEVELOPER
    if (!g_WindowOpen) return;
    UI::SetNextWindowSize(500, 300, UI::Cond::FirstUseEver);
    if (UI::Begin(MenuTitle, g_WindowOpen)) {
        UI::SeparatorText("Available Metadata");
        Render_WindowMain();
    }
    UI::End();
#endif
}

void RenderMenu() {
#if SIG_DEVELOPER
    if (UI::MenuItem(MenuTitle, "", g_WindowOpen)) {
        g_WindowOpen = !g_WindowOpen;
    }
#else
    UI::BeginDisabled();
    UI::MenuItem(MenuTitle + " (Requires Dev Mode)", "", g_WindowOpen);
    UI::EndDisabled();
#endif
}

void Render_WindowMain() {
    if (!Meta::IsDeveloperMode()) {
        UI::Text("Developer mode is required to use this plugin");
        return;
    }
    auto app = GetApp();
    Render_MetadataFor("RootMap", app.RootMap);
    auto si = cast<CTrackManiaNetworkServerInfo>(app.Network.ServerInfo);
    UI::Text("\\$i\\$aaa"+Icons::QuestionCircle+": \"Alt\" metadata is probably NetWrite declarations");
    Render_MetadataFor("si.TeamProfile0", si.TeamProfile0);
    Render_MetadataFor("si.TeamProfile1", si.TeamProfile1);
    Render_MetadataFor("si.TeamProfile2", si.TeamProfile2);
    if (app.CurrentPlayground !is null) {
        UI::SeparatorText("UI Configs");
        UI::Indent();
        Render_MetadataFor("ClientManiaAppPlayground.UI", app.Network.ClientManiaAppPlayground.UI);
        Render_MetadataFor("ClientManiaAppPlayground.ClientUI", app.Network.ClientManiaAppPlayground.ClientUI);
        UI::Unindent();

        UI::SeparatorText("Playground Players");
        UI::Indent();
        Render_MdForPlayground(app.CurrentPlayground);
        UI::Unindent();
    } else {
        UI::Text("\\$i\\$999No playground -> no players");
    }
}


void Render_MdForPlayground(CGamePlayground@ pg) {
    for (uint i = 0; i < pg.Players.Length; i++) {
        auto player = cast<CSmPlayer>(pg.Players[i]);
        if (player is null) continue;
        Render_MetadataFor(tostring(i) + ". " + player.User.Name, player);
    }
}


void Render_MetadataFor(const string &in name, CSmPlayer@ player) {
    Render_Metadata(name, MetadataReader(player.ScriptAPI));
    // try {
    //     Render_Metadata(name + " (NW?)", MetadataReader(player.ScriptAPI, true));
    // } catch {}
    Render_Metadata(name + "->Score", CreateMDReaderForScore(player.Score));
}


void Render_MetadataFor(const string &in name, CGameTeamProfile@ team) {
    if (team is null) {
        UI::Text(name + " is null");
        return;
    }
    Render_Metadata(name, CreateMDReaderForTeam(team));
    Render_Metadata(name + " Alt", CreateAltMTReaderForTeam(team));
}


void Render_MetadataFor(const string &in name, CGameCtnChallenge@ map) {
    if (map is null) {
        UI::Text(name + " is null");
        return;
    }
    Render_Metadata(name, MetadataReader(map));
}

void Render_MetadataFor(const string &in name, CGamePlaygroundUIConfig@ ui) {
    if (ui is null) {
        UI::Text(name + " is null");
        return;
    }
    Render_Metadata(name, CreateMDReaderForUI(ui));
    // Render_Metadata(name + " Alt1", CreateMDReaderForUI_Alt1(ui));
    Render_Metadata(name + " Alt", CreateMDReaderForUI_Alt2(ui));
}


void Render_Metadata(const string &in name, MetadataReader@ md) {
    if (UI::TreeNode("Metadata: " + name)) {
        if (md !is null) {
            CopiableLabeledPtr(md.bufLocation);
            UI::SeparatorText("Metadata Entries");
            auto rows = md.GetAllMetadataEntries();
            if (UI::BeginTable("mdt."+name, 4, UI::TableFlags::SizingFixedSame)) {
                UI::TableSetupColumn("Ptr & Name", UI::TableColumnFlags::WidthStretch, 0.45);
                UI::TableSetupColumn("Type Name", UI::TableColumnFlags::WidthFixed, 70);
                UI::TableSetupColumn("Type ID", UI::TableColumnFlags::WidthFixed, 70);
                UI::TableSetupColumn("Value", UI::TableColumnFlags::WidthStretch, 0.35);

                UI::ListClipper clip(rows.Length);
                while (clip.Step()) {
                    for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                        UI::PushID("MdEl" + i);
                        Render_MetadataEl_TableRow(rows[i]);
                        UI::PopID();
                    }
                }
                UI::EndTable();
            }
        } else {
            UI::Text("No metadata");
        }
        UI::TreePop();
    }
}

void Render_MetadataEl_Tree(uint i, MetadataRow@ row) {
    if (UI::TreeNode("Row " + i)) {
        UI::Text("Name: " + row.Name);
        UI::Text("Type: " + tostring(row.Type));
        UI::Text("TypeRaw: " + Text::Format("0x%x", row.TypeRaw));
        CopiableLabeledPtr(row.ptr);
        UI::TreePop();
    }
}

void Render_MetadataEl_TableRow(MetadataRow@ row) {
    UI::TableNextRow();
    UI::TableNextColumn();
    CopiableLabeledValueTooltip(Icons::Star, Text::FormatPointer(row.ptr));
    UI::SameLine();
    CopiableValue(row.Name);
    UI::TableNextColumn();
    auto tyName = tostring(row.Type);
    if (tyName.Length > 0 && tyName[0] < 0x3A) {
        tyName = "\\$i\\$fb8" + tyName;
    }
    UI::Text(tyName);
    UI::TableNextColumn();
    UI::Text(Text::Format("0x%x", row.TypeRaw));
    UI::TableNextColumn();
    CopiableValue(row.ValueToString);
    // UI::TableNextColumn();
    // UI::Text(Text::FormatPointer(row.x20));
    // UI::TableNextColumn();
    // UI::Text(tostring(row.x30));
}
