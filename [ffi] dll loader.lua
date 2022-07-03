-- Note:
-- dlls are placed under 'nix/dlls' create folder there, if you're not capable to get it work please stop playing.

ffi.cdef([[
    uint32_t GetModuleHandleA(const char* pModuleName);
    uint32_t GetModuleFileNameA(uint32_t hModule, char* lpFilename, uint32_t nSize);

    typedef struct
    {
        uint32_t dwFileAttributes;
        uint32_t ftCreationTime[2];
        uint32_t ftLastAccessTime[2];
        uint32_t ftLastWriteTime[2];
        uint32_t nFileSizeHigh;
        uint32_t nFileSizeLow;
        uint32_t dwReserved0;
        uint32_t dwReserved1;
        char cFileName[260];
        char cAlternateFileName[14];
    } WIN32_FIND_DATA;

    uint32_t FindFirstFileA(const char* lpFileName, WIN32_FIND_DATA* lpFindFileData);
    bool FindNextFileA(uint32_t hFindFile, WIN32_FIND_DATA* lpFindFileData);
    bool FindClose(uint32_t hFindFile);
]])

local function GetModuleFileNameA(module)
    local name = ffi.new("char[260]")
    return ffi.string(name, ffi.C.GetModuleFileNameA(0, name, 260))
end

local function GetPath(path)
    local pathend = string.len(path) - string.find(string.reverse(path), "\\")

    return string.sub(path, 1, pathend)
end

local function GetFiles(path)
    local files = {}

    local m_Data   = ffi.new("WIN32_FIND_DATA")
    local m_Find   = ffi.C.FindFirstFileA(path .. "\\*", m_Data);
    if (m_Find ~= 0) then

        while (ffi.C.FindNextFileA(m_Find, m_Data)) do
            if (ffi.string(m_Data.cFileName, 1) ~= ".") then
                table.insert(files, ffi.string(m_Data.cFileName, 260))
            end
        end

        ffi.C.FindClose(m_Find)
    end

    return files
end

local function TableStringFilter(tbl, str)
    local newtbl = {}

    for i = 1, #tbl do
        if (string.find(tbl[i], str) ~= nil) then
            table.insert(newtbl, tbl[i])
        end
    end

    return newtbl
end

local m_DllPath     = GetPath(GetModuleFileNameA(0)) .. "\\nix\\dlls"
local m_DllFiles    = TableStringFilter(GetFiles(m_DllPath), ".dll")

if (#m_DllFiles == 0) then
    client.notify("nix/dlls - nothing found!")
    client.unload_script(client.get_script_name())
    return
end

local m_DllCombo    = ui.add_combo_box("Select:", "dll_loader_combo", m_DllFiles, 0)
local m_DllCheck    = ui.add_check_box("Load", "dll_loader_check", false)

-- Loader
ffi.cdef([[
    bool VirtualProtect(void* lpAddress, uint32_t dwSize, uint32_t flNewProtect, uint32_t* lpflOldProtect);
    uint32_t LoadLibraryA(const char* lpLibFileName);
]])

local m_OldProtect = ffi.new("uint32_t[1]")
local function VirtualProtect(address, size, newprotect)
	return ffi.C.VirtualProtect(address, size, newprotect, m_OldProtect)
end

local m_NtOpenFile = ffi.cast("uint8_t*", client.find_pattern("csgo.exe", "1B F6 45 0C 20") - 0x1)

client.register_callback("paint", function()
    if (not ui.is_visible()) then
        client.unload_script(client.get_script_name())
    end

    if (m_DllCheck:get_value()) then
        m_DllCheck:set_value(false)

        local dllname = m_DllFiles[m_DllCombo:get_value() + 1]
        if (ffi.C.GetModuleHandleA(dllname) == 0) then
            local oldvalue = m_NtOpenFile[0]

            if (VirtualProtect(m_NtOpenFile, 0x1, 0x40)) then

                m_NtOpenFile[0] = 0xEB

                ffi.C.LoadLibraryA(m_DllPath .. "\\" .. dllname)

                m_NtOpenFile[0] = oldvalue

                VirtualProtect(m_NtOpenFile, 0x1, m_OldProtect[0])
            end

            client.notify("Loaded: " .. dllname)
        else
            client.notify("This dll is already loaded!")
        end
    end
end)