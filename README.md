# HexFlow-Launcher-Unofficial-Custom
<p>Releases page: https://github.com/BlackSheepBoy69/HexFlow-Launcher-Unofficial-Custom/releases</p>
<p>Revamp mod for VitaHEX's 3D coverflow style launcher for PS Vita.</p>
<p><img src="/Media/screen_09.jpg" width="900" title="screen-20"></p>
<p>Releases page: https://github.com/BlackSheepBoy69/HexFlow-Launcher-Unofficial-Custom/releases</p>
<p>Display and launch your games and homebrews in style.<br /><strong>HexFlow Launcher</strong> features a 3d user interface to display your games with their box art and supports many customization options like custom covers, backgrounds, and - in v0.6 and above - one custom category.</p>
<p>Launching a game/app from <strong>HexFlow Launcher</strong> will close the launcher automaticaly without asking.</p>
<p><strong>Now compatible with Adrenaline Launcher and Adrenaline Bubble Manager for launching PS1/PSP games either without bubbles, or with your custom bubbles!</strong></p>
<p>Enable RetroFlow mode to launch all your ROMS directly, if they are in the same folders that RetroFlow reads them from (The RetroFlow data folder's ROMS section). Great for people who already had the very popular 'RetroFlow' set up and want to try this app.</p>
<h2>Custom Covers</h2>
<p>Place your custom covers in "<em>ux0:/data/HexFlow/COVERS/PSVITA/</em>" and similar.</p>
<p>If RetroFlow is enabled, Retro covers can be found in "<em>ux0:/data/RetroFlow/COVERS/</em>"</p>
<p>Cover images must be in <strong>png</strong> format and the file name must match the <strong>App ID</strong> or the <strong>App Name</strong> of each app (recomended resolution 256x256px). <a href="https://live.staticflickr.com/7176/6885249717_738e8ee187_n.jpg" target="_blank" rel="noopener">Sample vita cover image</a></p>
<h3>Download Covers and Backgrounds</h3>
<p>In v0.3 and above, covers can be downloaded automatically from the settings menu (Start button). You can also download covers and backgrounds manually from the link below. Thanks to <b>astuermer</b> for creating <a href="https://github.com/andiweli/hexflow-covers">the original cover archive</a> used in v0.9.1 and below, and big thanks to <b>jimbob4000</b> for maintaining the current cover archive.</p>
<p><a href="https://github.com/jimbob4000/hexflow-covers/" target="_blank" rel="noopener">https://github.com/jimbob4000/hexflow-covers/</a></p>
<h3>Custom Background</h3>
<p>Place your <strong>Background.png</strong> or <strong>Background.jpg</strong> image in "<em>ux0:/data/HexFlow/</em>" (recomended resolution 1280x720px or less). Some custom backgrounds are available <a href="https://github.com/andiweli/hexflow-covers/tree/main/Backgrounds">HERE</a>. In v0.9 and above, these sample custom backgrounds are included by default.</p>
<p>If RetroFlow is enabled, special backgrounds for RetroFlow entries can be downloaded individually from the triangle menu and can be found in "<em>ux0:/data/RetroFlow/BACKGROUNDS/</em>"</p>
<h3>Custom Category</h3>
<p>In v0.6 and above, take the <strong>applist.dat</strong> file in "<em>ux0:data/HexFlow/</em>" and rename it to <strong>customsort.dat</strong>. This will generate a 5th category - "Custom" - and you can put what games you want or reorder it within Vitashell, or on your PC in a unix-compatible text editor such as gVim Easy. Windows notepad won't work. This can be used for real apps, for example, to create a "utilities" category, however it doesn't currently support RetroFlow entries and a fix for this is in bugtesting.</p>
<h3>Custom Music</h3>
<p>Place your  <strong>Music.ogg</strong> or <strong>Music.mp3</strong> file in "<em>ux0:data/HexFlow/</em>" (music will play automaticaly when the "Sounds" option is enabled)</p>
<p>&nbsp;</p>
<h2>AutoBoot</h2>
<p>If you want to auto-launch <strong>HexFlow Launcher Unofficial Custom</strong> every time your PS Vita boots up you can use the <a href="https://vitadb.rinnegatamante.it/#/info/261" target="_blank" rel="noopener"><strong>AutoBoot</strong></a> plugin by Rinnegatamante. It's also available on Autoplugin II, however some people recommend to not use autoplugin. Once it's installed and you restart your Vita, you can edit the file that should be there after restart: ux0:data/AutoBoot/boot.cfg</p>
<p>Inside, put the text "HXLC00001" without quotes</p>
<p>&nbsp;</p>
<p><img src="/Media/screen_01.jpg" width="800" title="screen-01"></p>
<h2>Controls</h2>
<p>Navigate your library using the <strong>DPad</strong> or the <strong>Left Stick</strong> or with the <strong>Touch Screen</strong>.</p>
<p><strong>R/L triggers</strong>: Skip 5 items</p>
<p><strong>Select+R/L triggers</strong>: Skip by alphabet</p>
<p><strong>Cross</strong>: Select/Launch game/app</p>
<p><strong>Square</strong>: Change Category</p>
<p><strong>Triangle</strong>: Game Details</p>
<p><strong>Circle</strong>: Change View/Cancel</p>
<p><strong>Start</strong>: Settings menu</p>
<p><strong>DPad Up/Down</strong>: Access SwitchView UI menu</p>
<p><strong>In v1.0 and above, DPad Up/Down can either be used to access SwitchView UI menu, or to change category if either of these options are enabled in the Settings menu</strong></p>
<p>&nbsp;</p>
<h3>IMPORTANT</h3>
<p><strong>Subfolders and psp categories plugin are not supported. Support for these is currently in bugtesting.</strong>.</p>
<h1>Downloads</h1>
<p>Grab the latest version from the releases page: https://github.com/BlackSheepBoy69/HexFlow-Launcher-Unofficial-Custom/releases
<p>&nbsp;</p>
<h1>Credits (Revamp Mod)</h1>
<p>Programming: <strong>BlackSheepBoy69</strong> (me) and one or more coders who wish to remain anonymous</p>
<h3>Special Thanks</h3>
<p>Code for "Return to Last Played Game": <b>fwannmacher</b> (v1.1 and above)</p>
<p><strong>jimbob4000</strong> (<a href="https://github.com/jimbob4000/hexflow-covers" target="_blank" rel="noopener">RetroFlow Covers database</a>) (v1.0 and above)</p>
<p>Inspiration + various help: <a href="https://github.com/jimbob4000/RetroFlow-Launcher/" target="_blank" rel="noopener">Team RetroFlow</a></p>
<p>Inspiration for adding smooth view in "Zoom-In" View/"Left-Side" View: Axce. He has coded for it to work in all views but I will fine tune it a little more before adding it to all the views.</p>
<p>You! Users who enjoy HexFlow Launcher, HexLauncher Custom, and Retroflow, who submit feature requests to this/those projects (which I do watch), and occasionally code. Thank you!</p>
<h1>Credits (General)</h1>
<p>Programming/UI: <strong>Sakis RG</strong></p>
<p>Developed with <a href="http://rinnegatamante.github.io/lpp-vita/" target="_blank" rel="noopener">Lua Player Plus</a> by <strong>Rinnegatamante</strong></p>
<h3>Special Thanks</h3>
<p><strong>Creckeryop</strong></p>
<h3>Translations</h3>
<p>French - @chronoss</p>
<p>German - @stuermerandreas</p>
<p>Spanish - @kodyna91</p>
<p>Italian - @TheheroGAC, @DaRk_ViVi</p>
<p>Russian - @_novff</p>
<p>Swedish - @Spoxnus86</p>
<p>Portuguese - @nighto (Retroflow)</p>
<p>Japanese - @iGlitch (Retroflow)</p>
<p>Polish - @SK00RUPA (Retroflow)</p>
<p>Google Translate was used for HexFlow Launcher Unofficial Custom translations that weren't found on HexFlow Launcher and Retroflow.</p>
<p>&nbsp;</p>
<h2>Support</h2>
<p>If you want to support the original creator of HexFlow Launcher (not this revamp mod), you can join <a href="https://www.patreon.com/vitahex">his Patreon</a>.</p>
<p>or send to his <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&amp;hosted_button_id=RM8ECMVYMTXGJ&amp;source=url">PayPal link.</a></p>
<p><a href="https://twitter.com/VitaHex">Official VitaHEX Twitter</a></p>
<p><a href="https://vitahex.weebly.com/">Official VitaHEX Website</a></p>
<p><a href="https://github.com/VitaHEX-Games/HexFlow-Launcher">Official VitaHEX HexFlow Launcher Github (abandoned?)</a></p>
<p><a href="https://github.com/BlackSheepBoy69/HexFlow-Launcher-Unofficial-Custom/releases">HexFlow Launcher Unofficial Custom download page</a></p>
<h2>User Feature Requests</h2>
<p>Feature requests and "issues" posted on Retroflow & HexFlow Launcher are considered for being added to this list. Mostly no feature is impossible because there are experienced coders involved in the HexLauncher Custom project, but this entire project is just for me (only posted publicly out of the "generousity of my heart") so only features that I like will get added.</p>
<p>If you'd like to try coding up a feature (which may be faster than having me do it), then take your editted sourcecode and name it to "index.lua" and put it in like this: ux0:/app/HXLC00001/index.lua</p>
<p>...Or put it directly into the vpk (openable with Winrar) to replace the index.lua there.</p>
<p>The great feature of lua files is they can open in a simple text editor such as Notepad, and you don't need VitaSDK.</p>
<p>If your version works out, send it here as a github "pull request" and I'll see about adding your feature to this project so it can stay as the app updates. Otherwise you'll basicly have to wait for next release and hope I added a feature you want.<p>
