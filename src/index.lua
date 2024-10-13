-- HexFlow Launcher Custom version 2.3.1
-- based on VitaHEX's HexFlow Launcher v0.5 + SwitchView UI v0.1.2 + jimbob4000's Retroflow v5.0.2
-- https://www.patreon.com/vitahex
-- Want to make your own version? Right-click the vpk and select "Open with... Winrar" and edit the index.lua inside.

local oneLoopTimer = Timer.new()	 --Startup speed timer, view result in menu>about
local oneLoopTime = 0
local functionTime = 0
local applistReadTime = 0
local sortTime = 0

dofile("app0:addons/threads.lua")
local working_dir = "ux0:/app"
local appversion = "2.3.1"
function System.currentDirectory(dir)
    if dir == nil then
        return working_dir --"ux0:/app"
    else
        working_dir = dir
    end
end

Network.init()
--@@ This app uses the RetroFlow cover archive: https://github.com/jimbob4000/hexflow-covers/
--@@ Sample: https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/PSVita/PCSA00029.png
--@@ For more details, check the 'DownloadCover' function.

-- Speed related settings. System.getCpuSpeed() can be used to check current status.
System.setBusSpeed(222)
System.setGpuSpeed(222)
System.setGpuXbarSpeed(166)
System.setCpuSpeed(444)

Sound.init()
local click = Sound.open("app0:/DATA/click2.ogg")
local sndMusic = click--temp
local imgCoverTmp = Graphics.loadImage("app0:/DATA/noimg.png")
local backTmp = Graphics.loadImage("app0:/DATA/noimg.png")
local btnAccept = Graphics.loadImage("app0:/DATA/x.png")	 -- Used to be btnX
local btnCancel = Graphics.loadImage("app0:/DATA/o.png")	 -- Used to be btnO
local btnT = Graphics.loadImage("app0:/DATA/t.png")
local btnS = Graphics.loadImage("app0:/DATA/s.png")
local btnD = Graphics.loadImage("app0:/DATA/d.png")
local imgArrows = Graphics.loadImage("app0:/DATA/tri_arrows.png")
local imgWifi = Graphics.loadImage("app0:/DATA/wifi.png")
local imgBattery = Graphics.loadImage("app0:/DATA/bat.png")
local imgBack = Graphics.loadImage("app0:/DATA/back_01.jpg")
local imgFloor = Graphics.loadImage("app0:/DATA/floor.png")
Graphics.setImageFilters(imgFloor, FILTER_LINEAR, FILTER_LINEAR)

local RetroflowAssetsAreLoaded = false
local SwitchviewAssetsAreLoaded = false

local CTRL_ACCEPT = SCE_CTRL_CROSS
local CTRL_CANCEL = SCE_CTRL_CIRCLE

-- Footer button margins
local btnMargin = 44	 -- Retroflow: 64. HEXFlow: ~46
local btnImgWidth = 20	 -- width of btnX/etc for spacing calculations.

-- Footer button X coordinates. Calculated in changeLanguage(). Alts are for start menu.
local label1AltImgX = 0
local label2AltImgX = 0
local label1AltX = 0
local label2AltX = 0
local label1ImgX = 0
local label2ImgX = 0
local label3ImgX = 0
local label4ImgX = 0
local label1X = 0
local label2X = 0
local label3X = 0
local label4X = 0
local toggle1X = nil
local toggle2X = nil

local spin_allowance = 0
local bottomMenu = false
local utilityMenu = false
local menuSel = 1
local render_distance = 8
local ovrrd_str = ""

-- Generates a switch statement out of the contents of a folder as an extremely-faster alternative for System.DoesFileExist()
-- input:	  "ux0:/data/HexFlow/COVERS/PSVITA/"
-- listdirectory: {[1]={["directory"]=false, ["size"]=31457280, ["name"]="PSCE00001.png"}, [2]={...}...}
-- output:	  {["PCSE00001.png"]=true, ["PCSE00002.png"]=true, ["Rayman Origins.png"]=true, ...}
function switch_generator(dir)
    local switch_output = {}
    for _, v in pairs(System.listDirectory(dir) or {}) do	 -- this "or {}" makes it not crash in case the "dir" is a folder that doesn't exist.
	if v.name then
	    switch_output[v.name]=true
	end
    end
    return switch_output
end

local cur_dir = "ux0:/data/HexFlow/"
local covers_psv = "ux0:/data/HexFlow/COVERS/PSVITA/"
local covers_psp = "ux0:/data/HexFlow/COVERS/PSP/"
local covers_psx = "ux0:/data/HexFlow/COVERS/PSX/"

-- Create directories
System.createDirectory("ux0:/data/HexFlow/")
System.createDirectory("ux0:/data/HexFlow/COVERS/")
System.createDirectory(covers_psv)
System.createDirectory(covers_psp)
System.createDirectory(covers_psx)

local cur_quick_dir = {}

-- Load cur_dir to memory for faster startup. Unlike switch_generator(), this uses :lower() for bulletproofing.
for _, v in pairs(System.listDirectory(cur_dir) or {}) do	 -- this "or {}" makes it not crash in case cur_dir somehow doesn't exist.
    if v.name then
	cur_quick_dir[v.name:lower()]=true
    end
end

if not cur_quick_dir["overrides.dat"] then
    local file_over = System.openFile(cur_dir .. "/overrides.dat", FCREATE)
    cur_quick_dir["overrides.dat"] = true
    System.writeFile(file_over, " ", 1)
    System.closeFile(file_over)
end

if not cur_quick_dir["lastplayedgame.dat"] then
    local file_over = System.openFile(cur_dir .. "/lastplayedgame.dat", FCREATE)
    cur_quick_dir["lastplayedgame.dat"] = true
    System.writeFile(file_over, " \n \n \n \n \n \n \n \n \n \n \n \n \n", 26)	 -- fixes the lag-at-first-launch glitch.
    System.closeFile(file_over)
end

local showView = 0	 -- Localized here so RetroFlow placeholders can be loaded.

-- load 3D models and textures
local modBackground = Render.loadObject("app0:/DATA/planebg.obj", imgBack)
local modDefaultBackground = Render.loadObject("app0:/DATA/planebg.obj", imgBack)
local modFloor = Render.loadObject("app0:/DATA/planefloor.obj", imgFloor)

local imgBox = Graphics.loadImage("app0:/DATA/vita_cover.png")
local imgBoxPSP = Graphics.loadImage("app0:/DATA/psp_cover.png")
local imgBoxPSX = Graphics.loadImage("app0:/DATA/psx_cover.png")

local modBox = Render.loadObject("app0:/DATA/box.obj", imgBox)
local modCover = Render.loadObject("app0:/DATA/cover.obj", imgCoverTmp)
local modBoxNoref = Render.loadObject("app0:/DATA/box_noreflx.obj", imgBox)
local modCoverNoref = Render.loadObject("app0:/DATA/cover_noreflx.obj", imgCoverTmp)

local modBoxPSP = Render.loadObject("app0:/DATA/boxpsp.obj", imgBoxPSP)
local modCoverPSP = Render.loadObject("app0:/DATA/coverpsp.obj", imgCoverTmp)
local modBoxPSPNoref = Render.loadObject("app0:/DATA/boxpsp_noreflx.obj", imgBoxPSP)
local modCoverPSPNoref = Render.loadObject("app0:/DATA/coverpsp_noreflx.obj", imgCoverTmp)

local modBoxPSX = Render.loadObject("app0:/DATA/boxpsx.obj", imgBoxPSX)
local modCoverPSX = Render.loadObject("app0:/DATA/coverpsx.obj", imgCoverTmp)
local modBoxPSXNoref = Render.loadObject("app0:/DATA/boxpsx_noreflx.obj", imgBoxPSX)
local modCoverPSXNoref = Render.loadObject("app0:/DATA/coverpsx_noreflx.obj", imgCoverTmp)

local modCoverHbr = Render.loadObject("app0:/DATA/cover_square.obj", imgCoverTmp)
local modCoverHbrNoref = Render.loadObject("app0:/DATA/cover_square_noreflx.obj", imgCoverTmp)

function load_RetroFlow()
    modCoverN64 = Render.loadObject("app0:/DATA/covern64.obj", imgCoverTmp)
    modCoverN64Noref = Render.loadObject("app0:/DATA/covern64_noreflx.obj", imgCoverTmp)

    modCoverNES = Render.loadObject("app0:/DATA/covernes.obj", imgCoverTmp)
    modCoverNESNoref = Render.loadObject("app0:/DATA/covernes_noreflx.obj", imgCoverTmp)

    modCoverGB = Render.loadObject("app0:/DATA/covergb.obj", imgCoverTmp)
    modCoverGBNoref = Render.loadObject("app0:/DATA/covergb_noreflx.obj", imgCoverTmp)

    modCoverMD = Render.loadObject("app0:/DATA/covermd.obj", imgCoverTmp)
    modCoverMDNoref = Render.loadObject("app0:/DATA/covermd_noreflx.obj", imgCoverTmp)

    modCoverTAPE = Render.loadObject("app0:/DATA/covertape.obj", imgCoverTmp)
    modCoverTAPENoref = Render.loadObject("app0:/DATA/covertape_noreflx.obj", imgCoverTmp)

    modCoverATARI = Render.loadObject("app0:/DATA/coveratari.obj", imgCoverTmp)
    modCoverATARINoref = Render.loadObject("app0:/DATA/coveratari_noreflx.obj", imgCoverTmp)

    modCoverLYNX = Render.loadObject("app0:/DATA/coverlynx.obj", imgCoverTmp)
    modCoverLYNXNoref = Render.loadObject("app0:/DATA/coverlynx_noreflx.obj", imgCoverTmp)

    function launch_retroarch(romfile, def_core_name)
	System.executeUri("psgm:play?titleid=RETROVITA" .. "&param=" .. def_core_name .. "&param2=" .. romfile)
	System.exit()
    end

    function launch_DaedalusX64(romfile)
	System.executeUri("psgm:play?titleid=DEDALOX64" .. "&param=" .. romfile)
	System.exit()
    end

    function launch_Flycast(romfile)
	System.executeUri("psgm:play?titleid=FLYCASTDC" .. "&param=" .. romfile)
	System.exit()
    end

    function launch_Fake08(romfile)
	romfile = romfile:gsub("ux0:", "ux0:/", 1)
	System.executeUri("psgm:play?titleid=FAKE00008" .. "&param=" .. romfile)
	System.exit()
    end

--  function launch_NooDS(romfile)
--	System.executeUri("psgm:play?titleid=NOODSVITA" .. "&param=" .. romfile)
--	System.exit()
--  end

--  function launch_scummvm(romfile, Working_Launch_ID)	 -- needs work
--	System.executeUri("psgm:play?titleid=VSCU00001" .. "&path=" .. romfile .. "&game_id=" .. ??????????????)
--	System.exit()
--  end

    function xRomDirLookup(rdir)
	if rdir == 5 then return	 "ux0:data/RetroFlow/ROMS/Nintendo - Nintendo 64/"
	elseif rdir == 6 then return	 "ux0:data/RetroFlow/ROMS/Nintendo - Super Nintendo Entertainment System/"
	elseif rdir == 7 then return	 "ux0:data/RetroFlow/ROMS/Nintendo - Nintendo Entertainment System/"
      --elseif rdir ==   then return	 "ux0:data/RetroFlow/ROMS/Nintendo - Nintendo DS/"
	elseif rdir == 8 then return	 "ux0:data/RetroFlow/ROMS/Nintendo - Game Boy Advance/"
	elseif rdir == 9 then return	 "ux0:data/RetroFlow/ROMS/Nintendo - Game Boy Color/"
	elseif rdir == 10 then return	 "ux0:data/RetroFlow/ROMS/Nintendo - Game Boy/"
	elseif rdir == 11 then return	 "ux0:data/RetroFlow/ROMS/Sega - Dreamcast/"
	elseif rdir == 12 then return	 "ux0:data/RetroFlow/ROMS/Sega - Mega-CD - Sega CD/"
	elseif rdir == 13 then return	 "ux0:data/RetroFlow/ROMS/Sega - 32X/"
	elseif rdir == 14 then return	 "ux0:data/RetroFlow/ROMS/Sega - Mega Drive - Genesis/"
	elseif rdir == 15 then return	 "ux0:data/RetroFlow/ROMS/Sega - Master System - Mark III/"
	elseif rdir == 16 then return	 "ux0:data/RetroFlow/ROMS/Sega - Game Gear/"
	elseif rdir == 17 then return	 "ux0:data/RetroFlow/ROMS/NEC - TurboGrafx 16/"
	elseif rdir == 18 then return	 "ux0:data/RetroFlow/ROMS/NEC - TurboGrafx CD/"
	elseif rdir == 19 then return	 "ux0:data/RetroFlow/ROMS/NEC - PC Engine/"
	elseif rdir == 20 then return	 "ux0:data/RetroFlow/ROMS/NEC - PC Engine CD/"
	elseif rdir == 21 then return	 "ux0:data/RetroFlow/ROMS/Commodore - Amiga/"
	elseif rdir == 22 then return	 "ux0:data/RetroFlow/ROMS/Commodore - 64/"
	elseif rdir == 23 then return	 "ux0:data/RetroFlow/ROMS/Bandai - WonderSwan Color/"
	elseif rdir == 24 then return	 "ux0:data/RetroFlow/ROMS/Bandai - WonderSwan/"
      --elseif rdir ==    then return	 "ux0:/data/RetroFlow/ROMS/ScummVM"
	elseif rdir == 25 then return	 "ux0:p8carts/"
	elseif rdir == 26 then return	 "ux0:data/RetroFlow/ROMS/Microsoft - MSX2/"
	elseif rdir == 27 then return	 "ux0:data/RetroFlow/ROMS/Microsoft - MSX/"
	elseif rdir == 28 then return	 "ux0:data/RetroFlow/ROMS/Sinclair - ZX Spectrum/"
	elseif rdir == 29 then return	 "ux0:data/RetroFlow/ROMS/Atari - 7800/"
	elseif rdir == 30 then return	 "ux0:data/RetroFlow/ROMS/Atari - 5200/"
	elseif rdir == 31 then return	 "ux0:data/RetroFlow/ROMS/Atari - 2600/"
	elseif rdir == 32 then return	 "ux0:data/RetroFlow/ROMS/Atari - Lynx/"
	elseif rdir == 33 then return	 "ux0:data/RetroFlow/ROMS/Coleco - ColecoVision/"
	elseif rdir == 34 then return	 "ux0:data/RetroFlow/ROMS/GCE - Vectrex/"
      --elseif rdir ==    then return	 "ux0:data/RetroFlow/ROMS/FBA 2012/"
      --elseif rdir ==    then return	 "ux0:data/RetroFlow/ROMS/MAME 2003 Plus/"
      --elseif rdir ==    then return	 "ux0:data/RetroFlow/ROMS/MAME 2000/"
      --elseif rdir ==    then return	 "ux0:data/RetroFlow/ROMS/SNK - Neo Geo - FBA 2012/"
	elseif rdir == 35 then return	 "ux0:data/RetroFlow/ROMS/SNK - Neo Geo Pocket Color/"
	else		       return	 "ux0:data/RetroFlow/ROMS/Sony - PlayStation - RetroArch/"
	end
    end

    function xSIconLookup(square_type)		 -- Placeholder icons in Triangle Menu and SwitchView
	if square_type == 5 then	 return "app0:/DATA/icon_n64.png"
	elseif square_type == 6 then	 return "app0:/DATA/icon_snes.png"
	elseif square_type == 7 then	 return "app0:/DATA/icon_nes.png"
      --elseif square_type ==   then	 return "app0:/DATA/icon_nds.png"
	elseif square_type == 8 then	 return "app0:/DATA/icon_gba.png"
	elseif square_type == 9 then	 return "app0:/DATA/icon_gbc.png"
	elseif square_type == 10 then	 return "app0:/DATA/icon_gb.png"
	elseif square_type == 11 then	 return "app0:/DATA/icon_dreamcast_eur.png"
	elseif square_type == 12 then	 return "app0:/DATA/icon_sega_cd.png"
	elseif square_type == 13 then	 return "app0:/DATA/icon_32x.png"
	elseif square_type == 14 then	 return "app0:/DATA/icon_md_usa.png"
	elseif square_type == 15 then	 return "app0:/DATA/icon_sms.png"
	elseif square_type == 16 then	 return "app0:/DATA/icon_gg.png"
	elseif square_type == 17 then	 return "app0:/DATA/icon_tg16.png"
	elseif square_type == 18 then	 return "app0:/DATA/icon_tgcd.png"
	elseif square_type == 19 then	 return "app0:/DATA/icon_pce.png"
	elseif square_type == 20 then	 return "app0:/DATA/icon_pcecd.png"
	elseif square_type == 21 then	 return "app0:/DATA/icon_amiga.png"
	elseif square_type == 22 then	 return "app0:/DATA/icon_c64.png"
	elseif square_type == 23 then	 return "app0:/DATA/icon_wswan_col.png"
	elseif square_type == 24 then	 return "app0:/DATA/icon_wswan.png"
      --elseif square_type == 26 then	 return "app0:/DATA/icon_scummvm.png"
	elseif square_type == 25 then	 return "app0:/DATA/icon_pico8.png"
	elseif square_type == 26 then	 return "app0:/DATA/icon_msx2.png"
	elseif square_type == 27 then	 return "app0:/DATA/icon_msx1.png"
	elseif square_type == 28 then	 return "app0:/DATA/icon_zxs.png"
	elseif square_type == 29 then	 return "app0:/DATA/icon_atari_7800.png"
	elseif square_type == 30 then	 return "app0:/DATA/icon_atari_5200.png"
	elseif square_type == 31 then	 return "app0:/DATA/icon_atari_2600.png"
	elseif square_type == 32 then	 return "app0:/DATA/icon_atari_lynx.png"
	elseif square_type == 33 then	 return "app0:/DATA/icon_colecovision.png"
	elseif square_type == 34 then	 return "app0:/DATA/icon_vectrex.png"
      --elseif square_type ==    then	 return "app0:/DATA/icon_fba.png"
      --elseif square_type ==    then	 return "app0:/DATA/icon_mame_2003p.png"
      --elseif square_type ==    then	 return "app0:/DATA/icon_mame.png"
      --elseif square_type ==    then	 return "app0:/DATA/icon_neogeo.png"
	elseif square_type == 35 then	 return "app0:/DATA/icon_ngpc.png"
	else				 return "app0:/DATA/icon_psx.png"
	end
    end

    function xTrueIconLookup(tr_apptype)
	return xSIconLookup(tr_apptype):gsub("app0:/DATA/icon", "app0:/DATA/missing_cover")
    end

    function Basic_Filter_Check(tmp_extension)
	if tmp_extension ~= ".sav"		 -- RetroArch/NooDS save file
	and tmp_extension ~= ".srm"
	and tmp_extension ~= ".mpk"
	and tmp_extension ~= ".eep"
	and tmp_extension ~= ".st0"
	and tmp_extension ~= ".sta"
	and tmp_extension ~= ".sr0"
	and tmp_extension ~= ".ss0"
	and tmp_extension ~= "tore"		 -- folder info file: DS_Store
	and tmp_extension:sub(-2) ~= "._"	 -- temporary file created if a file transfer fails.
	and tmp_extension:sub(-3) ~= ".db" then	 -- folder info file: Thumbs.db
	    return "pass"
	end
    end

    function Read_Rom_Dir(tmpap, filter_list)
	local tmp_rom_dir = xRomDirLookup(tmpap)
	local tmp_table_in = System.listDirectory(tmp_rom_dir) or {}		 -- defaults to empty table {} in case a rom directory doesn't exist.
	local tmp_table_out_1 = {}
	local coverspath = tmp_rom_dir:gsub("/ROMS/", "/COVERS/")		 -- Example: "ux0:data/RetroFlow/COVERS/Nintendo - Game Boy"
	local tmp_covers_list = {}
	local custom_path = ""

	if tmpap == 3 then
	    coverspath = covers_psx
	    tmp_covers_list = switch_generator(covers_psx)
	else
	    tmp_covers_list = switch_generator(coverspath)
	end

	for _, v in pairs(tmp_table_in) do
	    for __, filter in ipairs(filter_list or {false}) do			 -- default filter is boolean "false"
		if v.directory then
		    if filter and filter == "folder" then
			v.apptitle = v.name
		    else
			break							 -- ignore folders unless we're actually looking for them.
		    end
		elseif filter and v.name:sub(-filter:len()) == filter then
		    v.apptitle = v.name:sub(1, -filter:len()-1)			 -- Super_Disc_Box.p8.png --> Super_Disc_Box
		elseif not filter and v.name:match("%.") and Basic_Filter_Check(v.name:sub(-4)) then
		    v.apptitle = v.name:match("(.+)%..+$")			 -- Donkey_Kong.n64 --> Donkey_Kong
		else
		    goto next_filter
		end
		v.app_type = tmpap
		v.launch_type = tmpap
		custom_path = (v.name:match("(.+)%..+$") or v.name) .. ".png"	 -- take filename and either cut off everything after "." OR if there's no "." use the whole filename. Works for normal roms AND lets pico-8 detect itself as a cover.
		table.insert(files_table, v)
		table.insert(tmp_table_out_1, v)
		if tmp_covers_list[custom_path] then
		    v.icon_path = coverspath .. custom_path
		elseif showView==5 or showView==6 then
		    v.icon_path = xSIconLookup(tmpap)				 -- special square placeholder icons for SwitchView.
		else
		    v.icon_path = xTrueIconLookup(tmpap)
		end
		::next_filter::
	    end
	end
	table.sort(tmp_table_out_1, function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)
	return tmp_table_out_1
    end

    psx_table =		 Read_Rom_Dir(3, {".cue", ".img", ".mdf", ".pbp", ".toc", ".cbn", ".m3u", ".ccd", ".chd"})	 --NOTE: apptype 4 is reserved for homebrew
    n64_table =		 Read_Rom_Dir(5)			 -- "ux0:data/RetroFlow/ROMS/Nintendo - Nintendo 64")				 @@ .n64 .z64 .v64
    snes_table =	 Read_Rom_Dir(6)			 -- "ux0:data/RetroFlow/ROMS/Nintendo - Super Nintendo Entertainment System")	 @@ .sfc .smc .fig
    nes_table =		 Read_Rom_Dir(7)			 -- "ux0:data/RetroFlow/ROMS/Nintendo - Nintendo Entertainment System")		 @@ .nes .fds .unf .unif
  --nds_table =		 Read_Rom_Dir( , {".nds"})		 -- "ux0:data/RetroFlow/ROMS/Nintendo - Nintendo DS")
    gba_table =		 Read_Rom_Dir(8)			 -- "ux0:data/RetroFlow/ROMS/Nintendo - Game Boy Advance")			 @@ .gba
    gbc_table =		 Read_Rom_Dir(9)			 -- "ux0:data/RetroFlow/ROMS/Nintendo - Game Boy Color")			 @@ .gbc
    gb_table =		 Read_Rom_Dir(10)			 -- "ux0:/data/RetroFlow/ROMS/Nintendo - Game Boy")				 @@ .gb
    dreamcast_table =	 Read_Rom_Dir(11, {".cdi", ".gdi"})	 -- "ux0:data/RetroFlow/ROMS/Sega - Dreamcast")
    sega_cd_table =	 Read_Rom_Dir(12, {".chd", ".cue"})	 -- "ux0:data/RetroFlow/ROMS/Sega - Mega-CD - Sega CD")
    s32x_table =	 Read_Rom_Dir(13)			 -- "ux0:data/RetroFlow/ROMS/Sega - 32X")
    md_table =		 Read_Rom_Dir(14)			 -- "ux0:data/RetroFlow/ROMS/Sega - Mega Drive - Genesis")			 @@ .md .gen .smd
    sms_table =		 Read_Rom_Dir(15)			 -- "ux0:data/RetroFlow/ROMS/Sega - Master System - Mark III")			 @@ .sms
    gg_table =		 Read_Rom_Dir(16)			 -- "ux0:data/RetroFlow/ROMS/Sega - Game Gear")					 @@ .gg
    tg16_table =	 Read_Rom_Dir(17)			 -- "ux0:data/RetroFlow/ROMS/NEC - TurboGrafx 16")
    tgcd_table =	 Read_Rom_Dir(18, {".chd", ".cue"})	 -- "ux0:data/RetroFlow/ROMS/NEC - TurboGrafx CD")
    pce_table =		 Read_Rom_Dir(19)			 -- "ux0:data/RetroFlow/ROMS/NEC - PC Engine")
    pcecd_table =	 Read_Rom_Dir(20, {".chd", ".cue"})	 -- "ux0:data/RetroFlow/ROMS/NEC - PC Engine CD")
    amiga_table =	 Read_Rom_Dir(21)			 -- "ux0:data/RetroFlow/ROMS/Commodore - Amiga")				 @@ .adf
    c64_table =		 Read_Rom_Dir(22)			 -- "ux0:data/RetroFlow/ROMS/Commodore - 64")					 @@ .t64
    wswan_col_table =	 Read_Rom_Dir(23)			 -- "ux0:data/RetroFlow/ROMS/Bandai - WonderSwan Color")			 @@ .ws
    wswan_table =	 Read_Rom_Dir(24)			 -- "ux0:data/RetroFlow/ROMS/Bandai - WonderSwan")				 @@ .ws
  --scummvm_table =	 Read_Rom_Dir(  , {"folder"})		 -- "ux0:/data/RetroFlow/ROMS/ScummVM")						 @@ folders
    pico8_table =	 Read_Rom_Dir(25, {".p8.png"})		 -- "ux0:p8carts")
    msx2_table =	 Read_Rom_Dir(26)			 -- "ux0:data/RetroFlow/ROMS/Microsoft - MSX2")
    msx1_table =	 Read_Rom_Dir(27)			 -- "ux0:data/RetroFlow/ROMS/Microsoft - MSX")
    zxs_table =		 Read_Rom_Dir(28)			 -- "ux0:data/RetroFlow/ROMS/Sinclair - ZX Spectrum")
    atari_7800_table =	 Read_Rom_Dir(29)			 -- "ux0:data/RetroFlow/ROMS/Atari - 7800")					 @@ .a78
    atari_5200_table =	 Read_Rom_Dir(30)			 -- "ux0:data/RetroFlow/ROMS/Atari - 5200")					 @@ .a52
    atari_2600_table =	 Read_Rom_Dir(31)			 -- "ux0:data/RetroFlow/ROMS/Atari - 2600")					 @@ .a26
    atari_lynx_table =	 Read_Rom_Dir(32)			 -- "ux0:data/RetroFlow/ROMS/Atari - Lynx")					 @@ .lnx
    colecovision_table = Read_Rom_Dir(33)			 -- "ux0:data/RetroFlow/ROMS/Coleco - ColecoVision")
    vectrex_table =	 Read_Rom_Dir(34)			 -- "ux0:data/RetroFlow/ROMS/GCE - Vectrex")
  --if arcadeMerge == 1 then
  --	fba_table = TableConcat(TableConcat(Read_Rom_Dir(36), Read_Rom_Dir(37)), TableConcat(Read_Rom_Dir(38), Read_Rom_Dir(39)))
  --	mame_2003_plus_table = {}
  --	mame_2000_table = {}
  --	neogeo_table = {}
  --	table.sort(fba_table, function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)
  --else
  --	fba_table =		 Read_Rom_Dir(  )		 -- "ux0:data/RetroFlow/ROMS/FBA 2012")
  --	mame_2003_plus_table =	 Read_Rom_Dir(  )		 -- "ux0:data/RetroFlow/ROMS/MAME 2003 Plus")
  --	mame_2000_table =	 Read_Rom_Dir(  )		 -- "ux0:data/RetroFlow/ROMS/MAME 2000")
  --	neogeo_table =		 Read_Rom_Dir(  )		 -- "ux0:data/RetroFlow/ROMS/SNK - Neo Geo - FBA 2012")
  --end
    ngpc_table =	 Read_Rom_Dir(35)			 -- "ux0:data/RetroFlow/ROMS/SNK - Neo Geo Pocket Color")			 @@ .ngp .ngc

    RetroflowAssetsAreLoaded = true
end

function load_SwitchView()
    fnt23_5 = Font.load("app0:/DATA/font.woff")
    Font.setPixelSizes(fnt23_5, 23.5)
    imgCart = Graphics.loadImage("app0:/DATA/cart.png")
    --imgAvatar = Graphics.loadImage("app0:/AVATARS/AV01.png")
    --imgCont = Graphics.loadImage("app0:/DATA/cont.png")
    --img4Square = Graphics.loadImage("app0:/DATA/foursquare.png")
    imgFloor2 = Graphics.loadImage("app0:/DATA/floor2.png")
    btnMenu1 = Graphics.loadImage("app0:/DATA/btm1.png")
    btnMenu2 = Graphics.loadImage("app0:/DATA/btm2.png")
    btnMenu3 = Graphics.loadImage("app0:/DATA/btm3.png")
    btnMenu4 = Graphics.loadImage("app0:/DATA/btm4.png")
    btnMenu5 = Graphics.loadImage("app0:/DATA/btm5.png")
    btnMenu6 = Graphics.loadImage("app0:/DATA/btm6.png")
    btnMenuSel = Graphics.loadImage("app0:/DATA/selct.png")
    SwitchviewAssetsAreLoaded = true
end

local fnt15 = Font.load("app0:/DATA/font.woff")
local fnt20 = Font.load("app0:/DATA/font.woff")
local fnt22 = Font.load("app0:/DATA/font.woff")
local fnt25 = Font.load("app0:/DATA/font.woff")

Font.setPixelSizes(fnt15, 15)
Font.setPixelSizes(fnt20, 20)
Font.setPixelSizes(fnt22, 22)
Font.setPixelSizes(fnt25, 25)

function sanitize(some_data)
    some_data = tostring(some_data)
    return some_data:gsub("\r", ""):gsub("\n", " "):gsub("\t", " ")
end

local menuX = 0
local menuY = 0
local showMenu = 0
local showCat = 1 -- Category: 0 = all, 1 = games, 2 = homebrews, 3 = psp, 4 = psx, 5 = custom
--local showView = 0

local info = System.extractSfo("app0:/sce_sys/param.sfo")
local app_version = info.version
local app_title = info.title
local app_short_title = info.short_title
local app_category = info.category
local app_titleid = info.titleid
--local app_size = 0
local app_size_text = "0"
local DISC_ID = false		 -- can be a string or a bool false

local master_index = 1
local p = 1
local oldpad = 0
--local delayTouch = 8.0	 -- unused
local delayButton = 8.0
local hideBoxes = 0.2
local tmp_move = 0
local prvRotY = 0

local gettingCovers = false
local scanComplete = false
local hasTyped = false

-- Init Colors
local black = Color.new(0, 0, 0)
local grey = Color.new(45, 45, 45)
local darkalpha = Color.new(40, 40, 40, 180)
local lightgrey = Color.new(58, 58, 58)
local white = Color.new(255, 255, 255)
local red = Color.new(190, 0, 0)
local blue = Color.new(2, 72, 158)
local yellow = Color.new(225, 184, 0)
local green = Color.new(79, 152, 37)
local orange = Color.new(220, 120, 0)
local pink = Color.new(170, 68, 101)	 --@@ NEW! Replaces the old 'purple' (151, 0, 185)
local purple = Color.new(77, 4, 160)	 --@@ Used to be called 'darkpurple'
local lightblue = Color.new(67,178,255)
local greyalpha = Color.new(45, 45, 45, 180)
local bg = Color.new(153, 217, 234)
local themeCol = Color.new(2, 72, 158)

local base_x = 0
local base_y = 0
local grid_x = 0
local grid_y = 0
local n64_x_bonus = 0	 -- n64_fix
local n64_fatness = 0.8	 -- n64_fix
local skipRow = false
local BaseYHotfix = 0	 --For the special Y axis behaviour in categories with 18 or more entries in Grid View.
local targetX = 0
local targetY = 0
local floorY = 0
local xstart = 0
local ystart = 0
local space = 1

local icon_height = 1
local icon_width = 1

local touchdown = 0
local tap_target = 0
local tap_zones = {}

local startCovers = false
local inPreview = false
local apptype = 0
local appdir = ""
local getCovers = 1 --1 PSV, 2 Homebrews, 3 PSP, 4 PS1
local getBGround = 1 --1 Custom, 2 Citylights, 3 Aurora, 4 "Wood 1", 5 "Wood 2", 6 Dark, 7 Marble
local BGroundText = "-"
local tmpappcat = 0
local background_brackets = true

local prevX = 0
local prevZ = 0
local prevRot = 0

--local total_all = 0
--local total_games = 0
--local total_homebrews = 0
--local total_pspemu = 0
--local total_roms = 0
local total_apps = 0
local curTotal = 0

local categoryText = "PS Vita"

-- Settings
local startCategory = 1
local setReflections = 1
local setSounds = 1
local musicLoop = 1
local themeColor = 0 -- 0 blue, 1 red, 2 yellow, 3 green, 4 grey, 5 black, 7 orange, 6 purple, 8 darkpurple. (reorder hack) 
local menuItems = 3 
local setBackground = 1 
local setLanguage = 0 
local showHomebrews = 0 
local setSwitch = 0
local setRetroFlow = 0
local hideEmptyCats = 0
local categoryButton = 0
local View5VitaCropTop = 1
local lockView = 0
local showRecentlyPlayed = 1
local swapXO = 0
--local smoothScrolling = 0			 -- unused
--local arcadeMerge = 0				 -- unused

local UNUSED1 = 1				 -- (1/2) For backwards compatability.
local UNUSED2 = 0				 -- (2/2)

function write_config()
    local file_config = System.openFile(cur_dir .. "/config.dat", FCREATE)
    cur_quick_dir["config.dat"] = true
    System.writeFile(file_config, (
	UNUSED1					 -- Used to be startCategory
	.. setReflections
	.. setSounds
	.. themeColor
	.. setBackground
	.. UNUSED2				 -- Used to be setLanguage
	.. showView
	.. showHomebrews
	.. musicLoop
	.. setSwitch
	.. hideEmptyCats
	.. categoryButton
	.. View5VitaCropTop
	.. setRetroFlow
	.. lockView
	.. showRecentlyPlayed
	.. string.format("%02d", startCategory)	 -- Upgraded to double digits
--@@	.. string.format("%02d", setLanguage)
--@@	.. 0
    ), 18)	 --@@ Used to be 21 before the experimental Error 597 fix.
    System.closeFile(file_config)
end

function stringSplit(inputstr, sep)
    if sep == nil then
	sep = "%s" --all "space"-type characters
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
	table.insert(t, str)
    end
    return t
end

function readBin(filename, allow_iso_scan)	 -- returns a string or nil
    local path_game = nil
    if System.doesFileExist(filename) and string.match(filename, ".bin") then
	local inp = assert(io.open(filename, "rb"), "Failed to open boot.bin")
	inp:seek("set",64)				 -- Skip early junk bytes
	local data = inp:read("*all"):gsub("%c", "")	 -- gsub %c skips late junk bytes. Result: "ux0:pspemu/psp/game/slus00453/eboot.pbp"
	inp:close()

	-- Supports PSP .iso files and PSX2PSP .eboot files

	if data:sub(-10):upper() == "/EBOOT.PBP" then
	    path_game = string.sub(data, -19, -11)	 -- Gets the "slus00453" from "ux0:pspemu/psp/game/slus00453/eboot.pbp"
	    app_size_text = app_size_text .. " (" .. string.format("%02d", getAppSize(data:sub(0, -10))/1024/1024) .. "Mb)"	 --@@ NEW! Example: "01Mb (512Mb)"
	elseif allow_iso_scan == true
	 and data:sub(-4):upper() == ".ISO"
	 and System.doesFileExist(data) then		 -- Example: "ux0:pspemu/ISO/Dantes_Inferno.iso"
	    inp = assert(io.open(data), "Failed to open PSP .iso file")
	    inp:seek("set",33651)
	    path_game = inp:read(10)
	    inp:close()
	    if path_game ~= nil then
		path_game = path_game:gsub("-", "")
	    end
	    inp = System.openFile(data, FREAD)		 -- There's probably a better way to do this
	 	app_size_text = app_size_text .. " (" .. string.format("%02d", System.sizeFile(inp)/1024/1024) .. "Mb)"
	    System.closeFile(inp)
	end
    end
    if path_game and not path_game:match("%W") then	 -- Only return valid path_game that DON'T have NON-alphanumeric characters.
	return path_game:upper()			 -- Example: SLUS00453
    end
end

--@@function autoset_language()
    local getLanguage = System.getLanguage()

    if getLanguage == 0 then
	setLanguage = 9		 -- Japanese
  --elseif (getLanguage == 1) or (getLanguage == 18) then	 -- 1=AmericanEnglish, 18=British
  --	setLanguage = 0		 -- American English
    elseif getLanguage == 2 then
	setLanguage = 2		 -- French
    elseif (getLanguage == 3) or (getLanguage == 20) then	 -- 3=Spanish, 20=SpanishLatin
	setLanguage = 4		 -- Spanish
    elseif getLanguage == 4 then
	setLanguage = 1		 -- German
    elseif getLanguage == 5 then
	setLanguage = 3		 -- Italian
    elseif (getLanguage == 7) or (getLanguage == 17) then	 -- 7=PortugeseTrad, 17=PortugeseBrazil
	setLanguage = 7		 -- Portugese
    elseif getLanguage == 8 then
	setLanguage = 5		 -- Russian
    elseif getLanguage == 13 then
	setLanguage = 6		 -- Swedish
    elseif getLanguage == 16 then
	setLanguage = 8		 -- Polish
    elseif getLanguage == 16 then
	setLanguage = 8		 -- Polish
    end	 -- Don't change what language is set if a system language has no co-responding HexFlow Custom language. These languages are as follows:
	 -- 6=Dutch, 9=Korean, 10=ChineseTrad, 11=ChineseSimple, 12=Finnish, 14=Danish, 15=Norwegian, 19=Turkish
	 -- Languages with no system language values which are should be imported from RetroFlow: Hungarian, Japanese Ryukyuan.
--@@end

--@@function apply_XO_swap()
    if Controls.getEnterButton() == SCE_CTRL_CIRCLE then
	swapXO = 1
	CTRL_ACCEPT, CTRL_CANCEL = CTRL_CANCEL, CTRL_ACCEPT
	btnAccept, btnCancel = btnCancel, btnAccept
    else
	swapXO = 0
    end
--@@end

-- READ SETTINGS
if cur_quick_dir["config.dat"] then
    local file_config = System.openFile(cur_dir .. "/config.dat", FREAD)
    local filesize = System.sizeFile(file_config)
    local str = System.readFile(file_config, filesize)
    System.closeFile(file_config)
    
    UNUSED1 =		 tonumber(string.sub(str, 1, 1)) or UNUSED1		 -- Used to be startCategory
    setReflections =	 tonumber(string.sub(str, 2, 2)) or setReflections
    setSounds =		 tonumber(string.sub(str, 3, 3)) or setSounds
    themeColor =	 tonumber(string.sub(str, 4, 4)) or themeColor
    setBackground =	 tonumber(string.sub(str, 5, 5)) or setBackground
    UNUSED2 =		 tonumber(string.sub(str, 6, 6)) or UNUSED2		 -- Used to be setLanguage
    showView =		 tonumber(string.sub(str, 7, 7)) or showView
    showHomebrews =	 tonumber(string.sub(str, 8, 8)) or showHomebrews
    musicLoop =		 tonumber(string.sub(str, 9, 9)) or musicLoop
    setSwitch =		 tonumber(string.sub(str, 10, 10)) or setSwitch
    hideEmptyCats =	 tonumber(string.sub(str, 11, 11)) or hideEmptyCats
    categoryButton =	 tonumber(string.sub(str, 12, 12)) or categoryButton
    View5VitaCropTop =	 tonumber(string.sub(str, 13, 13)) or View5VitaCropTop
    setRetroFlow =	 tonumber(string.sub(str, 14, 14)) or setRetroFlow
    lockView =		 tonumber(string.sub(str, 15, 15)) or lockView
    showRecentlyPlayed = tonumber(string.sub(str, 16, 16)) or showRecentlyPlayed
    startCategory =	 tonumber(string.sub(str, 17, 18)) or startCategory	 -- Upgraded to double digits
--@@setLanguage =	 tonumber(string.sub(str, 19, 20)) or autoset_language() --@@ Unnecessary. This is now always scanned instead of cached.
  --smoothScrolling = 	 tonumber(string.sub(str,   ,   )) or smoothScrolling	 -- unused
  --arcadeMerge =	 tonumber(string.sub(str,   ,   )) or arcadeMerge	 -- unused
else
--@@autoset_language()
    write_config()
end

--@@apply_XO_swap()
showCat = startCategory

if showView > 4 then
    if setSwitch == 1 then
	load_SwitchView()
    else
	showView = 0
    end
end


-- Custom Backgrounds
function ApplyBackground()
    imgCustomBack = imgBack
    if (setBackground >= 10) and (setBackground < 99) and (System.doesFileExist("app0:/DATA/back_" .. setBackground .. ".png")) then
	imgCustomBack = Graphics.loadImage("app0:/DATA/back_" .. setBackground .. ".png")	 -- default BG's "back_10.png" through "back_12.png"
    elseif (setBackground > 1.5) and (setBackground < 10) and (System.doesFileExist("app0:/DATA/back_0" .. setBackground .. ".png")) then
	imgCustomBack = Graphics.loadImage("app0:/DATA/back_0" .. setBackground .. ".png")	 -- default BG's "back_02.png" through "back_08.png"
    elseif cur_quick_dir["background.png"] then
	imgCustomBack = Graphics.loadImage("ux0:/data/HexFlow/Background.png")			 -- custom png
    elseif cur_quick_dir["background.jpg"] then
	imgCustomBack = Graphics.loadImage("ux0:/data/HexFlow/Background.jpg")			 -- custom jpg
    end

    Graphics.setImageFilters(imgCustomBack, FILTER_LINEAR, FILTER_LINEAR)
    Render.useTexture(modBackground, imgCustomBack)
end
ApplyBackground()

-- Custom Music
function play_music()
    if setSounds ~= 0 then
	if cur_quick_dir["music.mp3"] then
	    sndMusic = Sound.open(cur_dir .. "/Music.mp3")
	elseif cur_quick_dir["music.ogg"] then
	    sndMusic = Sound.open(cur_dir .. "/Music.ogg")
	else
	    return	 -- if no music exists, just closes this function.
	end
	if musicLoop == 1 then
	    Sound.play(sndMusic, true)
	else
	    Sound.play(sndMusic, false)
	end
    end
end
play_music()

function SetThemeColor()
    if themeColor == 1 then
        themeCol = red
    elseif themeColor == 2 then
        themeCol = yellow
    elseif themeColor == 3 then
        themeCol = green
    elseif themeColor == 4 then
        themeCol = lightgrey
    elseif themeColor == 5 then
        themeCol = black
    elseif themeColor == 7 then
        themeCol = orange
    elseif themeColor == 6 then
    --@@themeCol = purple
        themeCol = pink --@@ NEW!
    elseif themeColor == 8 then
    --@@themeCol = darkpurple
        themeCol = purple --@@ NEW!
    else
        themeCol = blue -- default blue
    end
end
SetThemeColor()

function OneShotPrint(my_func)
    local loadingCacheImg = Graphics.loadImage("app0:/DATA/oneshot_cache_write.png")
    local imgCacheIcon = Graphics.loadImage("app0:/DATA/cache_icon_25x25.png")
    -- Draw loading screen for caching process
    Graphics.termBlend()  -- End main loop blending if still running
    Graphics.initBlend()
    Screen.clear(black)
    Graphics.drawImage(0, 0, loadingCacheImg)
    Graphics.drawImage(587, 496, imgCacheIcon)
    Graphics.termBlend()
    Screen.flip()
    Graphics.freeImage(loadingCacheImg)
end

local lang_lines = {}
local lang_default = "PS VITA\nHOMEBREWS\nPSP\nPS1\nALL\nSETTINGS\nLaunch\nDetails\nCategory\nView\nClose\nVersion\nAbout\nStartup Category\nReflection Effect\nSounds\nTheme Color\nCustom Background\nDownload Covers\nReload Covers Database\nLanguage\nON\nOFF\nRed\nYellow\nGreen\nGrey\nBlack\nPurple\nOrange\nBlue\nSelect"
		  .. "Nintendo 64\nSuper Nintendo\nNintendo Entertainment System\nGame Boy Advance\nGame Boy Color\nGame Boy\nSega Genesis/Mega Drive\nSega Master System\nSega Game Gear\nMAME\nAmiga\nTurboGrafx-16\nPC Engine\nHomebrews Category\nStartup scan\nRefresh cache\nCUSTOM\nCover style\nScan\nPlease wait...\nMenu\nDark Purple"
		  .. "Done. Please 'Refresh cache' via the start menu\nCover * found!\nCache has been updated.\nwriting to cache... please don't suspend/power off"
function ChangeLanguage()
    lang_lines = {}
    local lang = "EN.ini"
     -- 0 EN, 1 DE, 2 FR, 3 IT, 4 SP, 5 RU, 6 SW, 7 PT, 8 PL, 9 JA
    if setLanguage == 1 then
	lang = "DE.ini"
    elseif setLanguage == 2 then
	lang = "FR.ini"
    elseif setLanguage == 3 then
	lang = "IT.ini"
    elseif setLanguage == 4 then
	lang = "SP.ini"
    elseif setLanguage == 5 then
	lang = "RU.ini"
    elseif setLanguage == 6 then
	lang = "SW.ini"
    elseif setLanguage == 7 then
	lang = "PT.ini"
    elseif setLanguage == 8 then
	lang = "PL.ini"
    elseif setLanguage == 9 then
	lang = "JA.ini"
		
    else
        lang = "EN.ini"
    end
    
    if System.doesFileExist("app0:/translations/" .. lang) then
        langfile = "app0:/translations/" .. lang
    else
        --create default EN.ini if language is missing
	handle = System.openFile("ux0:/data/HexFlow/EN.ini", FCREATE)
	cur_quick_dir["EN.ini"] = true
        System.writeFile(handle, "" .. lang_default, string.len(lang_default))
        System.closeFile(handle)
	langfile = "ux0:/data/HexFlow/EN.ini"
        setLanguage=0
    end

    for line in io.lines(langfile) do
        lang_lines[#lang_lines+1] = line
    end

  --if arcadeMerge == 1 then
  --	fba_text = "Arcade"
  --else
  --	fba_text = "fba_table"
  --end

--Set footer button spacing.   btnMargin: 44    btnImgWidth: 20    8px img-text buffer.
    label1ImgX = 904-Font.getTextWidth(fnt20, lang_lines[7])			 --X
    label1X = label1ImgX+btnImgWidth+8						 --Launch
    label2ImgX = label1ImgX-(Font.getTextWidth(fnt20, lang_lines[8])+btnMargin)	 --Tri
    label2X = label2ImgX+btnImgWidth+8						 --Details
    label3ImgX = label2ImgX-(Font.getTextWidth(fnt20, lang_lines[9])+btnMargin)	 --Box
    label3X = label3ImgX+btnImgWidth+8						 --Category
    if categoryButton == 2 then
	label4ImgX = label2ImgX-(Font.getTextWidth(fnt20, lang_lines[10])+btnMargin) --O
    else
	label4ImgX = label3ImgX-(Font.getTextWidth(fnt20, lang_lines[10])+btnMargin) --O
    end
    label4X = label4ImgX+btnImgWidth+8						 --View

    label1AltImgX = 900-Font.getTextWidth(fnt20, lang_lines[11])			--O
    label1AltX = label1AltImgX+btnImgWidth+8						--Close
    label2AltImgX = label1AltImgX-(Font.getTextWidth(fnt20, lang_lines[32])+btnMargin)	--X
    label2AltX = label2AltImgX+btnImgWidth+8						--Select
    
    toggle1X = nil
end
ChangeLanguage()

function PrintCentered(font, x, y, text, color, size)
    text = text:gsub("\n","")
    local width = Font.getTextWidth(font,text)
    Font.print(font, x - width / 2, y, text, color)
end

function TableConcat(t1, t2)
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

function FreeMemory()
    if (cur_quick_dir["music.mp3"] or cur_quick_dir["music.ogg"])
    and setSounds ~= 0 then
        Sound.close(sndMusic)
    end
    Graphics.freeImage(imgCoverTmp)
    Graphics.freeImage(btnAccept)		 -- Used to be btnX
    Graphics.freeImage(btnCancel)		 -- Used to be btnO
    Graphics.freeImage(btnT)
    Graphics.freeImage(btnS)
    Graphics.freeImage(btnD)
    Graphics.freeImage(imgWifi)
    Graphics.freeImage(imgBattery)
    Graphics.freeImage(imgBack)
    Graphics.freeImage(imgBox)
    if SwitchviewAssetsAreLoaded == true then
	SwitchviewAssetsAreLoaded = false
	Graphics.freeImage(imgCart)
	--Graphics.freeImage(imgAvatar)
	--Graphics.freeImage(imgCont)
	--Graphics.freeImage(img4Square)
	Graphics.freeImage(imgFloor2)
	Graphics.freeImage(btnMenu1)
	Graphics.freeImage(btnMenu2)
	Graphics.freeImage(btnMenu3)
	Graphics.freeImage(btnMenu4)
	Graphics.freeImage(btnMenu5)
	Graphics.freeImage(btnMenu6)
	Graphics.freeImage(btnMenuSel)
    end
end


function toboolean(str)
    local bool = false
    if str == "true" then
        bool = true
    end
    return bool
end

function WriteAppList()
    local file_over = System.openFile(cur_dir .. "/applist.dat", FCREATE)
    cur_quick_dir["applist.dat"] = true
    io.open(cur_dir .. "/applist.dat","w"):close()	 -- Clear old applist data
    System.closeFile(file_over)

    file = io.open(cur_dir .. "/applist.dat", "w")
    for k, v in pairs(folders_table) do
	file:write(v.name .. "," .. sanitize(v.apptitle) .. "\n")
    end
    file:close()
end


-- If app in the custom sort doesn't exist, then it won't be found in files_table, 
-- therefore it will be omitted as desired. If an installed app is not present in 
-- the custom sort, then it won't be displayed, working as a "hide" function.
-- As of v1.2, this is also used for reading the "recently played" file.
function ReadCustomSort(file_over, target_table)
    if cur_quick_dir[file_over] then			 -- faster than System.doesFileExist(cur_dir .. "/customsort.dat")
	sortTimer = Timer.new()
	local rem_table = {}
	for k, v in pairs(files_table) do
	    table.insert(rem_table, v) --I'm sure there's a better way to do this.
	end
	for line in io.lines(cur_dir .. file_over) do
	    if not (line == "" or line == " " or line == "\n") then
	        local app = stringSplit(line, ",")
	        for k, v in pairs(rem_table) do
		    if v.name == app[1] then
			table.insert(target_table, v)
			-- By removing it from the original table, 
			-- duplicates in customsort.dat will be ignored.
			table.remove(rem_table, k)
		    end
		end
	    end
	end
	rem_table = {}
	sortTime = Timer.getTime(sortTimer)
	Timer.destroy(sortTimer)
    else
	sortTime = 0
    end
end

function WriteRecentlyPlayed(lastPlayedGameID)	 -- Needs cleaned up
    local lastPlayedGameText = ""
    local recent_duplicate = false

    if lastPlayedGameID == "hotfix_mode" then
	local lastPlayedGameFile = assert(io.open(cur_dir .. "/lastplayedgame.dat", "r"), "Failed to open lastplayedgame.dat")
	local OLDlastPlayedGameCat = lastPlayedGameFile:read("*line")
	OLDlastPlayedGameCat = tonumber(OLDlastPlayedGameCat)
	if not OLDlastPlayedGameCat then
	    lastPlayedGameFile:close()
	    return
	elseif setRetroFlow == 0 then
	    if OLDlastPlayedGameCat > 35 then	 -- "return to last played" noretro: 7. "return to last played" yesretro: 38
		OLDlastPlayedGameCat = OLDlastPlayedGameCat - 31
	    elseif OLDlastPlayedGameCat > 4 then
		OLDlastPlayedGameCat = 0
	    end
	elseif OLDlastPlayedGameCat > 4 then
	    OLDlastPlayedGameCat = OLDlastPlayedGameCat + 31
	end
	lastPlayedGameText = OLDlastPlayedGameCat .. "\n" .. (lastPlayedGameFile:read("*all") or "") .. "\n"
	lastPlayedGameFile:close()
    elseif showRecentlyPlayed == 1 then
	lastPlayedGameText = showCat .. "\n" .. lastPlayedGameID .. "\n"
	for k, v in ipairs(recently_played_table) do
	    if k < 12 then
		if v.name ~= lastPlayedGameID then
		    lastPlayedGameText = lastPlayedGameText .. v.name .. "\n"
		else
		    recent_duplicate = true
		end
	    elseif recent_duplicate == true and v.name ~= lastPlayedGameID then
		lastPlayedGameText = lastPlayedGameText .. v.name .. "\n"
	    end
	end
    elseif ((setRetroFlow==1 and startCategory==38) or (setRetroFlow~=1 and startCategory==7)) then
	lastPlayedGameText = showCat .. "\n" .. lastPlayedGameID .. "\n"
    end
    if lastPlayedGameText ~= "" then
	local file_over = System.openFile(cur_dir .. "/lastplayedgame.dat", FCREATE)	-- open file or create if it doesn't exist.
	cur_quick_dir["lastplayedgame.dat"] = true
	io.open(cur_dir .. "/lastplayedgame.dat","w"):close()				-- clear file data incase new data is shorter.
	System.writeFile(file_over, lastPlayedGameText, lastPlayedGameText:len())
	System.closeFile(file_over)
    end
end

function appt_hotfix(apptype)
    if apptype == 2 then	 return 3
    elseif apptype == 3 then	 return 4
    elseif apptype == 0
    or apptype == 4 then	 return 2
    else			 return apptype		 -- vita & retro apptypes.
    end
end

function CoverDirectoryLookup(getCovers)  -- For categoric cover downloads
    if getCovers == 2 then
	return covers_psp
    elseif getCovers == 3 then
	return covers_psx
    else		 -- vita & homebrew (0, 1, and 4)
	return covers_psv
    end
end

-- Resets an entry's app_type and respective icon_path based on overrides.dat
function Respec_Entry(file, pspemu_translate_tmp)
    custom_path, custom_path_id, custom_path_psx = nil, nil, nil
    if file.directory and ovrrd_str then	 -- the directory check is only here so the app functions exactly like HEXflow launcher v0.5, it's probably not necessary at all.
	--0 default, 1 vita, 2 psp, 3 psx, 4 homebrew
	if string.match(ovrrd_str, file.name .. "=1") then
	    file.app_type=1
	elseif string.match(ovrrd_str, file.name .. "=2") then
	    file.app_type=2
	elseif string.match(ovrrd_str, file.name .. "=3") then
	    file.app_type=3
	elseif string.match(ovrrd_str, file.name .. "=4") then
	    file.app_type=0
	end
    end

    table.insert(xCatLookup(appt_hotfix(file.app_type)), file)

    custom_path =    CoverDirectoryLookup(file.app_type) .. app_short_title .. ".png"
    custom_path_id = CoverDirectoryLookup(file.app_type) .. file.name .. ".png"

    if custom_path and System.doesFileExist(custom_path) then
	file.icon_path = custom_path --custom cover by app name
    elseif custom_path_id and System.doesFileExist(custom_path_id) then
	file.icon_path = custom_path_id --custom cover by app id
    else
	if System.doesFileExist("ur0:/appmeta/" .. file.name .. "/icon0.png") then
	    file.icon_path = "ur0:/appmeta/" .. file.name .. "/icon0.png"  --app icon
	else
	    file.icon_path = "app0:/DATA/noimg.png" --blank grey
	end
    end
    return file.app_type, file.icon_path
end

-- Structure of TSV:
-- {
-- directory:bool, 
-- size:number, 
-- icon:Graphics.FileHandler(int?), 
-- icon_path:string, 
-- apptitle:string, 
-- name:string, 
-- app_type:number (0 homebrew, 1 psvita, 2 psp, 3 psx)
-- }
function CacheTitleTable()
    OneShotPrint() --Basic Loading Screen
    local file_over = System.openFile(cur_dir .. "/apptitlecache.dat", FCREATE)
    cur_quick_dir["apptitlecache.dat"] = true

    -- Clear apptitlecache.dat data. Might be necessary if you delete 2 apps and add 1?
    io.open(cur_dir .. "/apptitlecache.dat","w"):close()

    System.closeFile(file_over)

    file = io.open(cur_dir .. "/apptitlecache.dat", "w")

    for _, v in pairs(folders_table) do
	local entry_data = {v.directory, v.size, "-2121791736", v.icon_path, v.apptitle, v.name, v.app_type}
	for key, val in ipairs(entry_data) do
	    file:write(sanitize(val) .. "\t")	
	end
	file:seek("cur", -1)
	file:write("\n")
    end
    file:close()
end

function p_plus(plus_num)
    if setSounds ~= 0 then
	Sound.play(click, NO_LOOP)
    end
    if bottomMenu == true then
	menuSel = menuSel + 1
	if menuSel > 6 then
	    menuSel = 1
	end
    else
	p = p + plus_num
	if p <= curTotal then
	    GetNameSelected()
	end
	if showView == 5 then
	    if p > master_index+2 then
		master_index = p - 3
	    end
	elseif showView == 6 then
	  --if math.floor((p - 1) / 6) > base_y then	 -- more optimized but unused; somehow causes "grid camera refocus glitch"
	    if math.floor((p - 1) / 6) > math.floor((master_index - 1) / 6) then
		master_index = p - 6
	    end
	else
	    if p >= master_index then
		master_index = p
	    end
	end
    end
end

function p_minus(minus_num)
    if setSounds ~= 0 then
	Sound.play(click, NO_LOOP)
    end
    if bottomMenu == true then
	menuSel = menuSel - 1
	if menuSel < 1 then
	    menuSel = 6
	end
    else
	p = p - minus_num
	if p > 0 then
	    GetNameSelected()
	end
	if p <= master_index then
	    master_index = p
	end
    end
end

-- Loads cache if it exists, or generates a new one if it doesn't.
function LoadAppTitleTables()
    local applistReadTimer = Timer.new()

    files_table = {}
    folders_table = {}
    games_table = {}
    homebrews_table = {}
    psp_table = {}
    psx_table = {}
    recently_played_table = {}
    -- search_results_table = {}
    -- favorites_table = {}
    custom_table = {}

    -- RetroFlow integration! If enabled, it overrides all the standard functions with new, slower RetroFlow functions.
    if setRetroFlow==1 then
	-- Uncomment these to make it wholly switch over to the RetroFlow covers folders if RetroFlow is enabled.
	--covers_psv = "ux0:/data/RetroFlow/COVERS/Sony - PlayStation Vita/"
	--covers_psp = "ux0:/data/RetroFlow/COVERS/Sony - PlayStation Portable/"
	--covers_psx = "ux0:/data/RetroFlow/COVERS/Sony - PlayStation/"

	function xCatLookup(CatNum)	 -- CatNum = Showcat. (or sometimes "GetCovers"). Used very often.
	    if CatNum == 1 then		 return games_table
	    elseif CatNum == 2 then	 return homebrews_table
	    elseif CatNum == 3 then	 return psp_table
	    elseif CatNum == 4 then	 return psx_table
	    elseif CatNum == 5 then	 return n64_table
	    elseif CatNum == 6 then	 return snes_table
	    elseif CatNum == 7 then	 return nes_table
	  --elseif CatNum ==   then	 return nds_table
	    elseif CatNum == 8 then	 return gba_table
	    elseif CatNum == 9 then	 return gbc_table
	    elseif CatNum == 10 then	 return gb_table
	    elseif CatNum == 11 then	 return dreamcast_table
	    elseif CatNum == 12 then	 return sega_cd_table
	    elseif CatNum == 13 then	 return s32x_table
	    elseif CatNum == 14 then	 return md_table
	    elseif CatNum == 15 then	 return sms_table
	    elseif CatNum == 16 then	 return gg_table
	    elseif CatNum == 17 then	 return tg16_table
	    elseif CatNum == 18 then	 return tgcd_table
	    elseif CatNum == 19 then	 return pce_table
	    elseif CatNum == 20 then	 return pcecd_table
	    elseif CatNum == 21 then	 return amiga_table
	    elseif CatNum == 22 then	 return c64_table
	    elseif CatNum == 23 then	 return wswan_col_table
	    elseif CatNum == 24 then	 return wswan_table
	  --elseif CatNum ==    then	 return scummvm_table
	    elseif CatNum == 25 then	 return pico8_table
	    elseif CatNum == 26 then	 return msx2_table
	    elseif CatNum == 27 then	 return msx1_table
	    elseif CatNum == 28 then	 return zxs_table
	    elseif CatNum == 29 then	 return atari_7800_table
	    elseif CatNum == 30 then	 return atari_5200_table
	    elseif CatNum == 31 then	 return atari_2600_table
	    elseif CatNum == 32 then	 return atari_lynx_table
	    elseif CatNum == 33 then	 return colecovision_table
	    elseif CatNum == 34 then	 return vectrex_table
	  --elseif CatNum ==    then	 return fba_table
	  --elseif CatNum ==    then	 return mame_2003_plus_table
	  --elseif CatNum ==    then	 return mame_2000_table
	  --elseif CatNum ==    then	 return neogeo_table
	    elseif CatNum == 35 then	 return ngpc_table
	    elseif CatNum == 36 then	 return recently_played_table
	    elseif CatNum == 37 then	 return custom_table
	    else      			 return files_table
	    end
	end

	function xTextLookup(CatTextNum)
	    if CatTextNum == 1 then	  return lang_lines[1] --PS VITA
	    elseif CatTextNum == 2 then	  return lang_lines[2] --HOMEBREWS
	    elseif CatTextNum == 3 then	  return lang_lines[3] --PSP
	    elseif CatTextNum == 4 then	  return lang_lines[4] --PSX
	    elseif CatTextNum == 5 then	  return lang_lines[33] --Nintendo 64
	    elseif CatTextNum == 6 then	  return lang_lines[34] --Super Nintendo
	    elseif CatTextNum == 7 then	  return lang_lines[35] --Nintendo Entertainment System
	  --elseif CatTextNum ==   then   return "nds_table"
	    elseif CatTextNum == 8 then	  return lang_lines[36] --Game Boy Advance
	    elseif CatTextNum == 9 then   return lang_lines[37] --Game Boy Color
	    elseif CatTextNum == 10 then  return lang_lines[38] --Game Boy
	    elseif CatTextNum == 11 then  return lang_lines[59] --Sega Dreamcast
	    elseif CatTextNum == 12 then  return lang_lines[60] --Sega CD
	    elseif CatTextNum == 13 then  return lang_lines[61] --Sega 32X
	    elseif CatTextNum == 14 then  return lang_lines[39] --Sega Genesis/Mega Drive
	    elseif CatTextNum == 15 then  return lang_lines[40] --Sega Master System
	    elseif CatTextNum == 16 then  return lang_lines[41] --Sega Game Gear
	    elseif CatTextNum == 17 then  return lang_lines[44] --TurboGrafx-16
	    elseif CatTextNum == 18 then  return lang_lines[62] --TurboGrafx-CD
	    elseif CatTextNum == 19 then  return lang_lines[45] --PC Engine
	    elseif CatTextNum == 20 then  return lang_lines[63] --PC Engine CD
	    elseif CatTextNum == 21 then  return lang_lines[43] --Amiga
	    elseif CatTextNum == 22 then  return lang_lines[64] --Commodore 64
	    elseif CatTextNum == 23 then  return lang_lines[86] --WonderSwan Color
	    elseif CatTextNum == 24 then  return lang_lines[87] --WonderSwan
	  --elseif CatTextNum ==    then  return "scummvm_table"
	    elseif CatTextNum == 25 then  return lang_lines[88] --PICO-8
	    elseif CatTextNum == 26 then  return lang_lines[110] --MSX2
	    elseif CatTextNum == 27 then  return lang_lines[111] --MSX
	    elseif CatTextNum == 28 then  return lang_lines[112] --ZX Spectrum
	    elseif CatTextNum == 29 then  return lang_lines[113] --Atari 7800
	    elseif CatTextNum == 30 then  return lang_lines[114] --Atari 5200
	    elseif CatTextNum == 31 then  return lang_lines[115] --Atari 2600
	    elseif CatTextNum == 32 then  return lang_lines[116] --Atari Lynx
	    elseif CatTextNum == 33 then  return lang_lines[117] --ColecoVision
	    elseif CatTextNum == 34 then  return lang_lines[118] --Vectrex
	  --elseif CatTextNum ==    then  return "fba_table"
	  --elseif CatTextNum ==    then  return "mame_2003_plus_table"
	  --elseif CatTextNum ==    then  return "mame_2000_table"
	  --elseif CatTextNum ==    then  return "neogeo_table"
	    elseif CatTextNum == 35 then  return lang_lines[119] --Neo Geo Pocket Color
	    elseif CatTextNum == 36 then  return lang_lines[108] --Recently Played
	    elseif CatTextNum == 37 then  return lang_lines[49] --CUSTOM
	    else			  return lang_lines[5] --ALL
	    end
	end

	function CoverDirectoryLookup(getCovers)
	    if getCovers == 2 then	 return covers_psp
	    elseif getCovers == 3 then	 return covers_psx
	    elseif getCovers == 5 then	 return "ux0:/data/RetroFlow/COVERS/Nintendo - Nintendo 64/"
	    elseif getCovers == 6 then	 return "ux0:/data/RetroFlow/COVERS/Nintendo - Super Nintendo Entertainment System/"
	    elseif getCovers == 7 then	 return "ux0:/data/RetroFlow/COVERS/Nintendo - Nintendo Entertainment System/"
	  --elseif getCovers ==   then	 return "ux0:/data/RetroFlow/COVERS/Nintendo - Nintendo DS/"
	    elseif getCovers == 8 then	 return "ux0:/data/RetroFlow/COVERS/Nintendo - Game Boy Advance/"
	    elseif getCovers == 9 then	 return "ux0:/data/RetroFlow/COVERS/Nintendo - Game Boy Color/"
	    elseif getCovers == 10 then	 return "ux0:/data/RetroFlow/COVERS/Nintendo - Game Boy/"
	    elseif getCovers == 11 then	 return "ux0:/data/RetroFlow/COVERS/Sega - Dreamcast/"
	    elseif getCovers == 12 then	 return "ux0:/data/RetroFlow/COVERS/Sega - Mega-CD - Sega CD/"
	    elseif getCovers == 13 then	 return "ux0:/data/RetroFlow/COVERS/Sega - 32X/"
	    elseif getCovers == 14 then	 return "ux0:/data/RetroFlow/COVERS/Sega - Mega Drive - Genesis/"
	    elseif getCovers == 15 then	 return "ux0:/data/RetroFlow/COVERS/Sega - Master System - Mark III/"
	    elseif getCovers == 16 then	 return "ux0:/data/RetroFlow/COVERS/Sega - Game Gear/"
	    elseif getCovers == 17 then	 return "ux0:/data/RetroFlow/COVERS/NEC - TurboGrafx 16/"
	    elseif getCovers == 18 then	 return "ux0:/data/RetroFlow/COVERS/NEC - TurboGrafx CD/"
	    elseif getCovers == 19 then	 return "ux0:/data/RetroFlow/COVERS/NEC - PC Engine/"
	    elseif getCovers == 20 then	 return "ux0:/data/RetroFlow/COVERS/NEC - PC Engine CD/"
	    elseif getCovers == 21 then	 return "ux0:/data/RetroFlow/COVERS/Commodore - Amiga/"
	    elseif getCovers == 22 then	 return "ux0:/data/RetroFlow/COVERS/Commodore - 64/"
	    elseif getCovers == 23 then	 return "ux0:/data/RetroFlow/COVERS/Bandai - WonderSwan Color/"
	    elseif getCovers == 24 then	 return "ux0:/data/RetroFlow/COVERS/Bandai - WonderSwan/"
	  --elseif getCovers ==    then	 return "ux0:/data/RetroFlow/COVERS/ScummVM/"
	    elseif getCovers == 25 then	 return "ux0:/data/RetroFlow/COVERS/Lexaloffle Games - Pico-8/"
	    elseif getCovers == 26 then	 return "ux0:/data/RetroFlow/COVERS/Microsoft - MSX2/"
	    elseif getCovers == 27 then	 return "ux0:/data/RetroFlow/COVERS/Microsoft - MSX/"
	    elseif getCovers == 28 then	 return "ux0:/data/RetroFlow/COVERS/Sinclair - ZX Spectrum/"
	    elseif getCovers == 29 then	 return "ux0:/data/RetroFlow/COVERS/Atari - 7800/"
	    elseif getCovers == 30 then	 return "ux0:/data/RetroFlow/COVERS/Atari - 5200/"
	    elseif getCovers == 31 then	 return "ux0:/data/RetroFlow/COVERS/Atari - 2600/"
	    elseif getCovers == 32 then	 return "ux0:/data/RetroFlow/COVERS/Atari - Lynx/"
	    elseif getCovers == 33 then	 return "ux0:/data/RetroFlow/COVERS/Coleco - ColecoVision/"
	    elseif getCovers == 34 then	 return "ux0:/data/RetroFlow/COVERS/GCE - Vectrex/"
	  --elseif getCovers ==    then	 return "ux0:/data/RetroFlow/COVERS/FBA 2012/"
	  --elseif getCovers ==    then	 return "ux0:/data/RetroFlow/COVERS/MAME 2003 Plus/"
	  --elseif getCovers ==    then	 return "ux0:/data/RetroFlow/COVERS/MAME 2000/"
	  --elseif getCovers ==    then	 return "ux0:/data/RetroFlow/COVERS/SNK - Neo Geo - FBA 2012/"
	    elseif getCovers == 35 then	 return "ux0:/data/RetroFlow/COVERS/SNK - Neo Geo Pocket Color/"
	    else			 return covers_psv
	    end
	end

	load_RetroFlow()

    else	 --elseif RetroflowAssetsAreLoaded == false then
	function xCatLookup(CatNum)	 -- CatNum = Showcat (for example). Used very often.
	    if CatNum == 1 then		 return games_table
	    elseif CatNum == 2 then	 return homebrews_table
	    elseif CatNum == 3 then	 return psp_table
	    elseif CatNum == 4 then	 return psx_table
	    elseif CatNum == 5 then	 return recently_played_table
	    elseif CatNum == 6 then	 return custom_table
	    else			 return files_table
	    end
	end

	function xTextLookup(CatTextNum)
	    if CatTextNum == 1 then	 return lang_lines[1]	 --PS VITA
	    elseif CatTextNum == 2 then	 return lang_lines[2]	 --HOMEBREWS
	    elseif CatTextNum == 3 then	 return lang_lines[3]	 --PSP
	    elseif CatTextNum == 4 then	 return lang_lines[4]	 --PSX
	    elseif CatTextNum == 5 then	 return lang_lines[108]	 --Recently Played
	    elseif CatTextNum == 6 then	 return lang_lines[49]	 --CUSTOM
	    else			 return lang_lines[5]	 --ALL
	    end
	end

    end

    local real_app_list = System.listDirectory(System.currentDirectory())

    local newAppsMsg = ""

    local cover_dir_psv = switch_generator(covers_psv)
    local cover_dir_psp = switch_generator(covers_psp)
    local cover_dir_psx = switch_generator(covers_psx)

    if cur_quick_dir["apptitlecache.dat"] then			  -- Faster than System.doesFileExist(...)
	local quick_app_list = {}
	local cover_path = ""
	local cover_list = {}
	local custom_path = ""
	local custom_path_id = ""

	for k, v in ipairs(real_app_list) do
	    quick_app_list[v.name] = k
	end
	for line in io.lines(cur_dir .. "/apptitlecache.dat") do
	    if not (line == "" or line == " " or line == "\n") then
                -- {directory,size,icon,icon_path,apptitle,name,app_type}
                local app = stringSplit(line, "\t")
                file = {}
                file.directory = toboolean(app[1])
                file.size = tonumber(app[2])
                --file.icon = tonumber(app[3])			  -- Uses imgCoverTmp instead.
                --file.icon_path = tostring(app[4])		  -- Uses instant cover finder instead.
                file.apptitle = tostring(app[5])
                file.name = tostring(app[6])
                file.app_type = tonumber(app[7])

		file.launch_type = 0

		-- START INSTANT COVER FINDER
		cover_path = CoverDirectoryLookup(file.app_type)
	      --if cover_path == covers_psv then
	      --    cover_list = cover_dir_psv
		if cover_path == covers_psp then
		    cover_list = cover_dir_psp
		elseif cover_path == covers_psx then
		    cover_list = cover_dir_psx
		else
		    cover_list = cover_dir_psv
		end
		custom_path = file.apptitle .. ".png"		  -- needs sanitization?
		if cover_list[custom_path] then
		    file.icon_path = cover_path .. custom_path
		    goto cover_found
		end
		custom_path_id = file.name .. ".png"
		if cover_list[custom_path_id] then
		    file.icon_path = cover_path .. custom_path_id
		    goto cover_found
		end
		file.icon_path = "ur0:/appmeta/" .. file.name .. "/icon0.png"
		::cover_found::
		-- END INSTANT COVER FINDER

		if quick_app_list[file.name] then
		    if real_app_list[(quick_app_list[file.name])].name == nil then
			-- do nothing - entry is a duplicate
		    elseif file.app_type == 1 then
			table.insert(folders_table, file)
		      --table.insert(files_table, file)
			table.insert(games_table, file) 
		    elseif file.app_type == 2 then
			table.insert(folders_table, file)
		      --if adr_launcher == 0 then
		      --    table.insert(files_table, file)
		      --end
			table.insert(psp_table, file) 
		    elseif file.app_type == 3 then
			table.insert(folders_table, file)
		      --table.insert(files_table, file)
			table.insert(psx_table, file)
		    else
			table.insert(folders_table, file)
		      --table.insert(files_table, file)
			table.insert(homebrews_table, file)
		    end
		    real_app_list[(quick_app_list[file.name])].name = nil
		else
		    newAppsMsg = newAppsMsg .. "-" .. file.name .. "\n"
		end
	    end		
	end
    end

    -- START AUTOMATIC CACHE ADDER
    total_apps = #real_app_list
    for i=0, total_apps do
	k = total_apps - i			 -- reversefor k, v in ipairs(real_app_list) do
	local v = real_app_list[k]
	if v					 -- I have no idea why it needs this "if v~=nil" (shortened to "if v") but it crashes without it.
	 and (
	  (v.name==nil)				 -- Rolling cache relies on a cool trick of just deleting the name data if an app was successfully loaded from cache.
	  or (v.directory==false)		 -- All real apps are folders.
	  or (v.name:len()~=9)			 -- All real apps are 9 letters long folders.
	  or (System.doesFileExist(working_dir .. "/" .. v.name .. "/sce_sys/param.sfo")==false) -- Slows loading time but hard-stops anything else that might come through. Example file it's looking for:  "ux0:/app/VITASHELL/sce_sys/param.sfo"
	 ) then
	    table.remove(real_app_list, k)
	end
    end
    if #real_app_list > 0 then
	local file_over = System.openFile(cur_dir .. "/overrides.dat", FREAD)
	local filesize = System.sizeFile(file_over)
	ovrrd_str = System.readFile(file_over, filesize)
	System.closeFile(file_over)

	-- psx.lua taken from Retroflow 3.4 and completely repurposed
	local file_over = System.openFile("app0:addons/psx.lua", FREAD)
	local filesize = System.sizeFile(file_over)
	psxdb = System.readFile(file_over, filesize)
	System.closeFile(file_over)

	for _, file in pairs(real_app_list) do
	    newAppsMsg = newAppsMsg .. "+" .. file.name .. "\n"
	    local custom_path, custom_path_id, app_type = nil, nil, nil
	    info = System.extractSfo(working_dir .. "/" .. file.name .. "/sce_sys/param.sfo")
	    app_short_title = sanitize(info.short_title)
	    file.launch_type = 0
	    if string.match(file.name, "PCS") and not string.match(file.name, "PCSI") then
		-- PSVita Games
		file.app_type = 1
	    elseif System.doesFileExist(working_dir .. "/" .. file.name .. "/data/boot.bin") and not System.doesFileExist("ux0:pspemu/PSP/GAME/" .. file.name .. "/EBOOT.PBP") then
		-- PSP Games
		pspemu_translate_tmp = readBin(working_dir .. "/" .. file.name .. "/data/boot.bin", false)	 -- example: "SLUS00453"
		if pspemu_translate_tmp and pspemu_translate_tmp ~= "-" and string.match(psxdb, pspemu_translate_tmp) then
		    -- PSX
		    file.app_type = 3
		else
		    -- PSP
		    file.app_type = 2
		end
	    elseif System.doesFileExist(working_dir .. "/" .. file.name .. "/data/boot.bin") and System.doesFileExist("ux0:pspemu/PSP/GAME/" .. file.name .. "/EBOOT.PBP") then
		-- PSX Games
		file.app_type = 3
	    else
		-- Homebrews.
		file.app_type=0
	    end
	    -- Respec applies overrides, adds item to table, and sets icon_path. Also used for triangle menu overrides.
	    file.app_type, file.icon_path = Respec_Entry(file, pspemu_translate_tmp)

	    --file.icon = imgCoverTmp		--add blank icon to all. Not necessary anymore
        
	    file.apptitle = app_short_title
	    table.insert(folders_table, file)
	  --table.insert(files_table, file)
	end
    end
    table.sort(games_table, function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)
    table.sort(homebrews_table, function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)
    table.sort(psp_table, function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)
    table.sort(psx_table, function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)
  --table.sort(files_table, function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)

    if newAppsMsg ~= "" then	 -- Always rewrites applist/cache when a title is added/removed.
	table.sort(folders_table, function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)
      --table.sort(files_table, function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)
	CacheTitleTable()
	WriteAppList()
      --System.setMessage(newAppsMsg, false, BUTTON_OK)
    end

    if setRetroFlow==1 then
	files_table = TableConcat(folders_table, files_table)
	folders_table = {}
    else
	files_table = folders_table	 -- folders_table is for everything that needs cached. Without it, adding Adrenaline Launcher will be much harder.
    end
    table.sort(files_table, function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)

    applistReadTime = Timer.getTime(applistReadTimer)
    Timer.destroy(applistReadTimer)

    table.sort(files_table, function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)
    ovrrd_str = ""

    if showRecentlyPlayed == 1 then
	ReadCustomSort("lastplayedgame.dat", recently_played_table)
    end
    ReadCustomSort("customsort.dat", custom_table)

    -- LAST PLAYED GAME
    if ((setRetroFlow==1 and startCategory==38) or (setRetroFlow~=1 and startCategory==7))
    and oneLoopTimer	 -- No "return to last played game" when toggling RetroFlow.
    and cur_quick_dir["lastplayedgame.dat"] then

	local lastPlayedGameFile = assert(io.open(cur_dir .. "/lastplayedgame.dat", "r"), "Failed to open lastplayedgame.dat")
	local lastPlayedGameCat = lastPlayedGameFile:read("*line")
	local lastPlayedGameID = lastPlayedGameFile:read("*line")
	lastPlayedGameFile:close()

	if (tonumber(lastPlayedGameCat) == nil) or (lastPlayedGameCat:len() > 3) then
	    startCategory = 1
	    showCat = 1
	else
	    showCat = tonumber(lastPlayedGameCat)
	    local cur_cat = xCatLookup(showCat)
	    curTotal = #cur_cat			 -- curTotal needs set for p_plus to work in SwitchView

	    for i=1, curTotal do
		if cur_cat[i].name == lastPlayedGameID then
		    p_plus(i - 1)
		    break
		end
            end
        end
    end
    categoryText = xTextLookup(showCat)
end

-- Sects: [1]=directory, [2]=size, [3]=icon, [4]=icon_path, [5]=apptitle, [6]=name, [7]=app_type
function UpdateCacheSect(app_id, working_sect, new_path)
    if cur_quick_dir["apptitlecache.dat"] then
	local inf = assert(io.open(cur_dir .. "/apptitlecache.dat", "r"), "Failed to open apptitlecache.dat")
	local lines = ""
	while(true) do
	    local line = inf:read("*line")
	    if not line then break end
	    if string.find(line, app_id, 1) then
	        local app = stringSplit(line, "\t")
		app[working_sect] = new_path
		new_line = table.concat(app,"\t")
		lines = lines .. new_line .. "\n"
	    else
	        lines = lines .. line .. "\n"
	    end
	end
	inf:close()
	file = io.open(cur_dir .. "/apptitlecache.dat", "w")
	file:write(lines)
	file:close()
    end
end

function loadImage(img_path)
    imgTmp = Graphics.loadImage(img_path)
end

function getAppSize(dir)
    local size = 0
    local function get_size(dir)
        local d = System.listDirectory(dir) or {}
        for _, v in ipairs(d) do
            if v.directory then
                get_size(dir .. "/" .. v.name)
            else
                size = size + v.size
            end
        end
    end
    get_size(dir)
    return size
end

function GetNameSelected()
    if #xCatLookup(showCat) > 0 then	 --if the currently-shown category isn't empty
--	if xCatLookup(showCat)[p].launch_type == 0 then
	    app_short_title = xCatLookup(showCat)[p].apptitle
--	else
--	    --unused. Replaces every " (" with "(", then delete the brackets and everything in them.
--	    app_short_title = xCatLookup(showCat)[p].apptitle:gsub(" %(", "("):gsub('%b()', '')
--	end
    else
	app_short_title = "-"
    end
end


function GetInfoSelected()
    appdir = ""
    app_title = "-"
    icon_path = "app0:/DATA/noimg.png"
    pic_path = "app0:/DATA/noimg.png"
    apptype = 0
    app_size_text = "0"
    app_titleid = "000000000"
    app_version = "00.00"
    DISC_ID = false

    if #xCatLookup(showCat) > 0 then --if the currently-shown category isn't empty then:
	apptype = xCatLookup(showCat)[p].app_type
        if xCatLookup(showCat)[p].launch_type == 0 then
	    if System.doesFileExist(working_dir .. "/" .. xCatLookup(showCat)[p].name .. "/sce_sys/param.sfo") then
		appdir=working_dir .. "/" .. xCatLookup(showCat)[p].name	    --example: "ux0:app/SLUS00453"
		app_size_text = "Size : " .. string.format("%02d", getAppSize(appdir)/1024/1024) .. "Mb"
        	info = System.extractSfo(appdir .. "/sce_sys/param.sfo")
        	icon_path = "ur0:/appmeta/" .. xCatLookup(showCat)[p].name .. "/icon0.png"
        	pic_path = "ur0:/appmeta/" .. xCatLookup(showCat)[p].name .. "/pic0.png"
		app_title = tostring(info.title)
		app_short_title = tostring(info.short_title)
		app_titleid = tostring(info.titleid)
		app_version = tostring(info.version)
		if apptype==2 or apptype==3 then
		    DISC_ID = readBin(appdir .. "/data/boot.bin", true)		 -- app_size_text is now modified in readBin() for PSP/PS1 games.
		end
	    end
	else
	    if xCatLookup(showCat)[p].directory then
		appdir=working_dir .. "/" .. xCatLookup(showCat)[p].name	 --example: "ux0:pspemu/PSP/GAME/SLUS00453"
		app_size = getAppSize(appdir)
	    else
		app_size = xCatLookup(showCat)[p].size
	    end
	    if app_size < 900000 and apptype ~= 3 then
		app_size_text = "Size: 0Mb, " .. string.format("%02d", app_size/1024) .. "Kb"
	    else
		app_size_text = "Size : " .. string.format("%02d", app_size/1024/1024) .. "Mb"
	    end
	    icon_path = xSIconLookup(apptype)
	    if apptype == 2 then
		pic_path = "ux0:data/RetroFlow/BACKGROUNDS/Sony - PlayStation Portable/"
	    elseif apptype == 3 then
		pic_path = "ux0:data/RetroFlow/BACKGROUNDS/Sony - PlayStation/"
	    elseif apptype == 25 then
		pic_path = "ux0:data/RetroFlow/BACKGROUNDS/Lexaloffle Games - Pico-8/"
	    else
		pic_path = xRomDirLookup(apptype):gsub("/ROMS/", "/BACKGROUNDS/")
	    end
	    pic_path = pic_path .. (xCatLookup(showCat)[p].name:match("(.+)%..+$") or xCatLookup(showCat)[p].name) .. ".png"	 -- cuts everything after the last "." then add ".png". Example:   "Donkey-Kong.n64" --> "Donkey-Kong"
	    app_title = xCatLookup(showCat)[p].apptitle
	    app_short_title = xCatLookup(showCat)[p].apptitle:gsub(" %(", "("):gsub('%b()', '')	    -- replaces every " (" with "(", then delete the brackets and everything in them.
	    if app_title:match("%((.+)%)") then		 -- input: "Wario Land (USA) (NTSC).gba" ---> output: "(USA) (NTSC)" @@ input: "Wario Land.gba" ---> output: nothing (FAILS THE "IF" STATEMENT)
		app_version = app_title:match("%((.+)%)"):gsub("%) %(", ', ')	 -- the gsub takes out midsection parenthesis like this: input: "(USA) (NTSC)" ---> output: (USA, NTSC)
	    end
	end
    end
end

function close_triangle_preview()
    GetNameSelected()
    oldpad = pad			 -- prevents launching next game accidentally when overriding.
    showMenu = 0
    prvRotY = 0
    spin_allowance = 0
    if setBackground > 0.5 then
	Render.useTexture(modBackground, imgCustomBack)
    end
end

function close_utility_menu()
    utilityMenu = false
    menuX = 0
    menuY = menuItems
  --Graphics.freeImage(imgUtilityBorder)
end

function check_for_out_of_bounds()
    curTotal = #xCatLookup(showCat)
    if curTotal == 0 then
        p = 0
        master_index = p
    end
    if p < 1 then
        p = curTotal
	if showView == 5 then
	    if curTotal > 3 then
		master_index = p - 3
	    else
		master_index = 1
	    end
	elseif showView == 6 and curTotal <= 12 then	 --@@ NEW! Less jumpy now.
	    master_index = 1				 --@@ NEW! Less jumpy now.
        elseif curTotal > 0 then
            master_index = p	 -- 0
        end
        startCovers = false
        GetNameSelected()
    elseif p > curTotal then
        p = 1
        master_index = p
        startCovers = false
        GetNameSelected()
    end
end

function OverrideCategory()
    --[1]=VITA, [2]=PSP, [3]=PS1, [4]=HOMEBREWS. (0 is default but it does nothing right now)
    if tmpappcat>0 and cur_quick_dir["overrides.dat"] then
	local inf = assert(io.open(cur_dir .. "/overrides.dat", "rw"), "Failed to open overrides.dat")
	local lines = ""
	while(true) do
	    local line = inf:read("*line")
	    if not line then break end
	    if not string.find(line, app_titleid .. "", 1) then
		lines = lines .. line .. "\n"
	    end
	end
	ovrrd_str = app_titleid .. "=" .. tmpappcat .. "\n"
	lines = lines .. ovrrd_str
	inf:close()
	file = io.open(cur_dir .. "/overrides.dat", "w")
	file:write(lines)
	file:close()

	-- Respec applies overrides, adds item to table, and set icon_path. Also used during startup scan.
	xCatLookup(showCat)[p].app_type, xCatLookup(showCat)[p].icon_path = Respec_Entry(xCatLookup(showCat)[p], nil)
	ovrrd_str = ""

	-- force icon change
	xCatLookup(showCat)[p].ricon = Graphics.loadImage(xCatLookup(showCat)[p].icon_path)

	UpdateCacheSect(app_titleid, 7, tmpappcat)

	-- Tidy up: remove game from old table, sort target table.
	for k, v in pairs(xCatLookup(appt_hotfix(apptype))) do
	    if (v.name ~= nil) and (v.name == app_titleid) then
		table.remove(xCatLookup(appt_hotfix(apptype)), k)
		break
	    end
	end
	table.sort(xCatLookup(appt_hotfix(tmpappcat)), function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)
	    
    end
end

function DownloadCover(entry)
    local downloadable_file = ""
    local output_folder = ""
    local output_file_location = ""
    local custom_path = ""

    apptype = entry.app_type
    launch_mode = entry.launch_type

    -- ID reader for PSP/PS1 games.
    if inPreview==false and launch_mode==0 and (apptype==2 or apptype==3) then
	DISC_ID =  readBin(working_dir .. "/" .. entry.name .. "/data/boot.bin", true)
    end

    downloadable_file =
     (
	(apptype==2 and		 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/PSP/")			 -- PSP
     or (apptype==3 and		 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/PS1/")			 -- PS1
     or (setRetroFlow ~= 1 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/PSVita/")			 -- Vita & Homebrews
     or (apptype==5 and		 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/N64/Covers/")		 -- N64
     or (apptype==6 and		 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/SNES/Covers/")		 -- SNES
     or (apptype==7 and		 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/NES/Covers/")		 -- NES
  -- or (apptype==  and		 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/NDS/Covers/")		 -- NDS @@ unused
     or (apptype==8 and		 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/GBA/Covers/")		 -- GBA
     or (apptype==9 and		 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/GBC/Covers/")		 -- GBC
     or (apptype==10 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/GB/Covers/")		 -- GB
     or (apptype==11 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/DC/Covers/")		 -- DREAMCAST
     or (apptype==12 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/SEGA_CD/Covers/")	 -- SEGA_CD
     or (apptype==13 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/32X/Covers/")		 -- S32X
     or (apptype==14 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/MD/Covers/")		 -- MD
     or (apptype==15 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/SMS/Covers/")		 -- SMS
     or (apptype==16 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/GG/Covers/")		 -- GG
     or (apptype==17 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/TG16/Covers/")		 -- TG16
     or (apptype==18 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/TG_CD/Covers/")		 -- TGCD
     or (apptype==19 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/PCE/Covers/")		 -- PCE
     or (apptype==20 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/PCE_CD/Covers/")	 -- PCECD
     or (apptype==21 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/AMIGA/Covers/")		 -- AMIGA
     or (apptype==22 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/C64/Covers/")		 -- C64
     or (apptype==23 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/WSWAN_COL/Covers/")	 -- WSCAN_COL
     or (apptype==24 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/WSWAN/Covers/")		 -- WSWAN
--@@ or (apptype==   and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/SCUMMVM/Covers/")	 --@@ new but unused. SCUMMVM
     or (apptype==25 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/PICO-8/Covers/")	 -- PICO-8 @@ invalid
     or (apptype==26 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/MSX2/Covers/")		 -- MSX2
     or (apptype==27 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/MSX/Covers/")		 -- MSX1
     or (apptype==28 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/ZXS/Covers/")		 -- ZXS	 
     or (apptype==29 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/ATARI_7800/Covers/")	 -- ATARI_7800
     or (apptype==30 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/ATARI_5200/Covers/")	 -- ATARI_5200
     or (apptype==31 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/ATARI_2600/Covers/")	 -- ATARI_2600
     or (apptype==32 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/ATARI_LYNX/Covers/")	 -- ATARI_LYNX
     or (apptype==33 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/COLECOVISION/Covers/")	 -- COLECOVISION
     or (apptype==34 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/VECTREX/Covers/")	 -- VECTREX
  -- or (apptype==   and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/MAME/Covers/")		 -- FBA @@unused. Shares mame archive
  -- or (apptype==   and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/MAME/Covers/")		 -- MAME_2003_PLUS @@ unused
  -- or (apptype==   and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/MAME/Covers/")		 -- MAME_2000 @@ unused
  -- or (apptype==   and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/NEOGEO/Covers/")	 -- NEOGEO @@ unused
     or (apptype==35 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/NEOGEO_PC/Covers/")	 -- NGPC
     or (			 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/PSVita/")			 -- Vita & Homebrews
     )
     ..
     (
        (launch_mode==0 and	 (DISC_ID or entry.name))		 -- For real apps. Relatively simple. Example: "VITASHELL"
     or (entry.name:match("(.+)%..+$")~=nil and entry.name:match("%((.+)%)")==nil and entry.name:match("(.+)%..+$") .. " (USA)")	 -- Add " (USA)" to RetroFlows with no region specified. Ex: "Donkey Kong.n64" -------> "Donkey Kong (USA)"
     or (entry.name:match("(.+)%..+$") or entry.name)			 -- For RetroFlow entries. If item has a period at the end, this removes it... otherwise it'll use the whole file name. Ex: "Donkey Kong (USA).n64" --> "Donkey Kong (USA)"
     ):gsub("%%", '%%25'):gsub("%s+", '%%20') .. ".png"			 -- Converts spacebars to "%20" and percentage signs to "%25" since you can't those in a website address, then adds ".png" Ex: "Donkey Kong (USA)" ---> "Donkey%20Kong%20(USA).png"

     --System.setMessage(downloadable_file, false, BUTTON_OK)		 -- debug

    custom_path = (entry.name:match("(.+)%..+$") or entry.name) .. ".png"
    System.deleteFile("ux0:/data/HexFlow/" .. custom_path)		 -- if cover already exists, delete it before trying to download.

    output_folder = CoverDirectoryLookup(apptype)			 -- Ex:  "ux0:/data/HexFlow/COVERS/PSVITA/"
    System.createDirectory(output_folder)				 -- Prevents Nintendo DS cover download crash in experimental builds.

    Network.downloadFile(downloadable_file, "ux0:/data/HexFlow/" .. custom_path)

    if System.doesFileExist("ux0:/data/HexFlow/" .. custom_path) then
	tmpfile = System.openFile("ux0:/data/HexFlow/" .. custom_path, FREAD)
	size = System.sizeFile(tmpfile)
	System.closeFile(tmpfile)
	if size < 1024 then
	    System.deleteFile("ux0:/data/HexFlow/" .. custom_path)
	else
	    output_file_location = output_folder .. custom_path:gsub('%%25', "%%"):gsub('%%20', " ")
	    System.rename("ux0:/data/HexFlow/" .. custom_path, output_file_location)
	    System.deleteFile("ux0:/data/HexFlow/" .. custom_path)	 -- just delete file if rename operation somehow failed.
	    entry.icon_path = output_file_location
	    return output_file_location
	end
    end
end

function DownloadSnap(entry)
    local downloadable_file = ""
    local output_folder = ""
    local output_file_location = ""
    local custom_path = ""

    apptype = entry.app_type
    launch_mode = entry.launch_type

    -- ID reader for PSP/PS1 games.
    if inPreview==false and launch_mode==0 and (apptype==2 or apptype==3) then
	DISC_ID =  readBin(working_dir .. "/" .. entry.name .. "/data/boot.bin", true)
    end

    downloadable_file =
     (
	(apptype==2 and		 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/PSP/Named_Snaps/")								 -- PSP
     or (apptype==3 and		 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/PS1/Named_Snaps/")								 -- PS1
     or (setRetroFlow ~= 1 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/PSVita/Names_Snaps/")									 -- Vita & Homebrews @@ invalid
     or (apptype==5 and		 "https://raw.githubusercontent.com/libretro-thumbnails/Nintendo_-_Nintendo_64/ec7430189022b591a8fb0fa16101201f861363f8/Named_Snaps/")				 -- N64
     or (apptype==6 and		 "https://raw.githubusercontent.com/libretro-thumbnails/Nintendo_-_Super_Nintendo_Entertainment_System/5c469e48755fec26b4b9d651b6962a2cdea3133d/Named_Snaps/")	 -- SNES
     or (apptype==7 and		 "https://raw.githubusercontent.com/libretro-thumbnails/Nintendo_-_Nintendo_Entertainment_System/f4415b21a256bcbe7b30a9d71a571d6ba4815c71/Named_Snaps/")	 -- NES
  -- or (apptype==  and		 "https://raw.githubusercontent.com/libretro-thumbnails/Nintendo_-_Nintendo_DS/bdbcbae29f2b2bbfc9ffb73fce5a86cea1a58521/Named_Snaps/")				 -- NDS @@ unused
     or (apptype==8 and		 "https://raw.githubusercontent.com/libretro-thumbnails/Nintendo_-_Game_Boy_Advance/fd58a8fae1cec5857393c0405c3d0514c7fdf6cf/Named_Snaps/")			 -- GBA
     or (apptype==9 and		 "https://raw.githubusercontent.com/libretro-thumbnails/Nintendo_-_Game_Boy_Color/a0cc546d2b4e2eebefdcf91b90ae3601c377c3ce/Named_Snaps/")			 -- GBC
     or (apptype==10 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Nintendo_-_Game_Boy/d5ad94ba8c5159381d7f618ec987e609d23ae203/Named_Snaps/")				 -- GB
     or (apptype==11 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/DC/Named_Snaps/")								 -- DREAMCAST
     or (apptype==12 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Sega_-_Mega-CD_-_Sega_CD/a8737a2a394645f27415f7346ac2ceb0cfcd0942/Named_Snaps/")			 -- SEGA_CD
     or (apptype==13 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Sega_-_32X/4deb45e651e29506a7bfc440408b3343f0e1a3ae/Named_Snaps/")					 -- S32X
     or (apptype==14 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Sega_-_Mega_Drive_-_Genesis/6ac232741f979a6f0aa54d077ff392fe170f4725/Named_Snaps/")			 -- MD
     or (apptype==15 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Sega_-_Master_System_-_Mark_III/02f8c7f989db6124475b7e0978c27af8534655eb/Named_Snaps/")			 -- SMS
     or (apptype==16 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Sega_-_Game_Gear/b99b424d2adcf5ccd45c372db2c15f01653f2b92/Named_Snaps/")				 -- GG
     or (apptype==17 and	 "https://raw.githubusercontent.com/libretro-thumbnails/NEC_-_PC_Engine_-_TurboGrafx_16/d0d6e27f84d757416799e432154e0adcadb154c9/Named_Snaps/")			 -- TG16
     or (apptype==18 and	 "https://raw.githubusercontent.com/libretro-thumbnails/NEC_-_PC_Engine_CD_-_TurboGrafx-CD/cd554a5cdca862f090e6c3f9510a3b1b6c2d5b38/Named_Snaps/")		 -- TGCD
     or (apptype==19 and	 "https://raw.githubusercontent.com/libretro-thumbnails/NEC_-_PC_Engine_-_TurboGrafx_16/d0d6e27f84d757416799e432154e0adcadb154c9/Named_Snaps/")			 -- PCE
     or (apptype==20 and	 "https://raw.githubusercontent.com/libretro-thumbnails/NEC_-_PC_Engine_CD_-_TurboGrafx-CD/cd554a5cdca862f090e6c3f9510a3b1b6c2d5b38/Named_Snaps/")		 -- PCECD
     or (apptype==21 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Commodore_-_Amiga/b6446e83b3dc93446371a5dbfb0f24574eb56461/Named_Snaps/")				 -- AMIGA
     or (apptype==22 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Commodore_-_64/df90042ef9823d1b0b9d3ec303051f555dca2246/Named_Snaps/")					 -- C64
     or (apptype==23 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Bandai_-_WonderSwan_Color/5b57a78fafa4acb8590444c15c116998fcea9dce/Named_Snaps/")			 -- WSCAN_COL
     or (apptype==24 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Bandai_-_WonderSwan/3913706e173ec5f8c0cdeebd225b16f4dc3dd6c6/Named_Snaps/")				 -- WSWAN
  -- or (apptype==   and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/SCUMMVM/Named_Snaps/")								 -- SCUMMVM @@ unused
     or (apptype==25 and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/PICO8/Named_Snaps/")								 -- PICO-8 @@ invalid
     or (apptype==26 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Microsoft_-_MSX2/12d7e10728cc4c3314b8b14b5a9b1892a886d2ab/Named_Snaps/")				 -- MSX2
     or (apptype==27 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Microsoft_-_MSX/ed54675a51597fd5bf66a45318a273f330b7662f/Named_Snaps/")					 -- MSX1
     or (apptype==28 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Sinclair_-_ZX_Spectrum/d23c953dc9853983fb2fce2b8e96a1ccc08b70e8/Named_Snaps/")				 -- ZXS
     or (apptype==29 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Atari_-_7800/eff4d49a71a62764dd66d414b1bf7a843f85f7ae/Named_Snaps/")					 -- ATARI_7800
     or (apptype==30 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Atari_-_5200/793489381646954046dd1767a1af0fa4f6b86c24/Named_Snaps/")					 -- ATARI_5200
     or (apptype==31 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Atari_-_2600/ea2ba38f9bace8e85539d12e2f65e31c797c6585/Named_Snaps/")					 -- ATARI_2600
     or (apptype==32 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Atari_-_Lynx/91278444136e9c19f89331421ffe84cce6f82fb9/Named_Snaps/")					 -- ATARI_LYNX
     or (apptype==33 and	 "https://raw.githubusercontent.com/libretro-thumbnails/Coleco_-_ColecoVision/332c63436431ea5fceedf50b94447bb6e7a8e1f5/Named_Snaps/")				 -- COLECOVISION
     or (apptype==34 and	 "https://raw.githubusercontent.com/libretro-thumbnails/GCE_-_Vectrex/ed03e5d1214399d2f4429109874b2ad3d8a18709/Named_Snaps/")					 -- VECTREX
  -- or (apptype==   and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/MAME/Named_Snaps/")								 -- FBA @@unused. Shares mame archive
  -- or (apptype==   and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/MAME/Named_Snaps/")								 -- MAME_2003_PLUS @@ unused
  -- or (apptype==   and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/MAME/Named_Snaps/")								 -- MAME_2000 @@ unused
  -- or (apptype==   and	 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/Retro/NEOGEO/Named_Snaps/")								 -- NEOGEO@@ unused
     or (apptype==35 and	 "https://raw.githubusercontent.com/libretro-thumbnails/SNK_-_Neo_Geo_Pocket_Color/f940bd5da36105397897c093dda77ef06d51cbcf/Named_Snaps/")			 -- NGPC
     or (			 "https://raw.githubusercontent.com/jimbob4000/hexflow-covers/main/Covers/PSVita/Names_Snaps/")									 -- Vita & Homebrews @@ invalid
     )
     ..
     (
        (launch_mode==0 and	 (DISC_ID or entry.name))		 -- For real apps. Relatively simple. Example: "VITASHELL"
     or (entry.name:match("(.+)%..+$")~=nil and entry.name:match("%((.+)%)")==nil and entry.name:match("(.+)%..+$") .. " (USA)")	 -- Add " (USA)" to RetroFlows with no region specified. Ex: "Donkey Kong.n64" -------> "Donkey Kong (USA)"
     or (entry.name:match("(.+)%..+$") or entry.name)			 -- For RetroFlow entries. If item has a period at the end, this removes it... otherwise it'll use the whole file name. Ex: "Donkey Kong (USA).n64" --> "Donkey Kong (USA)"
     ):gsub("%%", '%%25'):gsub("%s+", '%%20') .. ".png"			 -- Converts spacebars to "%20" and percentage signs to "%25" since you can't those in a website address, then adds ".png" Ex: "Donkey Kong (USA)" ---> "Donkey%20Kong%20(USA).png"

     --System.setMessage(downloadable_file, false, BUTTON_OK)		 -- debug

    custom_path = (entry.name:match("(.+)%..+$") or entry.name) .. ".png"
    System.deleteFile("ux0:/data/HexFlow/" .. custom_path)		 -- if cover already exists, delete it before trying to download.

    if apptype == 2 then
	output_folder = "ux0:data/RetroFlow/BACKGROUNDS/Sony - PlayStation Portable/"
    elseif apptype == 3 then
	output_folder = "ux0:data/RetroFlow/BACKGROUNDS/Sony - PlayStation/"
    elseif apptype == 25 then
	output_folder = "ux0:data/RetroFlow/BACKGROUNDS/Lexaloffle Games - Pico-8/"
    else
	output_folder = xRomDirLookup(apptype):gsub("/ROMS/", "/BACKGROUNDS/")
    end
    System.createDirectory(output_folder)				 -- Prevents Nintendo DS cover download crash in experimental builds.

    Network.downloadFile(downloadable_file, "ux0:/data/HexFlow/" .. custom_path)

    if System.doesFileExist("ux0:/data/HexFlow/" .. custom_path) then
	tmpfile = System.openFile("ux0:/data/HexFlow/" .. custom_path, FREAD)
	size = System.sizeFile(tmpfile)
	System.closeFile(tmpfile)
	if size < 1024 then
	    System.deleteFile("ux0:/data/HexFlow/" .. custom_path)
	else
	    output_file_location = output_folder .. custom_path:gsub('%%25', "%%"):gsub('%%20', " ")
	    System.rename("ux0:/data/HexFlow/" .. custom_path, output_file_location)
	    System.deleteFile("ux0:/data/HexFlow/" .. custom_path) -- just delete file if rename operation somehow failed.
	    pic_path = output_file_location
            -- set pic0 as background
            Graphics.freeImage(backTmp)
            backTmp = Graphics.loadImage(pic_path)
            Graphics.setImageFilters(backTmp, FILTER_LINEAR, FILTER_LINEAR)
            Render.useTexture(modBackground, backTmp)
	    return output_file_location
	end
    end
end



function DownloadCategoryCovers()
    local cvrfound = 0

    local running = false
    status = System.getMessageState()

    if status ~= RUNNING then
	if not Network.isWifiEnabled() then
	    System.setMessage(lang_lines[124], false, BUTTON_OK)
	else
	    System.setMessage(lang_lines[126], true)
	    System.setMessageProgMsg(lang_lines[126])
	    for i=1, #xCatLookup(getCovers) do
		if string.match(xCatLookup(getCovers)[i].icon_path, "/COVERS/") == nil
		and DownloadCover(xCatLookup(getCovers)[i]) then
		    cvrfound = cvrfound + 1
		end
		Graphics.initBlend()	 -- one of these sets of initBlend/termBlend/Screen.flip()'s might not be necessary.
		Graphics.termBlend()
		Screen.flip()

		System.setMessageProgress(i / #xCatLookup(getCovers) * 100)
		System.setMessageProgMsg(lang_lines[127] .. "\n" ..lang_lines[128] .. xCatLookup(getCovers)[i].name .. "\n" .. lang_lines[129] ..  cvrfound .. lang_lines[130] .. #xCatLookup(getCovers))

		Graphics.initBlend()
		Graphics.termBlend()
		Screen.waitVblankStart()
		Screen.flip()
	    end
	    System.closeMessage()
	    scanComplete = true
	    FreeIcons()
	    FreeMemory()
	    Network.term()
	    dofile("app0:index.lua")
	end
    end
    gettingCovers = false
end

local function DrawCover(x, y, text, icon, sel, apptype, reflections)
    rot = 0
    extraz = 0
    extrax = 0
    extray = 0
    zoom = 0
    camX = 0
    Graphics.setImageFilters(icon, FILTER_LINEAR, FILTER_LINEAR)
  --abs_side_factor = math.abs(x/space)	 -- new but unused. Credit Axce/Retroflow
    if inPreview == true then
	extraz = -prevZ
	rot = prevRot+prvRotY
    elseif showView == 1 then
        -- flat zoom out view
        space = 1.6
        zoom = 0
        if x > 0.5 then
            extraz = 6
            extrax = 1
	    -- table.insert(tap_zones, {(x*96)+491, 213, 95, sel}) -- unused
        elseif x < -0.5 then
            extraz = 6
            extrax = -1
	    -- table.insert(tap_zones, {(x*96)+369, 213, 95, sel}) -- unused
        end
    elseif showView == 2 then
        -- smooth zoom-in view
        space = 1.6
        zoom = -1
        extray = -0.6
	extrax = x / space
	rot = -extrax
        --if x > 0.5 then
        --    rot = -1
        --    extraz = 0
        --    extrax = 1
        --elseif x < -0.5 then
        --    rot = 1
        --    extraz = 0
        --    extrax = -1
        --end
    elseif showView == 3 then
        -- smooth left side view
        space = 1.5
        zoom = -0.6
        extray = -0.3
        camX = 1
        if x > space then
            rot = -0.5
            extraz = x * 0.833		 --simplified abs_side_factor + x
            extrax = 0.6
        elseif x > 0 then
            rot = x * -0.333		 -- simplified -0.5 * abs_side_factor
            extraz = x * 0.833		 -- simplified (abs_side_factor + x) / 2, which used to be 2 + (x / 2)
            extrax = x * 0.4		 -- simplified 0.6 * abs_side_factor
        elseif x < -0.5 then		 -- (1/4)
            rot = 0.5			 -- (2/4) Remove these lines to stop items on the left from teleporting offscreen.
            extraz = 2			 -- (3/4)
            extrax = -10		 -- (4/4)
	else				 -- x is -0.5 or below
            rot = x * -0.333		 -- simplified 0 - abs_side_factor
	    extrax = x * 0.667		 -- simplified 0.5 * abs_side_factor
        end
    elseif showView == 4 then
        -- scroll around
        space = 1
        zoom = 0
        if x > 0.5 then
            extraz = 2 + (x / 1.5)
            extrax = 1
        elseif x < -0.5 then
            extraz = 2 - (x / 1.5)
            extrax = -1
        end
    else			 -- used to be if showView ~= 5 then
        -- default view
        space = 1
        zoom = 0
        if x > 0.5 then
            rot = -1
            extraz = 3
            extrax = 1
        elseif x < -0.5 then
            rot = 1
            extraz = 3
            extrax = -1
        end
    end
    
    Render.setCamera(camX, 0, 0, 0.0, 0.0, 0.0)
    
    if hideBoxes <= 0 then
	if showView==5 and inPreview==false then
	    -- SwitchView! 192px image size, 200px space.
	    x = x * 200 + 85
	    y = 152
	    table.insert(tap_zones, {x, y, 192, sel})
	    if sel==p and not bottomMenu then
		Graphics.fillRect(x-6, x+198, y-6, y+198,lightblue)
	    end
	    icon_height = Graphics.getImageHeight(icon)
	    icon_width = Graphics.getImageWidth(icon)
	    if apptype==1 and View5VitaCropTop==1 and icon_height~=128 then
	      --vita_header_size = math.ceil(icon_height*31/320)
		vita_header_size = math.ceil(icon_height*0.096875)	 -- how big the blue top of the vita cover is (29/320 will work but 31/320 looks best) to dynamicly crop it.
		Graphics.drawImageExtended(x+96, y+96, icon, 0, vita_header_size, icon_width, icon_height - vita_header_size, 0, 192 / icon_width, 192 / (icon_height-vita_header_size))
	    else
		Graphics.drawScaleImage(x, 152, icon, 192 / icon_width, 192 / icon_height)
	    end
	elseif showView==6 and inPreview==false then
	    -- Grid View! 132px image size, 140px space.
	    --x = ((sel-1) % 6) * 140 + 60				 -- X attempt 1
	    --y = ((math.floor((sel-1) / 6)) - targetY) * 140 + 152	 -- Y attempt 1
	    --y = ((sel-1) // 6 - targetY) * 140 + 152			 -- Y attempt 2
	    x = grid_x * 140 - 80
	    y = (grid_y - targetY) * 140 + 152
	    table.insert(tap_zones, {x, y, 140, sel})
	    if sel==p and not bottomMenu then
		Graphics.fillRect(x-6, x+138, y-6, y+138,lightblue)
	    end
	    icon_height = Graphics.getImageHeight(icon)
	    icon_width = Graphics.getImageWidth(icon)
	    if (apptype==1) and (View5VitaCropTop == 1) and (icon_height ~= 128) then
	      --vita_header_size = math.ceil(Graphics.getImageHeight(icon)*31/320)
		vita_header_size = math.ceil(icon_height*0.096875)	 -- how big the blue top of the vita cover is (29/320 will work but 31/320 looks best) to dynamicly crop it.
		Graphics.drawImageExtended(x+66, y+66, icon, 0, vita_header_size, icon_width, icon_height-vita_header_size, 0, 132 / icon_width, 132 / (icon_height - vita_header_size))
	    else
		Graphics.drawScaleImage(x, y, icon, 132 / icon_width, 132 / icon_height)
	    end
        elseif apptype==1 then
            -- PSVita Boxes
            if reflections == 1 then
                Render.useTexture(modCover, icon)
                Render.drawModel(modCover, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
                Render.drawModel(modBox, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            else
                Render.useTexture(modCoverNoref, icon)
                Render.drawModel(modCoverNoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
                Render.drawModel(modBoxNoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            end
        elseif apptype==2 then
            -- PSP Boxes
            if reflections == 1 then
                Render.useTexture(modCoverPSP, icon)
                Render.drawModel(modCoverPSP, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
                Render.drawModel(modBoxPSP, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            else
                Render.useTexture(modCoverPSPNoref, icon)
                Render.drawModel(modCoverPSPNoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
                Render.drawModel(modBoxPSPNoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            end
        elseif apptype==3 then
            -- PSX Boxes
            if reflections == 1 then
                Render.useTexture(modCoverPSX, icon)
                Render.drawModel(modCoverPSX, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
                Render.drawModel(modBoxPSX, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            else
                Render.useTexture(modCoverPSXNoref, icon)
                Render.drawModel(modCoverPSXNoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
                Render.drawModel(modBoxPSXNoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            end
	elseif setRetroFlow == 0 then
            -- Homebrew Icon
            if reflections == 1 then
                Render.useTexture(modCoverHbr, icon)
                Render.drawModel(modCoverHbr, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            else
                Render.useTexture(modCoverHbrNoref, icon)
                Render.drawModel(modCoverHbrNoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            end
        elseif apptype==5 or apptype==6 then
	    if inPreview == false	 -- n64_fix
	    and showView == 1 then	 -- n64_fix
		x = x - 0.45		 -- n64_fix
	    end				 -- n64_fix
            if reflections == 1 then
                Render.useTexture(modCoverN64, icon)
                Render.drawModel(modCoverN64, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            else
                Render.useTexture(modCoverN64Noref, icon)
                Render.drawModel(modCoverN64Noref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            end
        elseif apptype==7 or apptype==12 or apptype==17 or apptype==18 or apptype==19 or apptype==20 or apptype==21 or apptype==23 or apptype==24 or apptype==35 then
            if reflections == 1 then
                Render.useTexture(modCoverNES, icon)
                Render.drawModel(modCoverNES, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            else
                Render.useTexture(modCoverNESNoref, icon)
                Render.drawModel(modCoverNESNoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            end
        elseif apptype==8 or apptype==9 or apptype==10 or apptype==11 then
            if reflections == 1 then
                Render.useTexture(modCoverGB, icon)
                Render.drawModel(modCoverGB, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            else
                Render.useTexture(modCoverGBNoref, icon)
                Render.drawModel(modCoverGBNoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            end
        elseif apptype==13 or apptype==14 or apptype==15 or apptype==16 then
            if reflections == 1 then
                Render.useTexture(modCoverMD, icon)
                Render.drawModel(modCoverMD, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            else
                Render.useTexture(modCoverMDNoref, icon)
                Render.drawModel(modCoverMDNoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            end
        elseif apptype==22 or apptype==26 or apptype==27 or apptype==28 then
            if reflections == 1 then
                Render.useTexture(modCoverTAPE, icon)
                Render.drawModel(modCoverTAPE, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            else
                Render.useTexture(modCoverTAPENoref, icon)
                Render.drawModel(modCoverTAPENoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            end
        elseif apptype==29 or apptype==30 or apptype==31 or apptype==33 or apptype==34 then
            if reflections == 1 then
                Render.useTexture(modCoverATARI, icon)
                Render.drawModel(modCoverATARI, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            else
                Render.useTexture(modCoverATARINoref, icon)
                Render.drawModel(modCoverATARINoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            end
        elseif apptype==25 or apptype==32 then
            if reflections == 1 then
                Render.useTexture(modCoverLYNX, icon)
                Render.drawModel(modCoverLYNX, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            else
                Render.useTexture(modCoverLYNXNoref, icon)
                Render.drawModel(modCoverLYNXNoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            end
        else
            -- Homebrew Icon
            if reflections == 1 then
                Render.useTexture(modCoverHbr, icon)
                Render.drawModel(modCoverHbr, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            else
                Render.useTexture(modCoverHbrNoref, icon)
                Render.drawModel(modCoverHbrNoref, x + extrax, y + extray, -5 - extraz - zoom, 0, math.deg(rot), 0)
            end
        end
    end
end

local FileLoad = {}

function FreeIcons()
    FileLoad = {}
    Threads.clear()
    for k, v in pairs(files_table) do	 -- Due to LuaJIT table recursion, clearing the "All" table clears every table.
        if v.ricon then
            Graphics.freeImage(v.ricon)
            v.ricon = nil
        end
    end
end

function DownloadSingleCover()
    running = false
    status = System.getMessageState()

    if status ~= RUNNING then
	if not Network.isWifiEnabled() then
	    System.setMessage(lang_lines[124], false, BUTTON_OK)
	elseif DownloadCover(xCatLookup(showCat)[p]) then
	    Threads.addTask(xCatLookup(showCat)[p], {
	    Type = "ImageLoad",
	    Path = xCatLookup(showCat)[p].icon_path,
	    Table = xCatLookup(showCat)[p],
	    Index = "ricon"
	    })
	    System.setMessage(lang_lines[56]:gsub("*", DISC_ID or xCatLookup(showCat)[p].name), false, BUTTON_OK) --Cover XXXXXXXXX found!
	else
	    System.setMessage(lang_lines[125], false, BUTTON_OK)
	end
    end
    gettingCovers = false
end

function DownloadSingleSnap()
    running = false
    status = System.getMessageState()

    if status ~= RUNNING then
	if not Network.isWifiEnabled() then
	    System.setMessage(lang_lines[124], false, BUTTON_OK)
	elseif not (setBackground > 0.5) then
	    System.setMessage(lang_lines[18] .. ": " .. lang_lines[23], false, BUTTON_OK) --Custom Background OFF
	elseif DownloadSnap(xCatLookup(showCat)[p]) then
	    System.setMessage(lang_lines[56]:gsub("*", DISC_ID or xCatLookup(showCat)[p].name), false, BUTTON_OK) --Cover XXXXXXXXX found!
	else
	    System.setMessage(lang_lines[125], false, BUTTON_OK)
	end
    end
    gettingCovers = false
end

-- For simpler code in secret feature "alphabet skip" (hold select+press L/R)
function first_letter_of_apptitle(target_position)
    local letr = string.sub(xCatLookup(showCat)[target_position].apptitle, 1, 1):lower()
    if letr and (letr >= "a") then
	return letr
    else
	return "1"
    end
end

function Category_Minus(tmpCat)
    FreeIcons()
    hideBoxes = 0.2
    p = 1
    master_index = p
    startCovers = false

  --tmpCat = showCat - 1

    while true do	 --loop in case hideEmptyCats is enabled.
	categoryText = xTextLookup(tmpCat)

	if categoryText == xTextLookup(tmpCat + 1) then	 -- impossibly low/high tmpCat, default to "CUSTOM" category.
	    if setRetroFlow == 1 then
		tmpCat = 37
	    else
		tmpCat = 6
	    end
	elseif categoryText == xTextLookup(tmpCat - 1) then	 -- tmpCat pushed out of bounds by the below if statements, default to "All".
	    tmpCat = 0
	    break						 -- always stop at tmpCat 0 ("All") to prevent infinite loop.
	elseif (showHomebrews == 0 and categoryText == lang_lines[2])			 --Homebrew
	 or (cur_quick_dir["customsort.dat"] == nil and categoryText == lang_lines[49])	 --CUSTOM
	 or (showRecentlyPlayed == 0 and categoryText == lang_lines[108]) then		 --Recently Played
	    tmpCat = tmpCat - 1
	elseif #xCatLookup(tmpCat) > 0 or hideEmptyCats == 0 or tmpCat == 0 then
	    break
	else
	    tmpCat = tmpCat - 1
	end
    end
    GetNameSelected()
    if true==true then
	return tmpCat
    end
end

function Category_Plus(tmpCat)
    FreeIcons()
    hideBoxes = 0.2
    p = 1
    master_index = p
    startCovers = false

  --tmpCat = showCat + 1

    while true do	 --loop in case hideEmptyCats is enabled.
	categoryText = xTextLookup(tmpCat)

	if categoryText == xTextLookup(tmpCat - 1) then	 -- impossibly high/low tmpCat, default to "PS Vita"
	    tmpCat = 1
	elseif categoryText == xTextLookup(tmpCat + 1) then	 -- tmpCat pushed out of bounds by the below if statements, default to "All".
	    tmpCat = 0
	    break						 -- always stop at tmpCat 0 ("All") to prevent infinite loop.
	elseif (showHomebrews == 0 and categoryText == lang_lines[2])			 --Homebrew
	 or (cur_quick_dir["customsort.dat"] == nil and categoryText == lang_lines[49])	 --CUSTOM
	 or (showRecentlyPlayed == 0 and categoryText == lang_lines[108]) then		 --Recently Played
	    tmpCat = tmpCat + 1
	elseif #xCatLookup(tmpCat) > 0 or hideEmptyCats == 0 or tmpCat == 0 then
	    break
	else
	    tmpCat = tmpCat + 1
	end
    end
    GetNameSelected()
    if true==true then
	return tmpCat
    end
end

local utilityItems = 7
function execute_switch_bottom_menu()
    if menuSel == 0 then
	FreeIcons()				    --0 Decrypt Icons. Credit to cy33hc for his program "copyicons"
	FreeMemory()
	Network.term()
	System.launchEboot("app0:/copyicons.bin")
    elseif menuSel==1 then
	System.executeUri("wbapp0:")		    --1 News (Internet Browser)
      --System.executeUri("https://www.google.com") --1 News (Internet Browser:https://www.google.com)
    elseif menuSel == 2 then
	System.executeUri("psns:")		    --2 Store
    elseif menuSel == 3 then
	System.executeUri("photo:")		    --3 Album
    elseif menuSel == 4 then			
	System.executeUri("scecomboplay:")	    --4 Controls (PS3 Cross-Controller). Note: to launch moonlight it's FreeMemory() + System.launchApp(XYZZ00002) + System.exit()
    elseif menuSel == 5 then
	System.executeUri("settings_dlg:")	    --5 System Settings
    elseif menuSel == 6 then
	if showMenu == 2 then
	    FreeMemory()			    --6 VitaShell (from start menu)
	    System.launchApp("VITASHELL")
	    System.exit()
	else
	    FreeMemory()			    --6 Exit
	    System.exit()
	end
    elseif menuSel == 7 then
	System.executeUri("pstc:")		    --7 Trophies
    end
end

-- Loads App list if cache exists, or generates a new one if it doesn't
LoadAppTitleTables()

--functionTime = Timer.getTime(functionTimer)
functionTime = Timer.getTime(oneLoopTimer)
--Timer.destroy(functionTimer)

-- Main loop
while true do
    
    -- Threads update
    Threads.update()
    
    if hasTyped == false then
	-- controller input
	pad = Controls.read()
	mx, my = Controls.readLeftAnalog()

	-- touch input
	x1, y1 = Controls.readTouch()
    end

    if showView == 5 then
	tap_zones = {
	    {240, 378, 78, -1},		 -- News
	    {322, 378, 78, -2},		 -- Store
	    {404, 378, 78, -3},		 -- Album
	    {486, 378, 78, -4},		 -- Controls
	    {568, 378, 78, -5},		 -- System Settings
	    {650, 378, 78, -6}		 -- Exit
	}
    else
	tap_zones = {}
    end
    
    -- Initializing rendering
    Graphics.initBlend()
    Screen.clear(black)
    
    if delayButton > 0 then
        delayButton = delayButton - 0.1
    else
        delayButton = 0
    end

    if hideBoxes > 0 then
	hideBoxes = hideBoxes - 0.1
    else
	hideBoxes = 0
    end

    if touchdown > 0 then
	touchdown = touchdown - 0.01
    else
	touchdown = 0
    end

  --if quick_scroll < 0.9001 then
  --	quick_scroll = quick_scroll + 0.1
  --else
  --	quick_scroll = 1
  --end
    
    -- Graphics
    if setBackground > 0.5 then
        Render.drawModel(modBackground, 0, 0, -5, 0, 0, 0)-- Draw Background as model
    else
        Render.drawModel(modDefaultBackground, 0, 0, -5, 0, 0, 0)-- Draw Background as model
    end

    -- Use this to debug instead of SCE_CTRL_SELECT.
    -- Graphics.debugPrint(10,10, " master_index:" .. master_index .. " p:" .. p .. " curTotal:" .. curTotal .. " targetX:" .. targetX .. " targetY:" .. targetY .. " BaseYHotfix:" .. BaseYHotfix, white)

    Graphics.fillRect(0, 960, 496, 544, themeCol)-- footer bottom
    if showView == 5 or showView == 6 then
	Graphics.drawLine(21, 940, 496, 496, white)
    end

    if showMenu == 0 then
        -- MAIN VIEW
	-- Shadow fix for covers with transparency and SwitchView Bottom Menu.
	if (showView == 5 or showView == 6) and setReflections==1 then
	    Graphics.drawScaleImage(0, 298, imgFloor2, 960, 1)
	end

        prevX = 0
        prevZ = 0
        prevRot = 0
        inPreview = false

        base_x = 0
	base_y = 0
	grid_x = 0
	grid_y = 0
	n64_x_bonus = 0			 -- n64_fix
	skipRow = false

        -- Draw Covers
	-- If the cover 7 tiles away has been loaded, increase render distance.
	if xCatLookup(showCat)[p+7] and xCatLookup(showCat)[p+7].ricon then
	    render_distance = 16
	else
	    render_distance = 8
	end
	if showView == 6 then
	    render_distance = render_distance * 3
	end

        for l, file in pairs(xCatLookup(showCat)) do
	    if (showView == 1)					 -- n64_fix
	    and (file.app_type == 5 or file.app_type == 6) then	 -- n64_fix
		n64_x_bonus = n64_x_bonus + n64_fatness		 -- n64_fix +0.8 real x bonus after an n64
	    end							 -- n64_fix
	    if (showView == 1)					 -- n64_fix
	    and (l == master_index)				 -- n64_fix
	    and (file.app_type == 5 or file.app_type == 6) then	 -- n64_fix
		base_x = base_x + space				 -- n64_fix
		n64_x_bonus = n64_x_bonus - 0.35		 -- n64_fix
            elseif l >= master_index then			 -- Note: >= @@ Used to be just "if" not "elseif"
                base_x = base_x + space
	    elseif (showView == 1)				 -- n64 fix
	    and (l <= master_index)				 -- n64 fix
	    and (file.app_type == 5 or file.app_type == 6) then	 -- n64_fix
		base_x = base_x - n64_fatness			 -- n64_fix +0.8 base x bonus after an n64
            end
	    if grid_x < 6 then
		grid_x = grid_x + 1
	    else
		skipRow = false					 -- In Grid View, only render in whole rows. Improves percieved app quality, and for some reason reduces app crashing a lot????
		grid_x = 1
		grid_y = grid_y + 1
		if l <= master_index then			 -- Note: <=
		    base_y = grid_y
		end
	    end
	    if skipRow == false and l > p-render_distance and l < p+render_distance+2 then						 --@@ (4/7)
		--if l==p and file.fave_heart == true then
		--    Graphics.drawImage(685, 36, imgFav_small_on)
		--end
                if FileLoad[file] == nil then --add a new check here
                    FileLoad[file] = true
                    Threads.addTask(file, {
                        Type = "ImageLoad",
                        Path = file.icon_path,
                        Table = file,
                        Index = "ricon"
                    })
                end
		DrawCover(space*(l-curTotal-1) + targetX + n64_x_bonus, -0.6, file.name, file.ricon or imgCoverTmp, l, file.app_type, setReflections)--draw visible covers only @@ n64_fix

            else
		if skipRow == false and showView == 6 then
		    skipRow = true
		end
                if FileLoad[file] == true then
                    FileLoad[file] = nil
                    Threads.remove(file)
                end
                if file.ricon then
                    Graphics.freeImage(file.ricon)
                    file.ricon = nil
                end
            end
        end
        -- Header and footer are now drawn AFTER the covers so Grid View can work right.
	Graphics.fillRect(0, 960, 496, 544, themeCol)
	if showView == 6 then
	    Graphics.fillRect(0, 960, 0, 65, darkalpha)		 -- Header top
	    Graphics.drawLine(21, 940, 496, 496, white)
	elseif showView == 5 then
	    Graphics.drawLine(21, 940, 496, 496, white)
	end
        h, m, s = System.getTime()
	Font.print(fnt20, 726, 34, string.format("%02d:%02d", h, m), white)-- Draw time
	life = System.getBatteryPercentage()
	Font.print(fnt20, 830, 34, life .. "%", white)-- Draw battery
	Graphics.drawImage(888, 41, imgBattery)
	Graphics.fillRect(891, 891 + (life / 5.2), 45, 53, white)
	if Network.isWifiEnabled() then
	    Graphics.drawImage(800, 38, imgWifi)-- wifi icon
	end
	-- Footer buttons and icons. X positions set in ChangeLanguage()
	Graphics.drawImage(label1ImgX, 510, btnAccept)	 -- Used to be btnX
	Font.print(fnt20, label1X, 508, lang_lines[7], white)--Launch
	Graphics.drawImage(label2ImgX, 510, btnT)
	Font.print(fnt20, label2X, 508, lang_lines[8], white)--Details
	if categoryButton == 1 then
	    Graphics.drawImage(label3ImgX, 510, btnD)
	    Font.print(fnt22, 32, 34, xTextLookup(showCat), white)--PS VITA/HOMEBREWS/PSP/PSX/CUSTOM/ALL
	    Font.print(fnt20, label3X, 508, lang_lines[9], white)--Category
	elseif categoryButton == 2 then
	    Graphics.drawImage(34, 37, imgArrows)
	    Font.print(fnt22, 52, 34, xTextLookup(showCat), white)--PS VITA/HOMEBREWS/PSP/PSX/CUSTOM/ALL
	else
	    Graphics.drawImage(label3ImgX, 510, btnS)
	    Font.print(fnt22, 32, 34, xTextLookup(showCat), white)--PS VITA/HOMEBREWS/PSP/PSX/CUSTOM/ALL
	    Font.print(fnt20, label3X, 508, lang_lines[9], white)--Category
	end
	if lockView == 0 then
	    Graphics.drawImage(label4ImgX, 510, btnCancel)	 -- Used to be btnO
	    Font.print(fnt20, label4X, 508, lang_lines[10], white)--View
	end

	if showView == 5 then
	    Graphics.drawImage(27, 108, imgCart)
	    Font.print(fnt23_5, 60, 106, app_short_title:gsub("\n",""), lightblue)	 -- Draw title in SwitchView UI style.
	    Graphics.drawImage(240, 378, btnMenu1)		 -- News
	    Graphics.drawImage(322, 378, btnMenu2)		 -- Store
	    Graphics.drawImage(404, 378, btnMenu3)		 -- Album
	    Graphics.drawImage(486, 378, btnMenu4)		 -- Controls
	    Graphics.drawImage(568, 378, btnMenu5)		 -- System Settings
	    Graphics.drawImage(650, 378, btnMenu6)		 -- Exit
	    if bottomMenu then
		Graphics.drawImage(menuSel*82-82+240-2, 378-2, btnMenuSel)
		PrintCentered(fnt23_5, menuSel*82-82+240+39, 452, lang_lines[menuSel+78], lightblue, 22) -- News/Store/Album/Controls/System Settings/Exit
		-- This is a really cheap way to put lang lines. I'll fix it later maybe (probably not honestly)
	    end
        elseif (showView ~= 2) and (showView ~= 6) then
            Graphics.fillRect(0, 960, 424, 496, black)-- black footer bottom
            PrintCentered(fnt25, 480, 430, app_short_title, white, 25)-- Draw title
	else
            Font.print(fnt22, 24, 508, app_short_title, white)	 -- Grid View draws apptitle at the bottom, like View 2.
        end

        if showView ~= 2 and showView ~= 6 and not bottomMenu then	 -- Disable curtotal counter in Grid View.
            PrintCentered(fnt20, 480, 462, p .. " of " .. #xCatLookup(showCat), white, 20)-- Draw total items
        end
        
        
	-- Special Y border calculations for Grid View
	--base_y = math.floor((master_index - 1) / 6)	 -- base_y attempt 1
	--base_y = (master_index - 1) // 6		 -- base_y attempt 2
	if curTotal > 12 then
	    if base_y < 1 or (curTotal < 19) then
		BaseYHotfix = 0							 -- this line is only here to help touch scrolling.
		base_y = 0.55
	    else
		BaseYHotfix = math.floor((curTotal - 1) / 6) - 2
		if base_y > BaseYHotfix then
		    base_y = BaseYHotfix + 0.55
		end
	    end
	end

        -- Smooth move items vertically
        if (targetY < (base_y - 0.0001)) or (targetY > (base_y + 0.0001)) then	 -- Stops drift (represented by targetY) when within 0.0001 of base_y
            targetY = targetY - ((targetY - base_y) * 0.1)
        else
            targetY = base_y
        end

        -- Smooth move items horizontally
        if (targetX < (base_x - 0.0001)) or (targetX > (base_x + 0.0001)) then	 -- Stops drift (represented by targetX) when within 0.0001 of base_x
            targetX = targetX - ((targetX - base_x) * 0.1)
        else
            targetX = base_x
        end


        -- Instantly move to selection
        if startCovers == false then
            targetX = base_x
	    targetY = base_y
	    if p == 1 and Controls.check(pad, CTRL_CANCEL) then	 -- Used to be SCE_CTRL_CIRCLE
		targetY = base_y + 0.05				 -- Tactical Jiggle
	    end
            startCovers = true
            GetNameSelected()
        end
        
	if setReflections == 1 and showView < 5 then
	    floorY = 0
	    if showView == 2 then
		floorY = -0.6
	    elseif showView == 3 then
		floorY = -0.3
	    end
	    --Draw half transparent floor for reflection effect
	    Render.drawModel(modFloor, 0, -0.6+floorY, 0, 0, 0, 0)
	end
    elseif showMenu == 1 then
        
        -- PREVIEW
        -- Footer buttons and icons. positions set in ChangeLanguage()
        Graphics.drawImage(label1AltImgX, 510, btnCancel)	 -- Used to be btnO
        Font.print(fnt20, label1AltX, 508, lang_lines[11], white)--Close
        Graphics.drawImage(label2AltImgX, 510, btnAccept)	 -- Used to be btnX
        Font.print(fnt20, label2AltX, 508, lang_lines[32], white)--Select
        
        Graphics.fillRect(24, 470, 24, 470, darkalpha)
        Render.setCamera(0, 0, 0, 0.0, 0.0, 0.0)
        if inPreview == false then
            if not pcall(loadImage, icon_path) then
                iconTmp = imgCoverTmp
            else
                iconTmp = Graphics.loadImage(icon_path)
            end
            -- set pic0 as background
            if System.doesFileExist(pic_path) and setBackground > 0.5 then
                Graphics.freeImage(backTmp)
                backTmp = Graphics.loadImage(pic_path)
                Graphics.setImageFilters(backTmp, FILTER_LINEAR, FILTER_LINEAR)
                Render.useTexture(modBackground, backTmp)
            else
                Render.useTexture(modBackground, imgCustomBack)
            end

	    menuY=0
	    tmpappcat=0
            inPreview = true
        end
        
        -- animate cover zoom in
        if prevX < 1.4 then
            prevX = prevX + 0.1
        end
        if prevZ < 1 then
            prevZ = prevZ + 0.06
        end
        if prevRot > -0.6 then
            prevRot = prevRot - 0.04
        end
        
        Graphics.drawImage(50, 50, iconTmp)-- icon
	--Graphics.drawScaleImage(50, 50, iconTmp, 128 / Graphics.getImageWidth(iconTmp), 128 / Graphics.getImageHeight(iconTmp)) --icon, stretched to frame (unused)

	local file = xCatLookup(showCat)[p]	 -- Moved here now. Allows cleaner code below

        -- txtname = string.sub(app_title, 1, 32) .. "\n" .. string.sub(app_title, 33)
	txtname = string.sub(file.apptitle, 1, 32) .. "\n" .. string.sub(file.apptitle, 33)
		
        local tmpapptype=""	 -- text for game type
	local tmpcatText=""	 -- text for currently selected override type
        -- Draw box
	if apptype == 0 or apptype == 4 then
	    tmpapptype = lang_lines[2]	 --Homebrew
	elseif file.launch_type == 3 then
	    tmpapptype = "PS1 Retroarch Game"
	else
	    tmpapptype = xTextLookup(appt_hotfix(file.app_type)):gsub('\r', "") .. " Game"	 -- this gsub cuts off the special Windows-notepad "new line" character which displays in Vita as an XL space.
	end

	--Draw box
	DrawCover(prevX, -1.0, file.name, file.ricon or imgCoverTmp, p, file.app_type, 0)
    
        Font.print(fnt22, 50, 190, txtname, white)-- app name
	if DISC_ID and DISC_ID ~= app_titleid then
	    Font.print(fnt22, 50, 240, tmpapptype .. "\nApp ID : " .. app_titleid .. " (" .. DISC_ID .. ")\nVersion : " .. app_version .. "\n" .. app_size_text, white)-- Draw info (PS1)
	else
	    Font.print(fnt22, 50, 240, tmpapptype .. "\nApp ID : " .. app_titleid .. "\nVersion : " .. app_version .. "\n" .. app_size_text, white)-- Draw info (not PS1)
	end
		
	if tmpappcat==1 then
	    tmpcatText = "PS Vita"
	elseif tmpappcat==2 then
	    tmpcatText = "PSP"
	elseif tmpappcat==3 then
	    tmpcatText = "PS1"
	elseif tmpappcat==4 then
	    tmpcatText = "Homebrew"
	else
	    tmpcatText = lang_lines[123]
	end

	if xCatLookup(showCat)[p].launch_type == 0 then
	    menuItems = 2
	    Graphics.fillRect(24, 470, 350 + (menuY * 40), 390 + (menuY * 40), themeCol)-- selection
	    Font.print(fnt22, 50, 352, lang_lines[120], white)
	    Font.print(fnt22, 50, 352+40, lang_lines[121] .. ": < " .. tmpcatText .. " >", white)
	    Font.print(fnt22, 50, 352+80, lang_lines[122], white)

	    --if xCatLookup(showCat)[p].fave_heart == true then
	    --    Graphics.drawImage(420, 50, imgFav_large_on)
	    --else
	    --    Graphics.drawImage(420, 50, imgFav_large_off)
	    --end

	    status = System.getMessageState()
	    if status ~= RUNNING then

		if (Controls.check(pad, CTRL_ACCEPT) and not Controls.check(oldpad, CTRL_ACCEPT)) then	 -- Used to be SCE_CTRL_CROSS
		    if menuY == 0 then
			if gettingCovers == false then
			    gettingCovers = true
			    DownloadSingleCover()
			end
		    elseif menuY == 1 then
			if spin_allowance < 0.1 then
			    if showCat == 0 or showCat == 5 or showCat == 6 or showCat == 36 or showCat == 37 then	 -- Lazy code but works fine for now.
				spin_allowance = 3
			    else
				OverrideCategory()
				check_for_out_of_bounds()
				close_triangle_preview()
			    end
			end
		    elseif menuY == 2 then	 -- Renamer option
			local running = false
			status = Keyboard.getState()
			if status ~= RUNNING then
			    if hasTyped == false then
				Keyboard.start("Rename. Leave blank to reset title.", sanitize(xCatLookup(showCat)[p].apptitle), 512, TYPE_LATIN, MODE_TEXT)
				hasTyped = true
			    else
				result_text = sanitize(Keyboard.getInput())
				Keyboard.clear()
				hasTyped = false
				status = System.getMessageState()
				if ("\"" .. result_text .. "\"") ~= string.format("%q", result_text) then
				    -- %q format makes the string LUA compatible by 1: adding quotes to the end and 2: sanitizing any LUA-special characters...
				    -- ...so if the string with added quotes DOESN'T equal the %q format output, it's not gonna go well with cache.
				    System.setMessage("invalid title", false, BUTTON_OK)
				else
				    if result_text:len() == 0 then
					result_text = sanitize(app_short_title)
				    end
				    xCatLookup(showCat)[p].apptitle = result_text

				    table.sort(xCatLookup(appt_hotfix(apptype)), function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)
				    table.sort(files_table, function(a, b) return (a.apptitle:lower() < b.apptitle:lower()) end)
				    targetX = targetX - 0.5

				    UpdateCacheSect(app_titleid, 5, result_text)
				    GetNameSelected()
				    close_triangle_preview()
				end
			    end
			end
                    end
		elseif (Controls.check(pad, SCE_CTRL_UP)) and not (Controls.check(oldpad, SCE_CTRL_UP)) then
		    if menuY > 0 then
			menuY = menuY - 1
		    else
			menuY=menuItems
		    end
		elseif (Controls.check(pad, SCE_CTRL_DOWN)) and not (Controls.check(oldpad, SCE_CTRL_DOWN)) then
		    if menuY < menuItems then
			menuY = menuY + 1
		    else
			menuY=0
		    end
		elseif (Controls.check(pad, SCE_CTRL_LEFT)) and not (Controls.check(oldpad, SCE_CTRL_LEFT)) then
		    if menuY==1 then
			if tmpappcat > 0 then
			    tmpappcat = tmpappcat - 1
			else
			    tmpappcat=4
			end
		    end
		elseif (Controls.check(pad, SCE_CTRL_RIGHT)) and not (Controls.check(oldpad, SCE_CTRL_RIGHT)) then
		    if menuY==1 then
			if tmpappcat < 4 then
			    tmpappcat = tmpappcat + 1
			else
			    tmpappcat=0
			end
		    end
		end
	    end
	else
	    menuItems = 1
	    Graphics.fillRect(24, 470, 350 + (menuY * 40), 390 + (menuY * 40), themeCol)-- selection
	    Font.print(fnt22, 50, 355, "Download Cover", white)
	    Font.print(fnt22, 50, 355+40, "Download Snap", white)
	    --if xCatLookup(showCat)[p].fave_heart == true then
	    --    Graphics.drawImage(420, 50, imgFav_large_on)
	    --else
	    --    Graphics.drawImage(420, 50, imgFav_large_off)
	    --end

	    status = System.getMessageState()
	    if status ~= RUNNING then

		if (Controls.check(pad, CTRL_ACCEPT) and not Controls.check(oldpad, CTRL_ACCEPT)) then	 -- Used to be SCE_CTRL_CROSS
		    if menuY == 0 then
			if gettingCovers == false then
			    gettingCovers = true
			    DownloadSingleCover()
			end
		    elseif menuY == 1 then
			if gettingCovers == false then
			    DownloadSingleSnap()
			end
                    end
		elseif (Controls.check(pad, SCE_CTRL_UP)) and not (Controls.check(oldpad, SCE_CTRL_UP)) then
		    if menuY > 0 then
			menuY = menuY - 1
		    else
			menuY=menuItems
		    end
		elseif (Controls.check(pad, SCE_CTRL_DOWN)) and not (Controls.check(oldpad, SCE_CTRL_DOWN)) then
		    if menuY < menuItems then
			menuY = menuY + 1
		    else
			menuY=0
		    end
		elseif (Controls.check(pad, SCE_CTRL_LEFT)) and not (Controls.check(oldpad, SCE_CTRL_LEFT)) then
		    if menuY==1 then
			if tmpappcat > 0 then
			    tmpappcat = tmpappcat - 1
			else
			    tmpappcat=4
			end
		    end
		elseif (Controls.check(pad, SCE_CTRL_RIGHT)) and not (Controls.check(oldpad, SCE_CTRL_RIGHT)) then
		    if menuY==1 then
			if tmpappcat < 4 then
			    tmpappcat = tmpappcat + 1
			else
			    tmpappcat=0
			end
		    end
		end
	    end
	end	
    elseif showMenu == 2 then

	-- Set Setting Menu Tab Spacing. This bit of code is so ugly sorry >.<
	if not toggle1X then
	    if (Font.getTextWidth(fnt22, lang_lines[107] .. ": ")) > 260 then
		toggle1X = (Font.getTextWidth(fnt22, lang_lines[107] .. ": ")) - 260 --Crop 'Vita' in View #5+
	    else
		toggle1X = 0
	    end
	    if (Font.getTextWidth(fnt22, lang_lines[99] .. ": ")) > 275 then
		toggle2X = (Font.getTextWidth(fnt22, lang_lines[99] .. ": ")) - 275 --Hide Empty Categories
	    else
		toggle2X = 0
	    end
	end
        -- SETTINGS
        -- Footer buttons and icons. label X's are set in function ChangeLanguage()
        Graphics.drawImage(label1AltImgX, 510, btnCancel)	 -- Used to be btnO
        Font.print(fnt20, label1AltX, 508, lang_lines[11], white)--Close
        Graphics.drawImage(label2AltImgX, 510, btnAccept)	 -- Used to be btnX
        Font.print(fnt20, label2AltX, 508, lang_lines[32], white)--Select
        Graphics.fillRect(60, 900, 24, 488, darkalpha)
        Font.print(fnt22, 84, 34, lang_lines[6], white)--SETTINGS
	if menuY < 5 then
	    Graphics.fillRect(60, 900, 77 + (menuY * 34), 112 + (menuY * 34), themeCol)-- selection
	elseif menuY == 11 then
	    Graphics.fillRect(60 + (280 * menuX), 60 + 280 + (280 * menuX), 77 + (menuY * 34), 112 + (menuY * 34), themeCol)-- selection
	elseif menuY > 11 then
	    --do nothing
	elseif menuX == 0 then	 -- The ON/OFF settings, left side
	    Graphics.fillRect(60, 460, 77 + (menuY * 34), 112 + (menuY * 34), themeCol)-- selection
	else			 -- The ON/OFF settings, right side
	    Graphics.fillRect(460, 900, 77 + (menuY * 34), 112 + (menuY * 34), themeCol)-- selection
	end
        Graphics.drawLine(60, 900, 70, 70, white)
        Graphics.drawLine(65, 895, 248, 248, white)
        Graphics.drawLine(65, 895, 282, 282, white)
        Graphics.drawLine(60, 900, 452, 452, white)
        
        menuItems = 11
        
        Font.print(fnt22, 84, 79, lang_lines[14] .. ": ", white)--Startup Category
	if ((setRetroFlow==1 and startCategory==38) or (setRetroFlow~=1 and startCategory==7)) then
	    Font.print(fnt22, 84 + 260, 79, lang_lines[109], white)--Return to last played game & category
	else
	    Font.print(fnt22, 84 + 260, 79, xTextLookup(startCategory), white)
	end

	Font.print(fnt22, 84, 79 + 34,  lang_lines[17] .. ": ", white)--Theme Color
	if themeColor == 1 then
	    Font.print(fnt22, 84 + 260, 79 + 34, lang_lines[24], white)--Red
	elseif themeColor == 2 then
	    Font.print(fnt22, 84 + 260, 79 + 34, lang_lines[25], white)--Yellow
	elseif themeColor == 3 then
	    Font.print(fnt22, 84 + 260, 79 + 34, lang_lines[26], white)--Green
	elseif themeColor == 4 then
	    Font.print(fnt22, 84 + 260, 79 + 34, lang_lines[27], white)--Grey
	elseif themeColor == 5 then
	    Font.print(fnt22, 84 + 260, 79 + 34, lang_lines[28], white)--Black
	elseif themeColor == 7 then
	    Font.print(fnt22, 84 + 260, 79 + 34, lang_lines[30], white)--Orange
	elseif themeColor == 6 then
	--@@Font.print(fnt22, 84 + 260, 79 + 34, lang_lines[29], white)
	    Font.print(fnt22, 84 + 260, 79 + 34, lang_lines[54], white)--@@ NEW! Pink
	elseif themeColor == 8 then
	--@@Font.print(fnt22, 84 + 260, 79 + 34, lang_lines[54], white)--Dark Purple
	    Font.print(fnt22, 84 + 260, 79 + 34, lang_lines[29], white)--@@ NEW! Purple @@ used to be called Dark Purple
	else
	    Font.print(fnt22, 84 + 260, 79 + 34, lang_lines[31], white)--Blue
	end

	if scanComplete == false then
	    Font.print(fnt22, 84, 79 + 68, lang_lines[19] .. ":", white)--Download Covers
	  --if getCovers == 0 then
	  --	Font.print(fnt22, 84 + 260, 79 + 68, "<  " .. lang_lines[5] .. "non-Homebrews  >", white) --< All non-Homebrews >
	    if getCovers == 2 then
		Font.print(fnt22, 84 + 260, 79 + 68, "<  " .. lang_lines[50] .. "  >", white) --< Homebrew - Special 'Vita' Archive Download >
	    else
		Font.print(fnt22, 84 + 260, 79 + 68, "<  " .. xTextLookup(getCovers) .. "  >", white) --< PS VITA/HOMEBREWS/PSP/PSX/CUSTOM/ALL >
	    end
	else
	    Font.print(fnt22, 84, 79 + 170,  lang_lines[20], white)--Reload Covers Database
	end
        
        Font.print(fnt22, 84, 79 + 102,  lang_lines[18] .. ": ", white)
	if getBGround == 1 then
	    if cur_quick_dir["background.jpg"] or cur_quick_dir["background.png"] then
		BGroundText = lang_lines[49] --CUSTOM
	    else
		BGroundText = lang_lines[22] --ON
	    end
	elseif getBGround == 2 then
	    BGroundText = lang_lines[65] --Citylights
	elseif getBGround == 3 then
	    BGroundText = lang_lines[66] --Aurora
	elseif getBGround == 4 then
	    BGroundText = lang_lines[76] --Crystal
	elseif getBGround == 5 then
	    BGroundText = lang_lines[67] --Wood
	elseif getBGround == 6 then
	    BGroundText = lang_lines[69] --Dark
	elseif getBGround == 7 then
	    BGroundText = lang_lines[74] --Playstation Pattern
	elseif getBGround == 8 then
	    BGroundText = lang_lines[71] --Retro
	elseif getBGround == 9 then
	    BGroundText = lang_lines[72] --SwitchView Basic Black
	else
	    BGroundText = lang_lines[23] --OFF
	end
	if (background_brackets == true) and (BGroundText ~= nil) then
	    BGroundText = "<  " .. BGroundText .. "  >"
	    --if setBackground ~= getBGround then	 -- Puts X icon next to unconfirmed background selection. Uncomment these 3 lines to try it.
	    --    Graphics.drawImage(Font.getTextWidth(fnt20, BGroundText) + btnMargin + 84 + 260, 5 + 79 + 102, btnAccept)	 -- Used to be btnX
	    --end
	end
        Font.print(fnt22, 84 + 260, 79 + 102, BGroundText, white)

--@@	Font.print(fnt22, 84, 79 + 136, lang_lines[21] .. ": ", white)--Language
	Font.print(fnt22, 84, 79 + 136, lang_lines[21] .. ": ", lightgrey)--Language
        if setLanguage == 1 then
            Font.print(fnt22, 84 + 260, 79 + 136, "German", white)
        elseif setLanguage == 2 then
            Font.print(fnt22, 84 + 260, 79 + 136, "French", white)
        elseif setLanguage == 3 then
            Font.print(fnt22, 84 + 260, 79 + 136, "Italian", white)
        elseif setLanguage == 4 then
            Font.print(fnt22, 84 + 260, 79 + 136, "Spanish", white)
        elseif setLanguage == 5 then
            Font.print(fnt22, 84 + 260, 79 + 136, "Russian", white)
        elseif setLanguage == 6 then
            Font.print(fnt22, 84 + 260, 79 + 136, "Swedish", white)
        elseif setLanguage == 7 then
            Font.print(fnt22, 84 + 260, 79 + 136, "Portugese", white)
        elseif setLanguage == 8 then
            Font.print(fnt22, 84 + 260, 79 + 136, "Polish", white)
        elseif setLanguage == 9 then
            Font.print(fnt22, 84 + 260, 79 + 136, "Japanese", white)
        elseif setLanguage == 10 then
            Font.print(fnt22, 84 + 260, 79 + 136, "Chinese", white)
        else
            Font.print(fnt22, 84 + 260, 79 + 136, "English", white)
        end


	Font.print(fnt22, 84, 79 + 170, lang_lines[16] .. ": ", white)--Music & Sounds
	Graphics.drawImage(84 + 260 - 22, 79 + 170 + 4, imgMusic)
        if setSounds == 0 then
            Font.print(fnt22, 84 + 260, 79 + 170, lang_lines[23], white)--OFF
	    -- Graphics.drawLine(84 + 260 - 22, 84 + 260 - 2, 79 + 170 + 4, 79 + 170 + 24, white)
	    -- Graphics.drawLine(84 + 260 - 21, 84 + 260 - 1, 79 + 170 + 4, 79 + 170 + 24, white)
	    Graphics.drawLine(322, 342, 253, 273, white)
	    Graphics.drawLine(323, 343, 253, 273, white)
	elseif not cur_quick_dir["music.mp3"] and not cur_quick_dir["music.ogg"] then
            Font.print(fnt22, 84 + 260, 79 + 170, lang_lines[22], white)--ON
	elseif musicLoop == 1 then
            Font.print(fnt22, 84 + 260, 79 + 170, lang_lines[90], white)--Music: Loop
        else
            Font.print(fnt22, 84 + 260, 79 + 170, "1x", white)
        end
        Font.print(fnt22, 484, 79 + 170, lang_lines[100] .. ": ", white)--Category Button
	if categoryButton == 1 then
	    Graphics.drawImage(484 + 275, 79 + 170 + 4, btnD)
	elseif categoryButton == 2 then
	    Graphics.drawImage(484 +  275 + 2, 79 + 170 + 4, imgArrows)		 -- up/down arrows png
	elseif categoryButton == 3 then
	    Graphics.drawImage(484 + 275, 79 + 170 + 4, btnS)
            Font.print(fnt22, 484 + 275 + 22, 79 + 170 + 1, "/", white)
            Font.print(fnt20, 484 + 275 + 35, 79 + 170 + 4, "▼", white)	 -- large down arrow. Note: large up arrow is ▲
	    Graphics.drawImage(484 + 275 + 58, 79 + 170 + 4, btnS)
        else
	    Graphics.drawImage(484 + 275, 79 + 170 + 4, btnS)
        end

                Font.print(fnt22, 84, 79 + 204, lang_lines[15] .. ": ", white)--Reflection Effect
        if setReflections == 1 then
            Font.print(fnt22, 84 + 260 + toggle1X, 79 + 204, lang_lines[22], white)--ON
        else
            Font.print(fnt22, 84 + 260 + toggle1X, 79 + 204, lang_lines[23], white)--OFF
        end
        Font.print(fnt22, 484, 79 + 204, lang_lines[96] .. ": ", white)--RetroFlow
        if setRetroFlow == 1 then
            Font.print(fnt22, 484 + toggle2X + 275, 79 + 204, lang_lines[22], white)--ON
        else
            Font.print(fnt22, 484 + toggle2X + 275, 79 + 204, lang_lines[23], white)--OFF
        end
		
        Font.print(fnt22, 84, 79 + 238, lang_lines[46] .. ": ", white)--Show Homebrews
	if showHomebrews == 1 then
            Font.print(fnt22, 84 + 260 + toggle1X, 79 + 238, lang_lines[22], white)--ON
        else
            Font.print(fnt22, 84 + 260 + toggle1X, 79 + 238, lang_lines[23], white)--OFF
        end
        Font.print(fnt22, 484, 79 + 238, lang_lines[99] .. ": ", white)--Hide Empty Categories
	if hideEmptyCats == 1 then
            Font.print(fnt22, 484 + toggle2X + 275, 79 + 238, lang_lines[22], white)--ON
        else
            Font.print(fnt22, 484 + toggle2X + 275, 79 + 238, lang_lines[23], white)--OFF
        end

        Font.print(fnt22, 84, 79 + 272, lang_lines[108] .. ": ", white)--Recently Played
        if showRecentlyPlayed == 1 then
            Font.print(fnt22, 84 + 260 + toggle1X, 79 + 272, lang_lines[22], white)--ON
        else
            Font.print(fnt22, 84 + 260 + toggle1X, 79 + 272, lang_lines[23], white)--OFF
        end
        Font.print(fnt22, 484, 79 + 272, lang_lines[94] .. ": ", white)--Lock Current View (#*)
        if lockView == 1 then
            Font.print(fnt22, 484 + toggle2X + 275, 79 + 272, lang_lines[22], white)--ON
        else
            Font.print(fnt22, 484 + toggle2X + 275, 79 + 272, lang_lines[23], white)--OFF
        end
        
        Font.print(fnt22, 84, 79 + 306, lang_lines[91] .. ": ", white)--Allow View #5/#6
	if setSwitch == 1 then
	    Font.print(fnt22, 84 + 260 + toggle1X, 79 + 306, lang_lines[22], white)--ON
	    Font.print(fnt22, 84, 79 + 340, lang_lines[107] .. ": ", white)--Crop 'Vita' in View #5
	    if View5VitaCropTop == 1 then
		Font.print(fnt22, 84 + 260 + toggle1X, 79 + 340, lang_lines[22], white)--ON
	    else
		Font.print(fnt22, 84 + 260 + toggle1X, 79 + 340, lang_lines[23], white)--OFF
	    end
	else
	    Font.print(fnt22, 84 + 260 + toggle1X, 79 + 306, lang_lines[23], white)--OFF
	    Font.print(fnt22, 84, 79 + 340, lang_lines[107] .. ": ", lightgrey)--Crop 'Vita' in View #5
	    if View5VitaCropTop == 1 then
		Font.print(fnt22, 84 + 260 + toggle1X, 79 + 340, lang_lines[22], lightgrey)--ON
	    else
		Font.print(fnt22, 84 + 260 + toggle1X, 79 + 340, lang_lines[23], lightgrey)--OFF
	    end
	end

	if menuY > 11 then	 -- System Apps / System Menu / Utilities
	    Graphics.fillRect(60, 60 + 280, 77 + (3 * 34), 112 + (10 * 34), darkalpha)-- selection
	    Graphics.fillRect(60, 60 + 280, 77 + (2 * 34), 112 + (10 * 34), darkalpha)-- selection
	    Graphics.drawImage(60, 122, imgUtilityBorder)
	    Graphics.fillRect(60, 60 + 280, 77 + ((menuY - 9) * 34), 112 + ((menuY - 9) * 34), themeCol)-- selection
	    Font.print(fnt22, 84, 79 + 102, lang_lines[95], white)		 -- Decrypt Icons
	    Font.print(fnt22, 84, 79 + 136, lang_lines[79], white)		 -- News
	    Font.print(fnt22, 84, 79 + 170, lang_lines[80], white)		 -- Store
	    Font.print(fnt22, 84, 79 + 204, lang_lines[81], white)		 -- Album
	    Font.print(fnt22, 84, 79 + 238, lang_lines[82], white)		 -- Controls
	    Font.print(fnt22, 84, 79 + 272, lang_lines[83], white)		 -- System Settings
	    Font.print(fnt22, 84, 79 + 306, "VitaShell", white)			 -- VitaShell
	    Font.print(fnt22, 84, 79 + 340, lang_lines[85], white)		 -- Trophies
	end

	-- sanitized because of the "invalid character spacing glitch"
	PrintCentered(fnt22, 60+140, 79 + 374, sanitize(lang_lines[101]), white, 22)--Utilities
        PrintCentered(fnt22, 60+140+280, 79 + 374, sanitize(lang_lines[84]), white, 22)--Exit
	PrintCentered(fnt22, 60+140+560, 79 + 374, sanitize(lang_lines[13]), white, 22)--More Information (About)
        
        status = System.getMessageState()
        if status ~= RUNNING then
            
            if (Controls.check(pad, CTRL_ACCEPT) and not Controls.check(oldpad, CTRL_ACCEPT)) then	 -- Used to be SCE_CTRL_CROSS
                if menuY == 0 then
                  --if startCategory < 7 then
		    if (setRetroFlow==1 and startCategory<38)
		    or (setRetroFlow~=1 and startCategory<7) then
                        startCategory = startCategory + 1
                    else
                        startCategory = 0
                    end
                elseif menuY == 1 then
                    if themeColor == 5 then	 -- cheap reorder hack to maintain HEXFlow Launcher 0.5 compatibility.
                        themeColor = 7
                    elseif themeColor == 7 then
                        themeColor = 6
                    elseif themeColor == 6 then
                        themeColor = 8
                    elseif themeColor < 5 then   -- normally "elseif themeColor < 7 then"
                        themeColor = themeColor + 1
                    else
                        themeColor = 0
                    end
                    SetThemeColor()
                elseif menuY == 2 then
                    if gettingCovers == false then
                        gettingCovers = true
                        DownloadCategoryCovers()
                    end
                elseif menuY == 3 then
                    if (setBackground == 0) and (getBGround == 0) then	 -- "OFF" becomes "<ON>"
			setBackground, getBGround = 1, 1
			background_brackets = true
		    else
			if (getBGround == 0) or (setBackground == getBGround) then
			    setBackground, getBGround = 0, 0		 -- "<OFF>" (with <>) and everything else (without <>) becomes "OFF"
			else
			    setBackground = getBGround			 -- "<Name of Background>" becomes "Name of Background"
			end
			background_brackets = false
		    end
		    ApplyBackground(setBackground)
                elseif menuY == 4 then
--@@		    if setLanguage < 9 then
--@@                        setLanguage = setLanguage + 1
--@@                    else
--@@                        setLanguage = 0
--@@                    end
--@@		    ChangeLanguage()
                elseif menuY == 5 then
		    if menuX == 0 then
			if Sound.isPlaying(sndMusic) then
			    Sound.close(sndMusic)
			    sndMusic = click--temp
			end
			if setSounds == 1 then
			    if (cur_quick_dir["music.mp3"] or cur_quick_dir["music.ogg"])
			    and musicLoop == 1 then
				musicLoop = 0
			    else
				setSounds = 0
			    end
			else
			    setSounds = 1
			    musicLoop = 1
			end
			play_music()
		    else
			if categoryButton < 3 then
			    categoryButton = categoryButton + 1
			else
			    categoryButton = 0
			end
			ChangeLanguage()	 -- refresh footer button spacing if using "category button: up/down"
		    end
                elseif menuY == 6 then
		    if menuX == 0 then
			if setReflections == 1 then
			    setReflections = 0
			else
			    setReflections = 1
			end
		    else
			if setRetroFlow == 1 then
			    setRetroFlow = 0
			    if startCategory > 35 then	 -- "return to last played" noretro: 7. "return to last played" yesretro: 38
				startCategory = startCategory - 31
			    elseif startCategory > 4 then
				startCategory = 1
			    end
			    if getCovers > 35 then
				getCovers = getCovers - 31
			    elseif getCovers > 4 then
				getCovers = 1
			    end
			    if showCat > 35 then
				showCat = showCat - 31
			    elseif showCat > 4 then
				showCat = 1
			    end
			else
			    setRetroFlow = 1
			    if startCategory > 4 then
				startCategory = startCategory + 31
			    end
			    if getCovers > 4 then
				getCovers = getCovers + 31
			    end
			    if showCat > 4 then
				showCat = showCat + 31
			    end
			end
			WriteRecentlyPlayed("hotfix_mode")
			LoadAppTitleTables()
			check_for_out_of_bounds()
			GetNameSelected()		 -- refresh selected app's name when toggling Retroflow
		    end
                elseif menuY == 7 then
		    if menuX == 0 then
			if showHomebrews == 1 then
			    showHomebrews = 0
			else
			    showHomebrews = 1
			end
		    else
			if hideEmptyCats == 1 then
			    hideEmptyCats = 0
			else
			    hideEmptyCats = 1
			end
		    end
                elseif menuY == 8 then
		    if menuX == 0 then
                	if showRecentlyPlayed == 1 then
                            showRecentlyPlayed = 0
			    if (setRetroFlow == 1 and startCategory == 38)
			    or (setRetroFlow ~= 1 and startCategory == 7) then
				-- If "return to last played game" is enabled, preserve recently played #1.
				local inf = assert(io.open(cur_dir .. "/lastplayedgame.dat", "rw"), "Failed to open lastplayedgame.dat")
				local lines = (inf:read("*line") or "") .. "\n" .. (inf:read("*line") or "")
				inf:close()
				file = io.open(cur_dir .. "/lastplayedgame.dat", "w")
				file:write(lines)
				file:close()
			    else
				if startCategory == 5 then
				    startCategory = 1
				end
				if showCat == 5 then
				    showCat = 1
				end
				local file_over = System.openFile(cur_dir .. "/lastplayedgame.dat", FCREATE)
				cur_quick_dir["lastplayedgame.dat"] = true
				io.open(cur_dir .. "/lastplayedgame.dat","w"):close()	 -- Clear old lastplayedgame data
				System.writeFile(file_over, " \n \n \n \n \n \n \n \n \n \n \n \n \n", 26)	 -- fixes the lag-at-first-launch glitch.
				System.closeFile(file_over)
			    end
                	else
                	    showRecentlyPlayed = 1
			end
			recently_played_table = {}
			ReadCustomSort("lastplayedgame.dat", recently_played_table)
		    else
			if lockView == 1 then
			    lockView = 0
			else
			    lockView = 1
			end
		    end
                elseif menuY == 9 then
		    if menuX == 0 then
                	if setSwitch == 1 then
			    bottomMenu = false
			    --menuSel = 0
                            setSwitch = 0
                	else
                	    setSwitch = 1
			end
		    end
                elseif menuY == 10 then
		    if menuX == 0 then
                	if View5VitaCropTop == 1 then
			    View5VitaCropTop = 0
                	else
                	    View5VitaCropTop = 1
			end
		    end
                elseif menuY == 11 then
		    if menuX == 0 then
			utilityMenu = true
			menuY = menuItems + 1
			imgUtilityBorder = Graphics.loadImage("app0:/DATA/utilityoverlay.png")
		    elseif menuX == 1 then
			-- Exit
			System.exit()
		    else
			-- More Information / About
			showMenu = 3
			menuY = 0
			menuX = 0
		    end
                elseif utilityMenu == true then			 -- could also be "(menuY > 11) and (menuY < 21) then"
		    menuSel = menuY - menuItems - 1		 -- Lazy code, needs improved later maybe
		    execute_switch_bottom_menu()
                end
                
                
		write_config()	 --Save settings
            elseif (Controls.check(pad, SCE_CTRL_UP)) and not (Controls.check(oldpad, SCE_CTRL_UP)) then
		if menuY == 12 then
		    close_utility_menu()
		elseif menuY == 5 or (menuY == 11 and menuX ~= 2) then -- When moving to start menu rows with LESS columns, round "menuX" DOWN.
		    menuX = 0
                    menuY = menuY - 1
                elseif menuY > 0 then
                    menuY = menuY - 1
		else
		    menuX = 0
		    menuY = menuItems
                end
            elseif (Controls.check(pad, SCE_CTRL_DOWN)) and not (Controls.check(oldpad, SCE_CTRL_DOWN)) then
		if utilityMenu == true then
		    if menuY < menuItems + utilityItems + 1 then
			menuY = menuY + 1
		    else
			close_utility_menu()
		    end
		elseif menuY == 10 and menuX == 2 then	 -- When moving to start menu rows with MORE columns, round "menuX" DOWN.
		    menuY = menuY + 1
		    menuX = 1
		elseif menuY < menuItems then
                    menuY = menuY + 1
		else
		    menuY=0
		    menuX=0				 -- When going from bottom to top of settings, set menuX to 0.
                end
            elseif (Controls.check(pad, SCE_CTRL_LEFT)) and not (Controls.check(oldpad, SCE_CTRL_LEFT)) then
		if utilityMenu == true then
		    close_utility_menu()
		elseif menuY==2 then		 --covers download selection -- [1]=PS VITA, [2]=HOMEBREWS, [3]=PSP, [4]=PSX, [5]=CUSTOM, [default]=ALL
		    getCovers = Category_Minus(getCovers-1)
		elseif menuY==3 then		 --Background selection
		-- [1]=Custom, [2]=Citylights, [3]=Aurora, [4]=Crystal, [5]=Wood, [6]=Dark, [7]=Playstation Pattern, [8]=Retro.
		    if getBGround > 0 then
			getBGround = getBGround - 1
		  --elseif setSwitch == 1 then
		  --	getBGround = 9
		    else
			getBGround = 8
		    end
		    background_brackets = true
		elseif menuY == 11 then
		    if menuX > 0 then
			menuX = menuX - 1
		    else
			menuX=2
		    end
		elseif menuY > 4 then
		    if menuX == 0 then
			menuX = 1
		    else
			menuX = 0
		    end
		end
            elseif (Controls.check(pad, SCE_CTRL_RIGHT)) and not (Controls.check(oldpad, SCE_CTRL_RIGHT)) then
		if utilityMenu == true then
		    close_utility_menu()
		elseif menuY==2 then				 --covers download selection -- [1]=PS VITA, [2]=HOMEBREWS, [3]=PSP, [4]=PSX, [5]=CUSTOM, [default]=ALL
		    getCovers = Category_Plus(getCovers+1)
		elseif menuY==3 then				 --Background selection
		-- [1]=Custom, [2]=Citylights, [3]=Aurora, [4]=Crystal, [5]=Wood, [6]=Dark, [7]=Playstation Pattern, [8]=Retro.
		  --if getBGround == 8 and setSwitch == 1 then
		  --	getBGround = 9
		    if getBGround < 8 then
			getBGround = getBGround + 1
		    else
			getBGround = 0
		    end
		    background_brackets = true
		elseif menuY == 11 then
		    if menuX > 1 then
			menuX = 0
		    else
			menuX = menuX + 1
		    end
		elseif menuY > 4 then
		    if menuX == 0 then
			menuX = 1
		    else
			menuX = 0
		    end
		end
	    end --End of Control Section
	end
    elseif showMenu == 3 then
        
        -- More Information / About
        -- Footer buttons and icons. label X's are set in ChangeLanguage()
        Graphics.drawImage(label1AltImgX, 510, btnCancel)	 -- Used to be btnO
        Font.print(fnt20, label1AltX, 508, lang_lines[11], white)--Close
        
        Graphics.fillRect(30, 930, 24, 496, darkalpha)-- bg
        
        Font.print(fnt20, 54, 42, "HexFlow Custom - version " .. appversion .. " by BlackSheepBoy69\nRevamp mod for VitaHEX's HexFlow Launcher 0.5\nSupport the original creator on patreon.com/vitahex", white)-- Draw info
        Font.print(fnt15, 690, 42, "Sort time: ".. sortTime .. " ms.\nRead time: ".. applistReadTime .. " ms.\nFunction Load time: ".. functionTime .. " ms.\nOne Loop time: ".. oneLoopTime .. " ms.", white)
        Graphics.drawLine(30, 930, 124, 124, white)
        Graphics.drawLine(30, 930, 384, 384, white)
        Font.print(fnt20, 54, 132, "Custom Backgrounds & Music\nIn 'ux0:/data/HexFlow/', place your image - 'background.png' or 'background.jpg'\n(1280x720 max) and song - 'music.ogg'. Unlocks setting 'Music & Sounds: Loop/Play 1x'"
            .. "\n\nCustom Covers & RetroFlow (requires 'RetroFlow' installed)\nPlace your custom covers in 'ux0:/data/HexFlow/COVERS/PSVITA' or '/PSP' or '/PS1'\nCover images must be in png format and file name must match the App ID or App Name.\nRespectively, 'RetroFlow: ON' lets it read from 'ux0:data/RetroFlow/COVERS' and '/ROMS'"
            .. "\n\nCustom Category\nTake the file 'ux0:/data/HexFlow/applist.dat' and rename it to customsort.dat then\nrearrange the titles how you like. It will spawn in a new category ('Custom')"
            .. "\n\nCredit to VitaHEX, Sakis RG, and everyone who worked on HexFlow Launcher 0.5 which"
            .. "\nthis is based on, jimbob4000 and everyone who worked on RetroFlow Launcher 5.0.2, for"
            .. "\ngeneral support/inspiration, Rinnegatamante for Lua Player Plus, Axce, Fwannmacher"
            .. "\nDaRk_ViVi, yzzyx-network, all translator, and one or more coders anonymous.", white)-- Draw info
    
    end
    
    -- Terminating rendering phase
    Graphics.termBlend()
    if showMenu == 1 then
        --Left Analog rotate preview box
	if spin_allowance > 0 then
	    if (prvRotY > 1.70) and (prvRotY < 2) then
		prvRotY = -1.3	 --never show the back of the cover lol
		OverrideCategory()
		GetInfoSelected()
	    else
		prvRotY=prvRotY+0.1
		spin_allowance = spin_allowance - 0.1
	    end
	elseif mx < 64 then
	    if prvRotY>-0.5 then
		prvRotY=prvRotY-0.02
	    end
        elseif mx > 180 then
	    if prvRotY<0.6 then
		prvRotY=prvRotY+0.02
	    end
        end
    end
    --Controls Start
    if showMenu == 0 then
        --Navigation Left Analog
	tmp_move = 0
	if delayButton < 0.5 then
	    if mx < 64 then
		delayButton = 1
		tmp_move = 0 - 1
	    elseif mx > 180 then
		delayButton = 1
		tmp_move = tmp_move + 1
	    end
	    if my > 180 and showView == 6 then
		delayButton = 1
		tmp_move = tmp_move + 6
	    elseif my > 250 and showView == 5 and bottomMenu == false then
		delayButton = 1
		bottomMenu = true
	    elseif my < 64 then
		if showView == 6 then
		    delayButton = 1
		    tmp_move = tmp_move - 6
		elseif bottomMenu == true then
		    delayButton = 1
		    bottomMenu = false
		end
	    end
	    if tmp_move < 0 then
		quick_scroll = 0
		p_minus(-tmp_move)
	    elseif tmp_move > 0 then
		quick_scroll = 0
		p_plus(tmp_move)
	    elseif delayButton == 1 then
		Sound.play(click, NO_LOOP)
	    end
	end
        
        -- Navigation Buttons
        if (Controls.check(pad, CTRL_ACCEPT) and not Controls.check(oldpad, CTRL_ACCEPT)) then	 -- Used to be SCE_CTRL_CROSS
	    if bottomMenu then
		execute_switch_bottom_menu()
	    elseif gettingCovers == false and app_short_title~="-" then
                FreeMemory()
		local file = xCatLookup(showCat)[p]
		local Working_Launch_ID = file.name	 -- Example: VITASHELL. This hotfix seems to 99% stop the "please close HexLauncher Custom" errors.

                WriteRecentlyPlayed(Working_Launch_ID)

		launch_mode = file.launch_type		 -- 0 real apps, 1 UNUSED (PS Mobile?), 2 PSP/PS1, 3 PS1 Retroarch, 4 UNUSED, 5 N64, 6 SNES, 7 NES...
		if launch_mode == 0 then
		    System.launchApp(Working_Launch_ID)
		    System.exit()
		else
		    romfile = xRomDirLookup(launch_mode) .. "/" .. file.name		 -- ex: "ux0:/data/RetroFlow/ROMS/Nintendo - Game Boy/batman.gb"

		    if apptype and xRomDirLookup(launch_mode) then
			if launch_mode == 3 then	 --@@ PS1
			    launch_retroarch(romfile, "app0:/pcsx_rearmed_libretro.self")
			elseif launch_mode == 5 then	 --@@ N64
			    launch_DaedalusX64(romfile)
			elseif launch_mode == 6 then	 --@@ SNES
			    launch_retroarch(romfile, "app0:/snes9x2005_libretro.self")
			elseif launch_mode == 7 then	 --@@ NES
			    launch_retroarch(romfile, "app0:/quicknes_libretro.self")
		      --elseif launch_mode ==   then	 --@@ NDS
		      --    launch_NooDS(romfile)
			elseif launch_mode == 8 then	 --@@ GBA. @@ launch_NooDS(romfile) can also be used for this.
			    launch_retroarch(romfile, "app0:/gpsp_libretro.self")
			elseif launch_mode == 9 then	 --@@ GBC
			    launch_retroarch(romfile, "app0:/gambatte_libretro.self")
			elseif launch_mode == 10 then	 --@@ GB
			    launch_retroarch(romfile, "app0:/gambatte_libretro.self")
			elseif launch_mode == 11 then	 --@@ DREAMCAST
			    launch_Flycast(romfile)
			elseif launch_mode == 12 then	 --@@ SEGA_CD
			    launch_retroarch(romfile, "app0:/genesis_plus_gx_libretro.self")
			elseif launch_mode == 13 then	 --@@ S32X
			    launch_retroarch(romfile, "app0:/picodrive_libretro.self")
			elseif launch_mode == 14 then	 --@@ MD
			    launch_retroarch(romfile, "app0:/genesis_plus_gx_libretro.self")
			elseif launch_mode == 15 then	 --@@ SMS
			    launch_retroarch(romfile, "app0:/smsplus_libretro.self")
			elseif launch_mode == 16 then	 --@@ GG
			    launch_retroarch(romfile, "app0:/smsplus_libretro.self")
			elseif launch_mode == 17 then	 --@@ TG16
			    launch_retroarch(romfile, "app0:/mednafen_pce_fast_libretro.self")
			elseif launch_mode == 18 then	 --@@ TGCD
			    launch_retroarch(romfile, "app0:/mednafen_pce_fast_libretro.self")
			elseif launch_mode == 19 then	 --@@ PCE
			    launch_retroarch(romfile, "app0:/mednafen_pce_fast_libretro.self")
			elseif launch_mode == 20 then	 --@@ PCECD
			    launch_retroarch(romfile, "app0:/mednafen_pce_fast_libretro.self")
			elseif launch_mode == 21 then	 --@@ AMIGA
			    launch_retroarch(romfile, "app0:/puae_libretro.self")
			elseif launch_mode == 22 then	 --@@ C64
			    launch_retroarch(romfile, "app0:/vice_x64_libretro.self")
			elseif launch_mode == 23 then	 --@@ WSCAN_COL
			    launch_retroarch(romfile, "app0:/mednafen_wswan_libretro.self")
			elseif launch_mode == 24 then	 --@@ WSWAN
			    launch_retroarch(romfile, "app0:/mednafen_wswan_libretro.self")
		      --elseif launch_mode == 26 then	 --@@ SCUMMVM @@ needs work
		      --    launch_scummvm(romfile, ?????????????????)
			elseif launch_mode == 25 then	 --@@ PICO8
			    launch_Fake08(romfile)
			elseif launch_mode == 26 then	 --@@ MSX2
			    launch_retroarch(romfile, "app0:/fmsx_libretro.self")
			elseif launch_mode == 27 then	 --@@ MSX1
			    launch_retroarch(romfile, "app0:/fmsx_libretro.self")
			elseif launch_mode == 28 then	 --@@ ZXS
			    launch_retroarch(romfile, "app0:/fuse_libretro.self")	 --@@ NOTE: FUSE NOT FMSX
			elseif launch_mode == 29 then	 --@@ ATARI_7800
			    launch_retroarch(romfile, "app0:/prosystem_libretro.self")
			elseif launch_mode == 30 then	 --@@ ATARI_5200
			    launch_retroarch(romfile, "app0:/atari800_libretro.self")
			elseif launch_mode == 31 then	 --@@ ATARI_2600
			    launch_retroarch(romfile, "app0:/stella2014_libretro.self")
			elseif launch_mode == 32 then	 --@@ ATARI_LYNX
			    launch_retroarch(romfile, "app0:/handy_libretro.self")
			elseif launch_mode == 33 then	 --@@ COLECOVISION
			    launch_retroarch(romfile, "app0:/bluemsx_libretro.self")
			elseif launch_mode == 34 then	 --@@ VECTREX
			    launch_retroarch(romfile, "app0:/vecx_libretro.self")
		      --elseif launch_mode ==    then	 --@@ FBA
		      --    launch_retroarch(romfile, "app0:/fbalpha2012_libretro.self")
		      --elseif launch_mode ==    then	 --@@ MAME_2003_PLUS
		      --    launch_retroarch(romfile, "app0:/mame2003_plus_libretro.self")
		      --elseif launch_mode ==    then	 --@@ MAME_2000
		      --    launch_retroarch(romfile, "app0:/mame2000_libretro.self")
		      --elseif launch_mode ==    then	 --@@ NEOGEO
		      --    launch_retroarch(romfile, "app0:/fbalpha2012_neogeo_libretro.self")
			elseif launch_mode == 35 then	 --@@ NGPC
			    launch_retroarch(romfile, "app0:/mednafen_ngp_libretro.self")
			end
		    else
			status = System.getMessageState()
			if status ~= RUNNING then
			    System.setMessage("Entry either has no .app_type or invalid .app_type\nTry refreshing cache?", false, BUTTON_OK)
			end
		    end
		end
            end
        elseif (Controls.check(pad, SCE_CTRL_TRIANGLE) and not Controls.check(oldpad, SCE_CTRL_TRIANGLE)) then
            if showMenu == 0 and app_short_title~="-" then
		--imgFav_large_on = Graphics.loadImage("app0:/DATA/fav-large-on.png")
		--imgFav_large_off = Graphics.loadImage("app0:/DATA/fav-large-off.png")
		prvRotY = 0
		GetInfoSelected()	 -- Full info scan is only here now.
                showMenu = 1
            end
        elseif (Controls.check(pad, SCE_CTRL_START) and not Controls.check(oldpad, SCE_CTRL_START)) then
            if showMenu == 0 then
		imgMusic = Graphics.loadImage("app0:/DATA/music_note.png")
		getBGround = setBackground
		background_brackets = true
		inPreview = false	 -- Probably not necessary
                showMenu = 2
            end
--	elseif (Controls.check(pad, SCE_CTRL_SELECT) and not Controls.check(oldpad, SCE_CTRL_SELECT)) then
--	    if n64_fix == true then	 -- n64_fix
--		n64_fix = false		 -- n64_fix
--	    else			 -- n64_fix
--		n64_fix = true		 -- n64_fix
--	    end				 -- n64_fix
--	    System.setMessage(tostring(DownloadCover(xCatLookup(showCat)[p])), false, BUTTON_OK)
	elseif (categoryButton == 3 and Controls.check(pad, SCE_CTRL_DOWN) and Controls.check(pad, SCE_CTRL_SQUARE) and not Controls.check(oldpad, SCE_CTRL_SQUARE))
	or ((categoryButton == 1 or categoryButton == 2) and Controls.check(pad, SCE_CTRL_UP) and not Controls.check(oldpad, SCE_CTRL_UP)) then
	    showCat = Category_Minus(showCat-1)
	elseif ((categoryButton ~= 1 and categoryButton ~= 2) and Controls.check(pad, SCE_CTRL_SQUARE) and not Controls.check(oldpad, SCE_CTRL_SQUARE))
	or ((categoryButton == 1 or categoryButton == 2) and Controls.check(pad, SCE_CTRL_DOWN) and not Controls.check(oldpad, SCE_CTRL_DOWN)) then
	    showCat = Category_Plus(showCat+1)
        elseif (Controls.check(pad, CTRL_CANCEL) and not Controls.check(oldpad, CTRL_CANCEL))	 -- Used to be SCE_CTRL_CIRCLE
	and (lockView == 0) then
            -- VIEW
	    if showView > 3 and setSwitch == 0 then
		showView = 0
	    elseif showView < 6 then
                showView = showView + 1
		if showView == 5 then
		    if (curTotal > 4) and (p > curTotal - 3) then
			master_index = curTotal - 3
		    end
		    for k, v in pairs(files_table) do	 --Due to a quirk in LuaJIT, clearing the "All" table clears every table.
			if string.find(v.icon_path, "app0:/DATA/missing_cover") then
			    FileLoad[v] = nil
			    Threads.remove(v)
			    v.icon_path = v.icon_path:gsub("app0:/DATA/missing_cover", "app0:/DATA/icon")
			    if v.ricon then
				Graphics.freeImage(v.ricon)
				v.ricon = nil
			    end
			end
		    end
		    if SwitchviewAssetsAreLoaded ~= true then
			load_SwitchView()
		    end
		end
            else
		master_index = p
		-- Switch over to true placeholder icons when leaving SwitchView
		for k, v in pairs(files_table) do	--Due to a quirk in LuaJIT, clearing the "All" table clears every table.
		    if string.find(v.icon_path, "app0:/DATA/icon") then
			FileLoad[v] = nil
			Threads.remove(v)
			v.icon_path = v.icon_path:gsub("app0:/DATA/icon", "app0:/DATA/missing_cover")
			if v.ricon then
			    Graphics.freeImage(v.ricon)
			    v.ricon = nil
			end
		    end
		end
                showView = 0
            end
	    bottomMenu = false	 -- (1/2) Reset SwitchView bottom menu
	    menuSel = 1		 -- (2/2)
            menuY = 0
            startCovers = false
	    write_config()	 --Save settings
        elseif (Controls.check(pad, SCE_CTRL_LEFT)) and not (Controls.check(oldpad, SCE_CTRL_LEFT)) then
	    p_minus(1)
        elseif (Controls.check(pad, SCE_CTRL_RIGHT)) and not (Controls.check(oldpad, SCE_CTRL_RIGHT)) then
	    p_plus(1)

        elseif (Controls.check(pad, SCE_CTRL_LTRIGGER)) and not (Controls.check(oldpad, SCE_CTRL_LTRIGGER)) then
	    bottomMenu = false
	    if (Controls.check(pad, SCE_CTRL_SELECT)) and p~=0 and p~=1 then	 -- Hold select + press L to move left by alphabet.
		for i=0, #xCatLookup(showCat) do	 -- the loop.
		    local v = #xCatLookup(showCat) - i	 -- go from the back.
		    if v == 1 then			 -- If you ran out of stuff to check...
			p_minus(p - 1)			 -- ... then move to position 1...
			break				 -- ... and exit the loop.
		    elseif (p > v)
		    and (first_letter_of_apptitle(v) < first_letter_of_apptitle(p))	    -- if target's letter is EARLIER in the alphabet...
		    and (first_letter_of_apptitle(v) ~= first_letter_of_apptitle(v-1)) then -- ... and target is the FIRST of a kind of that letter...
			p_minus(p - v)							    -- ... then jump to target.
			break
		    end
		end
	    else
		p_minus(5)
	    end
        elseif (Controls.check(pad, SCE_CTRL_RTRIGGER)) and not (Controls.check(oldpad, SCE_CTRL_RTRIGGER)) then
	    bottomMenu = false
	    if (Controls.check(pad, SCE_CTRL_SELECT)) and p ~= #xCatLookup(showCat) then	 -- Hold select + press R to move right by alphabet.
		for i=1, #xCatLookup(showCat) do	 --the loop.
		    if i == #xCatLookup(showCat) then	 -- If you ran out of stuff to check...
			p_plus(i - p)			 -- ... then move to position max...
			break				 -- ... and exit the loop.
		    elseif (p < i)
		    and (first_letter_of_apptitle(i) > first_letter_of_apptitle(p)) then
			p_plus(i - p)			 -- Jump to a target with LATER-in-alphabet letter.
			break
		    end
		end
	    else
		p_plus(5)
	    end
	elseif (Controls.check(pad,SCE_CTRL_UP)) and not (Controls.check(oldpad,SCE_CTRL_UP)) then
	    if showView==5 and bottomMenu==true then
		bottomMenu = false
		if setSounds == 1 then
		    Sound.play(click, NO_LOOP)
		end
	    elseif showView==6 then
		p_minus(6)
	    end
	elseif (Controls.check(pad,SCE_CTRL_DOWN)) and not (Controls.check(oldpad,SCE_CTRL_DOWN)) then
	    if showView==5 and bottomMenu==false then
		bottomMenu = true
		if setSounds == 1 then
		    Sound.play(click, NO_LOOP)
		end
	    elseif showView==6 then
		p_plus(6)
	    end
	end
        
        -- Touch Input
        if x1 ~= nil then
            if xstart == nil then
		touchdown = 1
                xstart = x1
		ystart = y1
		for k, v in pairs(tap_zones) do
		    if (x1 > v[1]) and (x1 < v[1] + v[3]) and (y1 > v[2]) and (y1 < v[2] + v[3]) then
			tap_target = v[4]	 -- The above line will only make sense if you look at a tap zone's data.
			break
		    end
		end
            end
            if showView == 1 then
		-- flat zoom out view - pan camera 1/487 p per pixel moved.
	        targetX = targetX + ((x1 - xstart) / 487)
	    elseif (showView == 2) or (showView == 3) then
		-- zoomin view & left side view - pan camera 1/1000 p per pixel moved.
	        targetX = targetX + ((x1 - xstart) / 1000)
	    elseif showView == 5 then
		-- SwitchView - pan camera 1/1840 p per pixel moved with gentle bump back at ends.
		if targetX + ((x1 - (xstart)) / 1840) > curTotal + 0.2 then
		    targetX = curTotal + 0.2			 -- 0.2 above max border. Kept in bounds by master_index.
		elseif curTotal <= 3 and targetX + ((x1 - xstart) / 1840) < curTotal - 0.2 then
		    targetX = curTotal - 0.2			 -- 0.2 below minimum border.
		elseif curTotal > 3 and targetX + ((x1 - xstart) / 1840) < 3.8 then
		    targetX = 3.8				 -- 0.2 below special fixed minimum border.
		else
		    targetX = targetX + ((x1 - xstart) / 1840)
		end
	    elseif showView == 6 then
		-- Grid View - pan camera 1/1265 p per pixel moved on Y AXIS with gentle bump back at ends.
		if (curTotal > 12) and (targetY - ((y1 - ystart) / 1265) > (BaseYHotfix + 0.7)) and (targetY < BaseYHotfix + 0.7) and not ((curTotal > 18) and (master_index <= 6))then
		    targetY = BaseYHotfix + 0.7			 -- 0.15 above the special Y-axis max border (BaseYHotfix + 0.55). Kept in bounds by master_index.
		elseif (curTotal > 12) and (targetY - ((y1 - ystart) / 1265) < 0.4) then
		    targetY = 0.4				 -- 0.15 below the special Y-axis minimum border (0.55)
		elseif (curTotal <= 12) and (targetY - ((y1 - ystart) / 1265) < -0.05) and (targetY > -0.05) then
		    targetY = -0.05				 -- 0.05 below normal Y minimum border (0)
		elseif (curTotal <= 12) and (targetY - ((y1 - ystart) / 1265) > 0.05) then
		    targetY = 0.05				 -- 0.05 above normal Y max border (0)
		else
		    targetY = targetY - ((y1 - ystart) / 1265)
		end
	    else
		-- all other views - pan camera 1/700 p per pixel moved.
	        targetX = targetX + ((x1 - xstart) / 700)
	    end
	    if x1 > xstart + 60 then
		if master_index > 1 then
		    master_index = master_index - 1
		end
                xstart = x1					 --refresh tracking start point
                p = p - 1
                if p > 0 then
                    GetNameSelected()
                end
		bottomMenu = false
		touchdown = 0
	    elseif x1 < xstart - 60 then
                xstart = x1					 --refresh tracking start point
                p = p + 1
		if showView ~= 5 or master_index < curTotal - 3 then
		    master_index = master_index + 1
		end
                if p <= curTotal then
                    GetNameSelected()
                end
		bottomMenu = false
		touchdown = 0
            end
	    if (showView == 6) and (y1 > ystart + 60) then	 -- Y axis tracking for Grid View!!! Force-move "p" and "master_index" (the camera) each by 6... then refresh Y-axis point of reference "ystart"
		if master_index > 6 then			 -- prevents camera from going negative.
		    master_index = master_index - 6
		end
                ystart = y1
                p = p - 6
                if p > 0 then
                    GetNameSelected()
                end
		touchdown = 0
	    elseif (showView == 6) and (y1 < ystart - 60) then
                ystart = y1
                p = p + 6
		if not (math.floor((master_index - 1) / 6) > math.floor((curTotal - 1) / 6) - 2) then	 -- prevents camera from going out of bounds.
		    master_index = master_index + 6
		end
                if p <= curTotal then
                    GetNameSelected()
                end
		touchdown = 0
            end
	elseif xstart ~= nil then
	    -- If where you touch is the same as where you release... move there (SwitchView/Grid View only)
	    if touchdown~=0 then
		for k, v in pairs(tap_zones) do
		    if  (x1_old > v[1]) and (x1_old < v[1] + v[3]) and (y1_old > v[2]) and (y1_old < v[2] + v[3]) and (tap_target == v[4]) then
			bottomMenu = false
			if tap_target < 0 then
			    bottomMenu = true
			    if setSounds ~= 0 then
				Sound.play(click, NO_LOOP)
			    end
			    menuSel = -tap_target
			elseif tap_target > p then
			    p_plus(tap_target - p)
			elseif tap_target < p then
			    p_minus(p - tap_target)
			end
			break
		    end
		end
	    end
	    touchdown = 0
	    if showView == 5 and master_index > curTotal - 3 then
		if curTotal > 3 then
		    master_index = curTotal - 3
		else
		    master_index = 1
		end
	    end	
	    xstart = nil
	    ystart = nil
        end
    -- End Touch
    elseif showMenu > 0 then
        if (Controls.check(pad, CTRL_CANCEL) and not Controls.check(oldpad, CTRL_CANCEL))	 -- Used to be SCE_CTRL_CIRCLE
	 and not hasTyped then		 -- Only read controls while not typing.
	    if utilityMenu == true then
		close_utility_menu()
	    end
            status = System.getMessageState()
            if status ~= RUNNING then
		if spin_allowance > 0 then
		    OverrideCategory()
		    spin_allowance = 0
		end
		if showView > 4 and setSwitch == 0 then
		    showView = 0
		    master_index = p	 -- Makes it not act weird when leaving switch view.
		    bottomMenu = false	 -- Exit the switch view bottom menu...
		    menuSel = 1		 -- ... and reset your position in it.
		    -- Switch over to true placeholder icons when leaving SwitchView
		    for k, v in pairs(files_table) do	--Due to a quirk in LuaJIT, clearing the "All" table clears every table.
			if string.find(v.icon_path, "app0:/DATA/icon") then
			    FileLoad[v] = nil
			    Threads.remove(v)
			    v.icon_path = v.icon_path:gsub("app0:/DATA/icon", "app0:/DATA/missing_cover")
			    if v.ricon then
				Graphics.freeImage(v.ricon)
				v.ricon = nil
			    end
			end
		    end
		    if SwitchviewAssetsAreLoaded == true then
			SwitchviewAssetsAreLoaded = false
			Graphics.freeImage(imgCart)
			--Graphics.freeImage(imgAvatar)
			--Graphics.freeImage(imgCont)
			--Graphics.freeImage(img4Square)
			Graphics.freeImage(imgFloor2)
			Graphics.freeImage(btnMenu1)
			Graphics.freeImage(btnMenu2)
			Graphics.freeImage(btnMenu3)
			Graphics.freeImage(btnMenu4)
			Graphics.freeImage(btnMenu5)
			Graphics.freeImage(btnMenu6)
			Graphics.freeImage(btnMenuSel)
		    end
		    showView = 0
		end
                close_triangle_preview()
            end
        end
    end
    -- End Controls    
    check_for_out_of_bounds()
    
    -- Refreshing screen and oldpad
    Screen.waitVblankStart()
    Screen.flip()
    if hasTyped == false then			  -- Only read controls/touch while not typing
	oldpad = pad
	x1_old = x1 or nil			  -- Store old touch data in order for tapping to work.
	y1_old = y1 or nil
    end
    
    if oneLoopTimer then			  -- if the timer is running then...
        oneLoopTime = Timer.getTime(oneLoopTimer) -- save the time
        Timer.destroy(oneLoopTimer)		  -- not sure if this is necessary
	oneLoopTimer = nil			  -- clear timer value
    end 
end
