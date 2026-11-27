local _, NBK = ...

local Codec = {}
NBK.Codec = Codec

local ESCAPE = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }
local function quote(s)
    return '"' .. s:gsub('[%c"\\]', function(c) return ESCAPE[c] or ("\\u%04x"):format(c:byte()) end) .. '"'
end

local write
local function array(t)
    local out = {}
    for i, v in ipairs(t) do out[i] = write(v) end
    return "[" .. table.concat(out, ",") .. "]"
end
local function object(t)
    local keys, out = {}, {}
    for k in pairs(t) do keys[#keys + 1] = k end
    table.sort(keys)
    for i, k in ipairs(keys) do out[i] = quote(k) .. ":" .. write(t[k]) end
    return "{" .. table.concat(out, ",") .. "}"
end
function write(v)
    local kind = type(v)
    if kind == "string" then return quote(v)
    elseif kind == "number" then
        if v ~= v or v - v ~= 0 then return "null" end
        return ("%.14g"):format(v)
    elseif kind == "boolean" then return tostring(v)
    elseif kind ~= "table" then error("no JSON: " .. kind, 0) end

    return (v[1] ~= nil or next(v) == nil) and array(v) or object(v)
end

function Codec.ToJson(value) return write(value) end

local function utf8(c)
    local floor, char = math.floor, string.char
    if c < 0x80 then return char(c) end
    if c < 0x800 then return char(0xC0 + floor(c / 0x40), 0x80 + c % 0x40) end
    if c < 0x10000 then return char(0xE0 + floor(c / 0x1000), 0x80 + floor(c / 0x40) % 0x40, 0x80 + c % 0x40) end
    return char(0xF0 + floor(c / 0x40000), 0x80 + floor(c / 0x1000) % 0x40, 0x80 + floor(c / 0x40) % 0x40, 0x80 + c % 0x40)
end

local MAX_DEPTH = 20
local PLAIN = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
local function bad() error("no JSON", 0) end

local function readString(s, at)
    local parts = {}
    at = at + 1
    while true do
        local stop = s:find('["\\]', at) or bad()
        parts[#parts + 1] = s:sub(at, stop - 1)
        if s:sub(stop, stop) == '"' then return table.concat(parts), stop + 1 end
        local c = s:sub(stop + 1, stop + 1)
        if c == "u" then
            local code = tonumber(s:match("^%x%x%x%x", stop + 2) or bad(), 16)
            at = stop + 6
            if code >= 0xD800 and code < 0xDC00 then
                local low = tonumber(s:match("^\\u([dD][c-fC-F]%x%x)", at) or bad(), 16)
                code = 0x10000 + (code - 0xD800) * 0x400 + low - 0xDC00
                at = at + 6
            end
            parts[#parts + 1] = utf8(code)
        else
            parts[#parts + 1] = PLAIN[c] or bad()
            at = stop + 2
        end
    end
end

local WORDS = { { "true", true }, { "false", false }, { "null", nil } }
local read
local function skip(s, at) return s:match("^[ \t\r\n]*()", at) end

local function readItems(s, at, close, item)
    at = skip(s, at + 1)
    if s:sub(at, at) == close then return at + 1 end
    while true do
        at = skip(s, item(at))
        local c = s:sub(at, at)
        if c == close then return at + 1 end
        if c ~= "," then bad() end
        at = skip(s, at + 1)
    end
end

function read(s, at, depth)
    if depth > MAX_DEPTH then bad() end
    local c = s:sub(at, at)
    if c == '"' then return readString(s, at) end
    if c == "{" or c == "[" then
        local t, n = {}, 0
        local stop = readItems(s, at, c == "{" and "}" or "]", function(pos)
            local key
            if c == "{" then
                if s:sub(pos, pos) ~= '"' then bad() end
                key, pos = readString(s, pos)
                pos = skip(s, pos)
                if s:sub(pos, pos) ~= ":" then bad() end
                pos = skip(s, pos + 1)
            else
                n = n + 1
                key = n
            end
            t[key], pos = read(s, pos, depth + 1)
            return pos
        end)
        return t, stop
    end
    for _, w in ipairs(WORDS) do
        if s:sub(at, at + #w[1] - 1) == w[1] then return w[2], at + #w[1] end
    end
    local number = s:match("^%-?%d+%.?%d*[eE]?[+-]?%d*", at)
    local value = number and tonumber(number) or bad()
    return value, at + #number
end

function Codec.FromJson(s)
    if type(s) ~= "string" then return nil end
    local ok, value = pcall(function()
        local v, at = read(s, skip(s, 1), 1)
        if skip(s, at) <= #s then bad() end
        return v
    end)
    if ok then return value end
end

local DIGITS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local CHAR, VALUE = {}, {}
for i = 1, 64 do
    CHAR[i - 1] = DIGITS:sub(i, i)
    VALUE[DIGITS:byte(i)] = i - 1
end

function Codec.ToBase64(s)
    local floor, out = math.floor, {}
    for i = 1, #s, 3 do
        local a, b, c = s:byte(i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        out[#out + 1] = CHAR[floor(n / 262144)] .. CHAR[floor(n / 4096) % 64]
            .. (b and CHAR[floor(n / 64) % 64] or "=") .. (c and CHAR[n % 64] or "=")
    end
    return table.concat(out)
end

function Codec.FromBase64(s)
    if type(s) ~= "string" then return nil end
    s = s:gsub("%s", "")
    if #s % 4 ~= 0 or not s:find("^[%w+/]*=?=?$") then return nil end
    local floor, out = math.floor, {}
    for i = 1, #s, 4 do
        local a, b, c, d = s:byte(i, i + 3)
        local n = (VALUE[a] or 0) * 262144 + (VALUE[b] or 0) * 4096 + (VALUE[c] or 0) * 64 + (VALUE[d] or 0)
        local bytes = string.char(floor(n / 65536), floor(n / 256) % 256, n % 256)
        out[#out + 1] = bytes:sub(1, VALUE[d] and 3 or VALUE[c] and 2 or 1)
    end
    return table.concat(out)
end

local function deflate() return LibStub("LibDeflate") end

function Codec.Pack(value) return Codec.ToBase64((deflate():CompressZlib(write(value)))) end

function Codec.Unpack(text)
    local raw = Codec.FromBase64(text)
    if not raw then return nil end
    local Deflate = deflate()
    local ok, json = pcall(Deflate.DecompressZlib, Deflate, raw)
    return ok and json and Codec.FromJson(json) or nil
end
