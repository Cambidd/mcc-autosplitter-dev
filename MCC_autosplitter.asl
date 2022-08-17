//Halo: The Master Chief Collection Autosplitter
//by Burnt and Cambid


//TODO;
/*
	H4 deathcounter?
	H4 IL splits - Probably not unless someone wants to supply the needed information re bspstate values.

	***NOTE*****
	Replaced H3, H4, HR and ODST IGT uint watchers with a global float watcher representing the game time.
	The IGT tickcounters for HR and H4 are unstable resulting in errors with the game time calc. The float
	value is stable and accurate so a better option for these 4 games to cut down on offsets to update.
	Doesn't work well in H2 though. Just keep and eye out for anything weird happening though.
*/

state("MCC-Win64-Shipping") {}
state("MCC-Win64-Shipping-WinStore") {} 
state("MCCWinStore-Win64-Shipping") {} //what the fuck 343?!


init //hooking to game to make memorywatchers
{
	
	//need to clear pause flags incase of restart/crash
	vars.loading = false;

	if (settings["perfmode"]) {refreshRate = 30;} else {refreshRate = 60;}	//Set autosplitter refresh rate. Probably doesn't help much. Whatever


	var message = "It looks like MCC has received a new patch that will "+
	"probably break me (the autosplitter). \n"+
	"Autosplitter was made for version: "+ "1.2904.0.0" + "\n" + 
	"Current detected version: "+ modules.First().FileVersionInfo.FileVersion + "\n" +
	"If I'm broken, you'll just have to wait for Burnt to update me. "+
	"You won't need to do anything except restart Livesplit once I'm updated.";
	
	//so the latest version of winstore (as of v2904), has a fun issue where you can't get the FileVersion from the module like you normally can
	//so this backup code will check for that failure and attempt to get it from the filepath
	
	//first check for the failure
	string testversion = modules.First().FileVersionInfo.FileVersion; 
	var winstorefileversioncheck = (testversion == null && (modules.First().ToString() == "MCCWinStore-Win64-Shipping.exe" || modules.First().ToString() == "MCC-Win64-Shipping-WinStore.exe"));
	if (winstorefileversioncheck) 
	{
		print ("dear god why");
		print (modules.First().FileName.ToString());
		var test = modules.First().FileName.ToString(); //get the filepath of the winstore exe
		var test2 = test.IndexOf("Chelan"); //check where the index of the word "Chelan" is in the filepath 
		if (test2 != -1) //-1 if it didn't find "Chelan"
		{
			var test3 = test.Substring(test2 + 7, 10); //move to the right of the filepath to get the version number
			print (test3);
			
			if (test3.Substring(1, 1) == ".") //sanity check
			testversion = test3;
		}
		
		if (testversion == null) //if our code didn't find the version, modify the error message to display below
		{
			message = "An issue with newer releases of WinStore MCC " + "\n" +
			"has broken some of my version checking code." + "\n" +
			"For now I'll assume you're on the latest patch and try to work anyway.";
		}
	}
	
	
	//version check and warning message for invalid version  
	switch(testversion)
	{
		case "1.2448.0.0":
		version = "1.2448.0.0";
		break;
		
		case "1.2645.0.0":
		version = "1.2645.0.0";
		break;
		
		case "1.2904.0.0":
		version = "1.2904.0.0";
		break;
		
		default: 
		version = "1.2904.0.0";
		if (vars.brokenupdateshowed == false)
		{
			vars.brokenupdateshowed = true;
			var brokenupdateMessage = MessageBox.Show(message,
				vars.aslName+" | LiveSplit",
				MessageBoxButtons.OK 
			);
		}
		break;
	}
	
	//STATE init
	// STEAM !!!!!!!!!!!!!!!!!!!! 
	if (modules.First().ToString() == "MCC-Win64-Shipping.exe")
	{
		if (version == "1.2904.0.0")
		{
			vars.watchers_fast = new MemoryWatcherList() {
				(vars.menuindicator = new MemoryWatcher<byte>(new DeepPointer(0x3E45529)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}), //behaviour changed to 07 and 0B, instead of 07 and 0C
				(vars.stateindicator = new MemoryWatcher<byte>(new DeepPointer(0x3F2FBC9)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_slow = new MemoryWatcherList() {
				(vars.gameindicator = new MemoryWatcher<byte>(new DeepPointer(0x03F7C380, 0x0)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) //scan for 8B 4B 18 ** ** ** ** **    48 8B 5C 24 30  89 07 nonwriteable, check what 89 07 writes to
			};

			vars.watchers_igt = new MemoryWatcherList() {
				(vars.IGT_float = new MemoryWatcher<float>(new DeepPointer(0x3F7C33C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h1 = new MemoryWatcherList() {
				(vars.H1_levelname = new StringWatcher(new DeepPointer(0x03F7BA50, 0x8, 0x2B611EC), 3)),
				(vars.H1_tickcounter = new MemoryWatcher<uint>(new DeepPointer(0x03F7BA50, 0x8, 0x2B88764)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_IGT = new MemoryWatcher<uint>(new DeepPointer(0x03F7BA50, 0x8, 0x2E7A354)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_bspstate = new MemoryWatcher<byte>(new DeepPointer(0x03F7BA50, 0x8, 0x1B661CC)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_cinematic = new MemoryWatcher<bool>(new DeepPointer(0x03F7BA50, 0x8, 0x02E773D8, 0x0A)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_cutsceneskip = new MemoryWatcher<bool>(new DeepPointer(0x03F7BA50, 0x8, 0x02E773D8, 0x0B)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h1xy = new MemoryWatcherList() {
				(vars.H1_xpos = new MemoryWatcher<float>(new DeepPointer(0x03F7BA50, 0x8, 0x2D7313C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_ypos = new MemoryWatcher<float>(new DeepPointer(0x03F7BA50, 0x8, 0x2D73140)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h1death = new MemoryWatcherList(){
				(vars.H1_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03F7BA50, 0x8, 0x2B611B7)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			//scan for 00 00 80 3F 00 00 80 3F 00 00 80 3F 02 00 00 00 FF FF 00 during cryo cs. Last 7 values are these, in order.
			vars.watchers_h1fade = new MemoryWatcherList(){
				(vars.H1_fadetick = new MemoryWatcher<uint>(new DeepPointer(0x03F7BA50, 0x8, 0x2E7F868, 0x3C0)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),	
				(vars.H1_fadelength = new MemoryWatcher<ushort>(new DeepPointer(0x03F7BA50, 0x8, 0x2E7F868, 0x3C4)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_fadebyte = new MemoryWatcher<byte>(new DeepPointer(0x03F7BA50, 0x8, 0x2E7F868, 0x3C6)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h2 = new MemoryWatcherList() {
				(vars.H2_levelname = new StringWatcher(new DeepPointer(0x03F7BA50, 0x28, 0xD4ABF8), 3)),
				(vars.H2_tickcounter = new MemoryWatcher<uint>(new DeepPointer(0x03F7BA50, 0x28, 0x14BDBC4)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_IGT = new MemoryWatcher<uint>(new DeepPointer(0x03F7BA50, 0x28, 0x147D9F0)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_fadebyte = new MemoryWatcher<byte>(new DeepPointer(0x03F7BA50, 0x28, 0x01520498, -0x92E)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_letterbox = new MemoryWatcher<float>(new DeepPointer(0x03F7BA50, 0x28, 0x01520498, -0x938)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_graphics = new MemoryWatcher<byte>(new DeepPointer(0x03F7BA50, 0x28, 0xCCF280)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) //scan for FF FF FF FF 2A 0A 00 0D on outskirts. Should be around here somewhere
			};
			
			vars.watchers_h2bsp = new MemoryWatcherList() {
				(vars.H2_bspstate = new MemoryWatcher<byte>(new DeepPointer(0x03F7BA50, 0x28, 0xCACD74)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h2xy = new MemoryWatcherList() {
				(vars.H2_xpos = new MemoryWatcher<float>(new DeepPointer(0x03F7BA50, 0x28, 0xD5A148)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_ypos = new MemoryWatcher<float>(new DeepPointer(0x03F7BA50, 0x28, 0xD5A14C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h2death = new MemoryWatcherList(){
				(vars.H2_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03F7BA50, 0x28, 0x00D5A5A0, -0xEF)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h3 = new MemoryWatcherList() {
				(vars.H3_levelname = new StringWatcher(new DeepPointer(0x03F7BA50, 0x48, 0x1E092E8), 3)), 
				(vars.H3_theatertime = new MemoryWatcher<uint>(new DeepPointer(0x03F7BA50, 0x48, 0x1EF61E8)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			vars.watchers_h3bsp = new MemoryWatcherList() {
				(vars.H3_bspstate = new MemoryWatcher<ulong>(new DeepPointer(0x03F7BA50, 0x48, 0x99FCA0, 0x2C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			vars.watchers_h3death = new MemoryWatcherList(){
				(vars.H3_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03F7BA50, 0x48, 0x1D8DF48, 0x1073D)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_hr = new MemoryWatcherList() {
				(vars.HR_levelname = new StringWatcher(new DeepPointer(0x03F7BA50, 0xC8, 0x290BDA7), 3)),
			};
			
			vars.watchers_hrbsp = new MemoryWatcherList() {
				(vars.HR_bspstate = new MemoryWatcher<uint>(new DeepPointer(0x03F7BA50, 0xC8, 0x3719E24)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_hrdeath = new MemoryWatcherList(){
				(vars.HR_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03F7BA50, 0xC8, 0x23CC7D8, 0x1F419)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_odst = new MemoryWatcherList() {
				(vars.ODST_levelnameBad = new StringWatcher(new DeepPointer(0x03F7BA50, 0xA8, 0xABD8E1), 4)),
				(vars.ODST_levelnameBad2 = new StringWatcher(new DeepPointer(0x03F7BA50, 0xA8, 0x20872f5), 4))
			};
			
			vars.watchers_odstbsp = new MemoryWatcherList() {
				(vars.ODST_bspstate = new MemoryWatcher<ulong>(new DeepPointer(0x03F7BA50, 0xA8, 0x2F9FD5C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			vars.watchers_odstdeath = new MemoryWatcherList(){
				(vars.ODST_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03F7BA50, 0xA8, 0x00F3EB8C, -0x913)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h4 = new MemoryWatcherList() {
				(vars.H4_levelname = new StringWatcher(new DeepPointer(0x03F7BA50, 0x68, 0x29A3743), 3))
			};
			
			vars.watchers_h4bsp = new MemoryWatcherList() {
				(vars.H4_bspstate = new MemoryWatcher<ulong>(new DeepPointer(0x03F7BA50, 0x68, 0x25DC188)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};




		}
		else if (version == "1.2645.0.0")
		{
			vars.watchers_fast = new MemoryWatcherList() {
				(vars.menuindicator = new MemoryWatcher<byte>(new DeepPointer(0x3A4A7C9)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}), //behaviour changed to 07 and 0B, instead of 07 and 0C
				(vars.stateindicator = new MemoryWatcher<byte>(new DeepPointer(0x3b40d69)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_slow = new MemoryWatcherList() {
				(vars.gameindicator = new MemoryWatcher<byte>(new DeepPointer(0x03B81270, 0x0)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}), //scan for 8B 4B 18 ** ** ** ** **    48 8B 5C 24 30  89 07 nonwriteable, check what 89 07 writes to
			};

			vars.watchers_igt = new MemoryWatcherList() {
				(vars.IGT_float = new MemoryWatcher<float>(new DeepPointer(0x3B80FF8)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h1 = new MemoryWatcherList() {
				(vars.H1_levelname = new StringWatcher(new DeepPointer(0x03B80E98, 0x8, 0x2AF8288), 3)),
				(vars.H1_tickcounter = new MemoryWatcher<uint>(new DeepPointer(0x03B80E98, 0x8, 0x2B5FC04)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_IGT = new MemoryWatcher<uint>(new DeepPointer(0x03B80E98, 0x8, 0x2AFB954)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_bspstate = new MemoryWatcher<byte>(new DeepPointer(0x03B80E98, 0x8, 0x19F748C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_cinematic = new MemoryWatcher<bool>(new DeepPointer(0x03B80E98, 0x8, 0x2af89b8, 0x0A)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_cutsceneskip = new MemoryWatcher<bool>(new DeepPointer(0x03B80E98, 0x8, 0x2af89b8, 0x0B)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h1xy = new MemoryWatcherList() {
				(vars.H1_xpos = new MemoryWatcher<float>(new DeepPointer(0x03B80E98, 0x8, 0x2A5EFF4)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_ypos = new MemoryWatcher<float>(new DeepPointer(0x03B80E98, 0x8, 0x2A5EFF8)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h1death = new MemoryWatcherList(){
				(vars.H1_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03B80E98, 0x8, 0x2AF8257)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
			};

			//scan for 00 00 80 3F 00 00 80 3F 00 00 80 3F 02 00 00 00 FF FF 00 during cryo cs. Last 7 values are these, in order.
			vars.watchers_h1fade = new MemoryWatcherList(){
				(vars.H1_fadetick = new MemoryWatcher<uint>(new DeepPointer(0x03B80E98, 0x8, 0x2B88E58, 0x3C0)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),	
				(vars.H1_fadelength = new MemoryWatcher<ushort>(new DeepPointer(0x03B80E98, 0x8, 0x2B88E58, 0x3C4)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_fadebyte = new MemoryWatcher<byte>(new DeepPointer(0x03B80E98, 0x8, 0x2B88E58, 0x3C6)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h2 = new MemoryWatcherList() {
				(vars.H2_levelname = new StringWatcher(new DeepPointer(0x03B80E98, 0x28, 0xD42E68), 3)),
				(vars.H2_tickcounter = new MemoryWatcher<uint>(new DeepPointer(0x03B80E98, 0x28, 0x14B5DE4)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_IGT = new MemoryWatcher<uint>(new DeepPointer(0x03B80E98, 0x28, 0x1475C10)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_fadebyte = new MemoryWatcher<byte>(new DeepPointer(0x03B80E98, 0x28, 0x015186A0, -0x92E)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_letterbox = new MemoryWatcher<float>(new DeepPointer(0x03B80E98, 0x28, 0x015186A0, -0x938)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_graphics = new MemoryWatcher<byte>(new DeepPointer(0x03B80E98, 0x28, 0xCC74A8)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) //scan for FF FF FF FF 2A 0A 00 0D on outskirts. Should be around here somewhere
			};
			
			vars.watchers_h2bsp = new MemoryWatcherList() {
				(vars.H2_bspstate = new MemoryWatcher<byte>(new DeepPointer(0x03B80E98, 0x28, 0xCA4D74)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h2xy = new MemoryWatcherList() {
				(vars.H2_xpos = new MemoryWatcher<float>(new DeepPointer(0x03B80E98, 0x28, 0xD523A8)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_ypos = new MemoryWatcher<float>(new DeepPointer(0x03B80E98, 0x28, 0xD523AC)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h2death = new MemoryWatcherList(){
				(vars.H2_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03B80E98, 0x28, 0x00D52800, -0xEF)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
			};
			
			vars.watchers_h3 = new MemoryWatcherList() {
				(vars.H3_levelname = new StringWatcher(new DeepPointer(0x03B80E98, 0x48, 0x1e0d358), 3)), 
				(vars.H3_theatertime = new MemoryWatcher<uint>(new DeepPointer(0x03B80E98, 0x48, 0x1F34A68)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			vars.watchers_h3bsp = new MemoryWatcherList() {
				(vars.H3_bspstate = new MemoryWatcher<ulong>(new DeepPointer(0x03B80E98, 0x48, 0x009A4Ba0, 0x2C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			vars.watchers_h3death = new MemoryWatcherList(){
				(vars.H3_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03B80E98, 0x48, 0x1D91E68, 0x1077D)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_hr = new MemoryWatcherList() {
				(vars.HR_levelname = new StringWatcher(new DeepPointer(0x03B80E98, 0xC8, 0x2907107), 3))
			};
			
			vars.watchers_hrbsp = new MemoryWatcherList() {
				(vars.HR_bspstate = new MemoryWatcher<uint>(new DeepPointer(0x03B80E98, 0xC8, 0x3716270)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_hrdeath = new MemoryWatcherList(){
				(vars.HR_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03B80E98, 0xC8, 0x00EEF330, 0x594249)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_odst = new MemoryWatcherList() {
				(vars.ODST_levelnameBad = new StringWatcher(new DeepPointer(0x03B80E98, 0xA8, 0xAAF371), 4)),
				(vars.ODST_levelnameBad2 = new StringWatcher(new DeepPointer(0x03B80E98, 0xA8, 0x2079d85), 4))
			};
			
			vars.watchers_odstbsp = new MemoryWatcherList() {
				(vars.ODST_bspstate = new MemoryWatcher<ulong>(new DeepPointer(0x03B80E98, 0xA8, 0x2F91A98)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			vars.watchers_odstdeath = new MemoryWatcherList(){
				(vars.ODST_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03B80E98, 0xA8, 0x00F3020c, -0x913)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h4 = new MemoryWatcherList() {
				(vars.H4_levelname = new StringWatcher(new DeepPointer(0x03B80E98, 0x68, 0x2836433), 3))
			};
			
			vars.watchers_h4bsp = new MemoryWatcherList() {
				(vars.H4_bspstate = new MemoryWatcher<ulong>(new DeepPointer(0x03B80E98, 0x68, 0x2472A88)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			


		}
		else if (version == "1.2448.0.0")
		{
			vars.watchers_fast = new MemoryWatcherList() {
				(vars.menuindicator = new MemoryWatcher<byte>(new DeepPointer(0x38EF0A9)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}), //behaviour changed to 07 and 0B, instead of 07 and 0C
				(vars.stateindicator = new MemoryWatcher<byte>(new DeepPointer(0x39E4DE9)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			
			vars.watchers_slow = new MemoryWatcherList() {
				(vars.gameindicator = new MemoryWatcher<byte>(new DeepPointer(0x3A253A0, 0x0)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) //scan for 8B 4B 18 ** ** ** ** **    48 8B 5C 24 30  89 07 nonwriteable, check what 89 07 writes to
			};

			vars.watchers_igt = new MemoryWatcherList() {
				(vars.IGT_float = new MemoryWatcher<float>(new DeepPointer(0x3A25188)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h1 = new MemoryWatcherList() {
				(vars.H1_levelname = new StringWatcher(new DeepPointer(0x3A24FF8, 0x8, 0x2AF111C), 3)),
				(vars.H1_tickcounter = new MemoryWatcher<uint>(new DeepPointer(0x3A24FF8, 0x8, 0x2B58A24)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_IGT = new MemoryWatcher<uint>(new DeepPointer(0x3A24FF8, 0x8, 0x2AF477C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_bspstate = new MemoryWatcher<byte>(new DeepPointer(0x3A24FF8, 0x8, 0x19F0400)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_cinematic = new MemoryWatcher<bool>(new DeepPointer(0x3A24FF8, 0x8, 0x2AF1868, 0x0A)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_cutsceneskip = new MemoryWatcher<bool>(new DeepPointer(0x3A24FF8, 0x8, 0x2AF1868, 0x0B)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h1xy = new MemoryWatcherList() {
				(vars.H1_xpos = new MemoryWatcher<float>(new DeepPointer(0x3A24FF8, 0x8, 0x2A57E74)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_ypos = new MemoryWatcher<float>(new DeepPointer(0x3A24FF8, 0x8, 0x2A57E78)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h1death = new MemoryWatcherList(){
				(vars.H1_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x3A24FF8, 0x8, 0x2AF10E7)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
			};

			//scan for 00 00 80 3F 00 00 80 3F 00 00 80 3F 02 00 00 00 FF FF 00 during cryo cs. Last 7 values are these, in order.
			vars.watchers_h1fade = new MemoryWatcherList(){
				(vars.H1_fadetick = new MemoryWatcher<uint>(new DeepPointer(0x3A24FF8, 0x8, 0x2B81CE8, 0x3C0)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),	
				(vars.H1_fadelength = new MemoryWatcher<ushort>(new DeepPointer(0x3A24FF8, 0x8, 0x2B81CE8, 0x3C4)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_fadebyte = new MemoryWatcher<byte>(new DeepPointer(0x3A24FF8, 0x8, 0x2B81CE8, 0x3C6)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h2 = new MemoryWatcherList() {
				(vars.H2_levelname = new StringWatcher(new DeepPointer(0x3A24FF8, 0x28, 0xE63FB3), 3)),
				(vars.H2_tickcounter = new MemoryWatcher<uint>(new DeepPointer(0x3A24FF8, 0x28, 0xE63144)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_IGT = new MemoryWatcher<uint>(new DeepPointer(0x3A24FF8, 0x28, 0xE22F40)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_fadebyte = new MemoryWatcher<byte>(new DeepPointer(0x3A24FF8, 0x28, 0x0143ACA0, -0x92E)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_letterbox = new MemoryWatcher<float>(new DeepPointer(0x3A24FF8, 0x28, 0x0143ACA0, -0x938)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_graphics = new MemoryWatcher<byte>(new DeepPointer(0x3A24FF8, 0x28, 0xCFB918)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) //scan for FF FF FF FF 2A 0A 00 0D on outskirts. Should be around here somewhere
			};
			
			vars.watchers_h2bsp = new MemoryWatcherList() {
				(vars.H2_bspstate = new MemoryWatcher<byte>(new DeepPointer(0x3A24FF8, 0x28, 0xCD7D74)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h2xy = new MemoryWatcherList() {
				(vars.H2_xpos = new MemoryWatcher<float>(new DeepPointer(0x3A24FF8, 0x28, 0xDA5CD8)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_ypos = new MemoryWatcher<float>(new DeepPointer(0x3A24FF8, 0x28, 0xDA5CDC)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h2death = new MemoryWatcherList(){
				(vars.H2_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x3A24FF8, 0x28, 0x00DA6140, -0xEF)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h3 = new MemoryWatcherList() {
				(vars.H3_levelname = new StringWatcher(new DeepPointer(0x3A24FF8, 0x48, 0x1D2C460), 3)), 
				(vars.H3_theatertime = new MemoryWatcher<uint>(new DeepPointer(0x3A24FF8, 0x48, 0x1E36118)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			vars.watchers_h3bsp = new MemoryWatcherList() {
				(vars.H3_bspstate = new MemoryWatcher<ulong>(new DeepPointer(0x3A24FF8, 0x48, 0x009F3EF0, 0x2C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			vars.watchers_h3death = new MemoryWatcherList(){
				(vars.H3_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x3A24FF8, 0x48, 0x1CB15C8, 0x1051D)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_hr = new MemoryWatcherList() {
				(vars.HR_levelname = new StringWatcher(new DeepPointer(0x3A24FF8, 0xC8, 0x2868777), 3))
			};
			
			vars.watchers_hrbsp = new MemoryWatcherList() {
				(vars.HR_bspstate = new MemoryWatcher<uint>(new DeepPointer(0x3A24FF8, 0xC8, 0x36778E0)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_hrdeath = new MemoryWatcherList(){
				(vars.HR_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x3A24FF8, 0xC8, 0x00EEFEB0, 0x544249)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_odst = new MemoryWatcherList() {
				(vars.ODST_levelnameBad = new StringWatcher(new DeepPointer(0x3A24FF8, 0xA8, 0xA84483), 4)),
				(vars.ODST_levelnameBad2 = new StringWatcher(new DeepPointer(0x3A24FF8, 0xA8, 0x1D25187), 4))
			};
			
			vars.watchers_odstbsp = new MemoryWatcherList() {
				(vars.ODST_bspstate = new MemoryWatcher<ulong>(new DeepPointer(0x3A24FF8, 0xA8, 0x2E46960)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			
			vars.watchers_odstdeath = new MemoryWatcherList(){
				(vars.ODST_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x3A24FF8, 0xA8, 0x00E8520C, -0x913)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h4 = new MemoryWatcherList() {
				(vars.H4_levelname = new StringWatcher(new DeepPointer(0x3A24FF8, 0x68, 0x276ACA3), 3))
			};
			
			vars.watchers_h4bsp = new MemoryWatcherList() {
				(vars.H4_bspstate = new MemoryWatcher<ulong>(new DeepPointer(0x3A24FF8, 0x68, 0x2441AB8, -0x560)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
		}
		
		

	}
	// WINSTORE !!!!!!!!!!!!!!!!!!!!
	else if (modules.First().ToString() == "MCC-Win64-Shipping-WinStore.exe" || modules.First().ToString() == "MCCWinStore-Win64-Shipping.exe")
	{
		if (version == "1.2904.0.0")
		{
			vars.watchers_fast = new MemoryWatcherList() {
				(vars.menuindicator = new MemoryWatcher<byte>(new DeepPointer(0x3CE9329)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}), //behaviour changed to 07 and 0B, instead of 07 and 0C
				(vars.stateindicator = new MemoryWatcher<byte>(new DeepPointer(0x3DD36E9)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};

			vars.watchers_slow = new MemoryWatcherList() {
				(vars.gameindicator = new MemoryWatcher<byte>(new DeepPointer(0x03E1FE60, 0x0)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) //scan for 8B 4B 18 ** ** ** ** **    48 8B 5C 24 30  89 07 nonwriteable, check what 89 07 writes to
			};

			vars.watchers_igt = new MemoryWatcherList() {
				(vars.IGT_float = new MemoryWatcher<float>(new DeepPointer(0x3E1FE1C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h1 = new MemoryWatcherList() {
				(vars.H1_levelname = new StringWatcher(new DeepPointer(0x03E1F540, 0x8, 0x2B611EC), 3)),
				(vars.H1_tickcounter = new MemoryWatcher<uint>(new DeepPointer(0x03E1F540, 0x8, 0x2B88764)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_IGT = new MemoryWatcher<uint>(new DeepPointer(0x03E1F540, 0x8, 0x2E7A354)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_bspstate = new MemoryWatcher<byte>(new DeepPointer(0x03E1F540, 0x8, 0x1B661CC)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_cinematic = new MemoryWatcher<bool>(new DeepPointer(0x03E1F540, 0x8, 0x02E773D8, 0x0A)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_cutsceneskip = new MemoryWatcher<bool>(new DeepPointer(0x03E1F540, 0x8, 0x02E773D8, 0x0B)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h1xy = new MemoryWatcherList() {
				(vars.H1_xpos = new MemoryWatcher<float>(new DeepPointer(0x03E1F540, 0x8, 0x2D7313C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_ypos = new MemoryWatcher<float>(new DeepPointer(0x03E1F540, 0x8, 0x2D73140)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h1death = new MemoryWatcherList(){
				(vars.H1_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03E1F540, 0x8, 0x2B611B7)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			//scan for 00 00 80 3F 00 00 80 3F 00 00 80 3F 02 00 00 00 FF FF 00 during cryo cs. Last 7 values are these, in order.
			vars.watchers_h1fade = new MemoryWatcherList(){
				(vars.H1_fadetick = new MemoryWatcher<uint>(new DeepPointer(0x03E1F540, 0x8, 0x2E7F868, 0x3C0)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),	
				(vars.H1_fadelength = new MemoryWatcher<ushort>(new DeepPointer(0x03E1F540, 0x8, 0x2E7F868, 0x3C4)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H1_fadebyte = new MemoryWatcher<byte>(new DeepPointer(0x03E1F540, 0x8, 0x2E7F868, 0x3C6)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h2 = new MemoryWatcherList() {
				(vars.H2_levelname = new StringWatcher(new DeepPointer(0x03E1F540, 0x28, 0xD4ABF8), 3)),
				(vars.H2_tickcounter = new MemoryWatcher<uint>(new DeepPointer(0x03E1F540, 0x28, 0x14BDBC4)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_IGT = new MemoryWatcher<uint>(new DeepPointer(0x03E1F540, 0x28, 0x147D9F0)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_fadebyte = new MemoryWatcher<byte>(new DeepPointer(0x03E1F540, 0x28, 0x01520498, -0x92E)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_letterbox = new MemoryWatcher<float>(new DeepPointer(0x03E1F540, 0x28, 0x01520498, -0x938)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_graphics = new MemoryWatcher<byte>(new DeepPointer(0x03E1F540, 0x28, 0xCCF280)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) //scan for FF FF FF FF 2A 0A 00 0D on outskirts. Should be around here somewhere
			};
			
			vars.watchers_h2bsp = new MemoryWatcherList() {
				(vars.H2_bspstate = new MemoryWatcher<byte>(new DeepPointer(0x03E1F540, 0x28, 0xCACD74)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h2xy = new MemoryWatcherList() {
				(vars.H2_xpos = new MemoryWatcher<float>(new DeepPointer(0x03E1F540, 0x28, 0xD5A148)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}),
				(vars.H2_ypos = new MemoryWatcher<float>(new DeepPointer(0x03E1F540, 0x28, 0xD5A14C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};

			vars.watchers_h2death = new MemoryWatcherList(){
				(vars.H2_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03E1F540, 0x28, 0x00D5A5A0, -0xEF)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h3 = new MemoryWatcherList() {
				(vars.H3_levelname = new StringWatcher(new DeepPointer(0x03E1F540, 0x48, 0x1E092E8), 3)), 
				(vars.H3_theatertime = new MemoryWatcher<uint>(new DeepPointer(0x03E1F540, 0x48, 0x1EF61E8)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			vars.watchers_h3bsp = new MemoryWatcherList() {
				(vars.H3_bspstate = new MemoryWatcher<ulong>(new DeepPointer(0x03E1F540, 0x48, 0x99FCA0, 0x2C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			vars.watchers_h3death = new MemoryWatcherList(){
				(vars.H3_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03E1F540, 0x48, 0x1D8DF48, 0x1073D)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_hr = new MemoryWatcherList() {
				(vars.HR_levelname = new StringWatcher(new DeepPointer(0x03E1F540, 0xC8, 0x290BDA7), 3))
			};
			
			vars.watchers_hrbsp = new MemoryWatcherList() {
				(vars.HR_bspstate = new MemoryWatcher<uint>(new DeepPointer(0x03E1F540, 0xC8, 0x3719E24)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_hrdeath = new MemoryWatcherList(){
				(vars.HR_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03E1F540, 0xC8, 0x00EEF330, 0xEF2010)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_odst = new MemoryWatcherList() {
				(vars.ODST_levelnameBad = new StringWatcher(new DeepPointer(0x03F7BA50, 0xA8, 0xABD8E1), 4)),
				(vars.ODST_levelnameBad2 = new StringWatcher(new DeepPointer(0x03E1F540, 0xA8, 0x20872f5), 4))
			};
			
			vars.watchers_odstbsp = new MemoryWatcherList() {
				(vars.ODST_bspstate = new MemoryWatcher<ulong>(new DeepPointer(0x03E1F540, 0xA8, 0x2F9FD5C)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
			
			vars.watchers_odstdeath = new MemoryWatcherList(){
				(vars.ODST_deathflag = new MemoryWatcher<bool>(new DeepPointer(0x03E1F540, 0xA8, 0x00F3EB8C, -0x913)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull})
			};
			
			vars.watchers_h4 = new MemoryWatcherList() {
				(vars.H4_levelname = new StringWatcher(new DeepPointer(0x03E1F540, 0x68, 0x29A3743), 3))
			};
			
			vars.watchers_h4bsp = new MemoryWatcherList() {
				(vars.H4_bspstate = new MemoryWatcher<ulong>(new DeepPointer(0x03E1F540, 0x68, 0x25DC188)) { FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull}) 
			};
	
		}
	}
}


startup //variable init and settings
{ 	
	//MOVED VARIABLE INIT TO STARTUP TO PREVENT BUGS WHEN RESTARTING (OR CRASHING) MCC MID RUN
	
	//GENERAL inits
	vars.loopcount = 0;
	vars.dirtybsps_byte = new List<byte>();
	vars.dirtybsps_int = new List<uint>();
	vars.dirtybsps_long = new List<ulong>();
	vars.startedlevel = "000";
	vars.levelloaded = "000";
	vars.startedgame = 10;
	vars.varsreset = false;
	vars.partialreset = false;
	vars.loopsplit = true;
	vars.forcesplit = false;
	vars.forcesplit2 = false;

	vars.brokenupdateshowed = false;
	vars.multigamepause = false;
	vars.multigametime = TimeSpan.Zero;
	vars.H2_tgjreadyflag = false;
	vars.H2_tgjreadytime = 0;
	vars.loading = false;

	//IGT
	vars.gametime = TimeSpan.Zero;
	vars.ingametime = 0;
	vars.leveltime = 0;
	vars.pgcrexists = false;

	//HALO 1
	vars.splitbsp_a10 = new byte[6] { 1, 2, 3, 4, 5, 6 };
	vars.splitbsp_a30 = new byte[1] { 1 };
	vars.splitbsp_a50 = new byte[3] { 1, 2, 3 };
	vars.splitbsp_b30 = new byte[1] { 1 };
	vars.splitbsp_b40 = new byte[4] { 0, 1, 10, 2};
	vars.splitbsp_c10 = new byte[4] { 1, 3, 4, 5};
	vars.splitbsp_c20 = new byte[3] { 1, 2, 3};
	vars.splitbsp_c40 = new byte[8] { 12, 10, 1, 9, 8, 6, 0, 5 };
	vars.splitbsp_d20 = new byte[3] { 4, 3, 2 };
	vars.splitbsp_d40 = new byte[7] { 1, 2, 3, 4, 5, 6, 7 };
	
	//HALO 2
	vars.splitbsp_01b = new byte[3] { 2, 0, 3 }; //cairo
	vars.splitbsp_03a = new byte[2] { 1, 2 }; //os
	vars.splitbsp_03b = new byte[1] { 1 }; //metro
	vars.splitbsp_04a = new byte[2] { 3, 0 }; //arby - 2, 0, 4, and 1 are using in cs 
	vars.splitbsp_04b = new byte[4] { 0, 2, 1, 5 }; //here - 0 in cs, 3 at start, returns to 0 later gah - maybe skip the 4 split cos it's just for like 10s when cables cut
	vars.splitbsp_05a = new byte[1] { 1 }; //dh - flahses between 2 and 0 in cs
	vars.splitbsp_05b = new byte[2] { 1, 2 }; //reg - 0 in cs. skipping 3 & 4 since it's autoscroller
	vars.splitbsp_06a = new byte[2] { 1, 2 }; //si - 0 then 3 in cs, starts on 0
	vars.splitbsp_06b = new byte[3] { 1, 2, 3 }; //qz- there are more besides this but all during autoscroller
	vars.splitbsp_07a = new byte[5] { 1, 2, 3, 4, 5 }; //gm - 7 & 0 in cs
	vars.splitbsp_08a = new byte[2] { 1, 0 }; //up -- hits 0 again after 1. ignoring skipable
	vars.splitbsp_07b = new byte[3] { 1, 2, 4 }; //HC -- none if doing HC skip
	vars.splitbsp_08b = new byte[3] { 0, 1, 3 }; //TGJ -- starts 0 and in cs, then goes to 1, then 0, then 1, then 0, then 3 (skipping 2 cos it's skippable)
	//so tgjs actual count is 5
	
	vars.lastinternal = false;
	vars.oldtick = -2;
	
	
	//HALO 3
	vars.splitbsp_010 = new ulong[8] { 7, 4111, 4127, 8589938751, 12884907135, 4294972543, 4294972927, 6143}; //sierra
	vars.splitbsp_040 = new ulong[8] { 70746701299715, 76347338653703, 5987184410895, 43920335569183, 52712133624127, 4449586119039, 110002702385663, 127560528691711 }; //storm 
	vars.splitbsp_070 = new ulong[9] { 319187993615142919, 497073530286903311, 5109160733019475999, 7059113264503853119, 7058267740062093439, 5296235395170702591, 6467180094380056063, 6471685893030682623, 6453663797939806207 }; //ark
	vars.splitbsp_100 = new ulong[11] { 4508347378708774919, 2060429875000377375, 4384271889560765215, 2060429875000378143, 4508347378708775711, 4229124150272197439, 4105313024951190527, 4159567262287660031, 4153434048988972031, 4099400491367139327, 21673629041340192 }; //cov
	vars.splitbsp_120 = new ulong[6] { 1030792151055, 691489734703, 1924145349759, 1133871367679, 1202590844927, 1219770714111 }; //halo
	
	//new levels
	vars.splitbsp_020 = new ulong[10] { 2753726871765283, 351925325267239, 527984624664871, 527980329698111, 355107896034111, 495845384389503, 1058778157941759, 2081384101315583, 2076028277097471, 2043042928264191}; //crows nest
	vars.splitbsp_030 = new ulong[5] { 708669603847, 1812476198927, 1709396983839, 128849018943, 2327872274495}; //tsavo
	vars.splitbsp_050 = new ulong[7] { 137438953607, 154618822791, 167503724703, 98784247967, 98784247999, 133143986431, 111669150207}; //floodgate
	vars.splitbsp_110 = new ulong[4] { 4294967459, 4294967527, 4294967535, 4294967551}; //cortana
		

	//HALO REACH
	vars.splitbsp_m10 = new uint[4] { 143, 175, 239, 495 }; // WC
	vars.splitbsp_m20 = new uint[4] { 249, 505, 509, 511 }; // oni
	vars.splitbsp_m30 = new uint[6] { 269, 781, 797, 1821, 1853, 1917 }; // nightfall
	vars.splitbsp_m35 = new uint[5] { 4111, 4127, 4223, 4607, 5119 }; //tots
	vars.splitbsp_m45 = new uint[6] { 31, 383, 10111, 12159, 16255, 32639 }; //lnos, might have to swap 895 for 10111 since former is cs only. 127 is cs only too, swap for 383?
	vars.splitbsp_m50 = new uint[5] { 5135, 5151, 5247, 5631, 8191 }; //exo
	//skipping NA
	vars.splitbsp_m60 = new uint[5] { 113, 125, 4221, 4223, 5119 }; //package
	vars.splitbsp_m70 = new uint[7] { 31, 63, 127, 255, 511, 1023, 2047 }; //poa
	
	
	//HALO 4
	vars.nosplitbsp_m10 = new ulong[3] { 0, 0x0000000001800000, 0x000000000700000F };
	vars.nosplitbsp_m02 = new ulong[2] { 0, 0x0000000080000C02 };
	vars.nosplitbsp_m30 = new ulong[2] { 0, 0x0000000072001902 };
	vars.nosplitbsp_m40 = new ulong[3] { 0, 0x00000040000C0001, 0x00000000013C0001 };
	vars.nosplitbsp_m60 = new ulong[3] { 0, 0x0000C00002100001, 0x0000400006000001 };
	vars.nosplitbsp_m70 = new ulong[2] { 0, 0x0000000100100004};
	vars.nosplitbsp_m80 = new ulong[4] { 0, 0x0020000080000006, 0x0000000080400006, 0x0000000180C0000E};
	vars.nosplitbsp_m90 = new ulong[3] { 0, 0x0000010000000006, 0x0000000000A00006};
	
	
	
	//HALO ODST	
	//streets
	vars.splitbsp_h100 = new ulong[9] { 1271310319912, 1511828488552, //drone optic
		1511828488544, 1305670058352, 1717986918896, 3848290698224, //guass turret
		1125281431814, //remote det (actually goes to sniper)
		1666447311756, //sniper rifle (actually goes to guass turret)
		1112396529931
		//no loads on pre data hive
	};//end streets
	//hopefully no 1236950581544, it shows up on drone optic without actual bsp load
	//1374389535040, 1168231104880 shows up on guass turret
	//1116691497220 shows up on remote det
	//3848290698120 shows up on .. first bsp load doesn't show up on my bytes, so gonna have to skip that one
	//1108101562634 more bad vals
	//1103806595337 more
	//no bsp loads on ptd
	
	vars.splitbsp_sc10 = new ulong[3] { 60129542158, 55834574863, 38654705679 }; //tayari
	
	
	vars.splitbsp_sc11 = new ulong[3] { 339302416463, 395136991327, 412316860543 }; //uplift reserve
	//first load has issue of being used in cutscene - add check for pgcr time being > 30 or something
	
	vars.splitbsp_sc13 = new ulong[2] { 47244640267,  30064771087}; //oni
	//bad vals 38654705673
	//12884901899 is a a valid bsp bsp load but i've removed it since it doesn't save time to compare to
	
	vars.splitbsp_sc12 = new ulong[3] { 47244640267, 60129542159, 51539607567 }; //kizingo
	//bad vals 38654705673, 42949672971
	
	vars.splitbsp_sc14 = new ulong[3] { 47244640267, 60129542159, 51539607567}; //NMPD
	//bad vals 38654705673
	//yes the vals are the same as kizongo
	
	vars.splitbsp_sc15 = new ulong[3] { 60129542159, 120259084319, 103079215135 }; //kikowani
	//bad vals 4294967297, 25769803783
	
	vars.splitbsp_l200 = new ulong[7] { 60129542159, 120259084319, 103079215135, 206158430271, 893353197823, 962072674559, 1786706395647}; //data hive
	//30064771079, 30064771072, 824633721087
	
	vars.splitbsp_l300  = new ulong[1] { 141733920935 }; //coastal
	//575525617798, 176093659311 (valid bsp but no timesave), 171798692015, 240518168767(valid but no timesave), 206158430399, 481036337407
	
	
	vars.aslName = "MCCsplitter";
	if(timer.CurrentTimingMethod == TimingMethod.RealTime){
		
		var timingMessage = MessageBox.Show(
			"This game uses Game Time (time without loads) as the main timing method. "+
			"LiveSplit is currently set to show Real Time (time INCLUDING loads). "+
			"Would you like the timing method to be set to Game Time for you?",
			vars.aslName+" | LiveSplit",
			MessageBoxButtons.YesNo,MessageBoxIcon.Question
		);
		if (timingMessage == DialogResult.Yes)
		timer.CurrentTimingMethod = TimingMethod.GameTime;
	}
	
	settings.Add("ILmode", false, "Individual Level mode");
	settings.SetToolTip("ILmode", "Makes the timer start, reset and ending split at the correct IL time for each level. For H2/H3, switches timing to PGCR timer.");
	
	settings.Add("Loopmode", false, "Level Loop mode", "ILmode");
	settings.SetToolTip("Loopmode", "For TBx10 (or similiar memes)");
	
	settings.Add("bspmode", false, "Split on unique \"Loading... Done\"'s ");
	settings.SetToolTip("bspmode", "Split on unique bsp loads (\"Loading... Done\") within levels. \n" +
		"You'll need to add a lot of extra splits for this option, see this spreadsheet for a count of how many per level of each game: \n" +
		"tinyurl.com/bspsplit"
	);
	
	settings.Add("bsp_cache", false, "Split on non-unique loads too", "bspmode");
	settings.SetToolTip("bsp_cache", "With this disabled, only the first time you enter a specific bsp will cause a split. \n" +
		"This is so that if you hit a load, then die and revert to before the load, and hit again, you won't get duplicate splits. \n" +
		"You probably shouldn't turn this on, unless you're say, practicing a specific segment of a level (from one load to another)."
	);
	
	settings.Add("anylevel", false, "Start full-game runs on any level (breaks multi-game runs)");
	settings.Add("menupause", true, "Pause when in Main Menu", "anylevel");
	settings.Add("sqsplit", false, "Split when loading a new level", "anylevel");
	settings.SetToolTip("sqsplit", "Useful for categories like Hunter%. Only works for Halo CE currently");

	settings.Add("deathcounter", false, "Enable Death Counter");
	settings.SetToolTip("deathcounter", "Will automatically create a layout component for you. Feel free \n" +
		"to move it around, but you won't be able to rename it"
	);

	settings.Add("debugmode", false, "Debug Mode");
	settings.SetToolTip("debugmode", "Probably shouldn't tick this");

	settings.Add("perfmode", false, "Performance Mode", "debugmode");
	settings.SetToolTip("perfmode", "Reduces the autosplitter refresh rate to 30Hz. Requires restart. No idea if this even works");

	settings.Add("IGTadd", false, "Add exact IGT on mission restart", "debugmode");
	settings.SetToolTip("IGTadd", "Add exact IGT value on mission restart instead of rounding to the value seen on-screen");

	settings.Add("IGTmode", false, "IGT Debug", "debugmode");
	settings.SetToolTip("IGTmode", "IGT debug mode. Don't use this unless you want bad things to happen");
	
	


	//DEATH COUNTERS AND FUN
	//DEATHS
	vars.TextDeathCounter     = null;
	vars.DeathCounter         = 0;
	vars.UpdateDeathCounter = (Action)(() => {
		if(vars.TextDeathCounter == null) {
			foreach (dynamic component in timer.Layout.Components) {
				if (component.GetType().Name != "TextComponent") continue;
				
				if (component.Settings.Text1 == "Deaths:"){
					vars.TextDeathCounter = component.Settings;
					break;
				}
			}
			if(vars.TextDeathCounter == null) {
				vars.TextDeathCounter = vars.CreateTextComponent("Deaths:");
			}
		}
		
		vars.TextDeathCounter.Text2 = vars.DeathCounter.ToString();
	});
	
	
	vars.CreateTextComponent = (Func<string, dynamic>)((name) => {
		var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
		dynamic textComponent = Activator.CreateInstance(textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);
		timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", textComponent as LiveSplit.UI.Components.IComponent));
		textComponent.Settings.Text1 = name;
		return textComponent.Settings;
	}); 

} 


update 
{
	//Update state vars
	vars.watchers_fast.UpdateAll(game);
	
	if (!(vars.menuindicator.Current == 7))
	{
		vars.watchers_slow.UpdateAll(game);
		if (vars.pgcrexists == true) {vars.pgcrexists = false;} //sanity check. Should never come up normally
	}
	else if (vars.menuindicator.Current == 7)
	{
		if (vars.loopcount == 60) //update slow when actually in game and fast when on menu. Fixes some false resetting
		{
			vars.watchers_slow.UpdateAll(game);
			vars.loopcount = 0;
		}
		else {++vars.loopcount;}

		byte test = vars.gameindicator.Current;
		switch (test)
		{
			//H1
			case 0:
			vars.watchers_h1.UpdateAll(game);
			if (settings["deathcounter"]) {vars.watchers_h1death.UpdateAll(game);}
			break;
			
			//H2
			case 1:
			vars.watchers_h2.UpdateAll(game);
			if (settings["deathcounter"]) {vars.watchers_h2death.UpdateAll(game);}
			if (settings["bspmode"]) {vars.watchers_h2bsp.UpdateAll(game);}
			break;
			
			//H3
			case 2:
			vars.watchers_h3.UpdateAll(game);
			if (settings["deathcounter"]) {vars.watchers_h3death.UpdateAll(game);}
			if (settings["bspmode"]) {vars.watchers_h3bsp.UpdateAll(game);}
			if (settings["ILmode"]) {vars.watchers_igt.UpdateAll(game);}
			break;
			
			//H4
			case 3:
			vars.watchers_h4.UpdateAll(game);
			vars.watchers_igt.UpdateAll(game);
			if (settings["bspmode"]) {vars.watchers_h4bsp.UpdateAll(game);}
			break;
			
			//ODST
			case 5:
			vars.watchers_odst.UpdateAll(game);
			vars.watchers_igt.UpdateAll(game);
			if (settings["bspmode"]) {vars.watchers_odstbsp.UpdateAll(game);}
			if (settings["deathcounter"]) {vars.watchers_odstdeath.UpdateAll(game);}	
			break;
			
			//HR
			case 6: 
			vars.watchers_hr.UpdateAll(game);
			vars.watchers_igt.UpdateAll(game);
			if (settings["deathcounter"]) {vars.watchers_hrdeath.UpdateAll(game);}
			if (settings["bspmode"]) {vars.watchers_hrbsp.UpdateAll(game);}
			break;
		}
	}


	//var reset
	if (timer.CurrentPhase == TimerPhase.Running && vars.varsreset == false)
	{
		vars.varsreset = true;
	}
	else if (timer.CurrentPhase == TimerPhase.NotRunning && vars.varsreset == true)
	{
		vars.loading = false;
		vars.multigamepause = false;

		vars.startedlevel = "000";
		vars.levelloaded = "000";
		vars.startedgame = 10;
		vars.loopsplit = true;
		vars.forcesplit = false;
		vars.forcesplit2 = false;
		vars.DeathCounter = 0;

		if (settings["deathcounter"])
		vars.UpdateDeathCounter();
		
		vars.H2_tgjreadyflag = false;
		vars.H2_tgjreadytime = 0;
		vars.lastinternal = false;

		vars.dirtybsps_byte.Clear();
		vars.dirtybsps_int.Clear();
		vars.dirtybsps_long.Clear();

		vars.gametime = TimeSpan.Zero;
		vars.multigametime = TimeSpan.Zero;
		vars.ingametime = 0;
		vars.leveltime = 0;
		vars.pgcrexists = false;

		vars.varsreset = false;
		vars.partialreset = false;

		print ("Autosplitter vars reinitalized!");
	}


	//Things that only need to happen after timer has started
	if (timer.CurrentPhase == TimerPhase.Running)
	{
		byte test = vars.gameindicator.Current;

		//Clear dirty bsps
		if (vars.partialreset)
		{
			switch (test)
			{
				case 0:
				case 1:
				vars.dirtybsps_byte.Clear();
				break;

				case 2:
				case 3:
				vars.dirtybsps_long.Clear();
				break;

				case 5:
				if (vars.ODST_levelnameBad.Current != "h100") {vars.dirtybsps_long.Clear();}
				break;

				case 6:
				vars.dirtybsps_int.Clear();
				break;
			}

			if (settings["debugmode"]) {print("Dirty BSPs cleared");}
			vars.partialreset = false;
		}
		

		//If someone is manually starting the timer for some reason
		if (vars.menuindicator.Current == 7 && (vars.startedlevel == "000" || vars.startedlevel == null))
		{
			switch (test)
			{
				case 0:
				vars.startedlevel = vars.H1_levelname.Current;
				vars.startedgame = 0;
				break;

				case 1:
				vars.startedlevel = vars.H2_levelname.Current;
				vars.startedgame = 1;
				break;

				case 2:
				vars.startedlevel = vars.H3_levelname.Current;
				vars.startedgame = 2;
				break;

				case 3:
				vars.startedlevel = vars.H4_levelname.Current;
				vars.startedgame = 3;
				break;

				case 5:
				vars.startedlevel = vars.ODST_levelnameBad2.Current;
				vars.startedgame = 5;
				break;

				case 6:
				vars.startedlevel = vars.HR_levelname.Current;
				vars.startedgame = 6;
				break;
			}
			print ("Manual timer start detected, updating startedlevel");
		}


		if (!vars.multigamepause)
		{
			//IGT function
			if (vars.menuindicator.Current == 7 && (settings["IGTmode"] || !(test == 0 || (test == 1 && !settings["ILmode"]))))
			{
				//reset gametime return of current iteration
				vars.gametime = TimeSpan.Zero;

				uint IGT = 0;
				uint IGTold = 0;
				byte tickrate = 0;
				string level = "000";
				
				switch (test)
				{
					case 0:
					IGT = vars.H1_IGT.Current;
					IGTold = vars.H1_IGT.Old;
					tickrate = 30;
					level = vars.H1_levelname.Current;
					break;

					case 1:
					IGT = vars.H2_IGT.Current;
					IGTold = vars.H2_IGT.Old;
					tickrate = 60;
					level = vars.H2_levelname.Current;
					break;

					case 2:
					if (settings["ILmode"])
					{
						IGT = (uint)Math.Round(vars.IGT_float.Current * 60);
						IGTold = (uint)Math.Round(vars.IGT_float.Old * 60);
						tickrate = 60;
						level = vars.H3_levelname.Current;
					}
					else
					{
						IGT = vars.H3_theatertime.Current;
						IGTold = vars.H3_theatertime.Old;
						tickrate = 60;
						level = vars.H3_levelname.Current;
					}
					break;

					case 3:
					IGT = (uint)Math.Round(vars.IGT_float.Current * 60);
					IGTold = (uint)Math.Round(vars.IGT_float.Old * 60);
					tickrate = 60;
					level = vars.H4_levelname.Current;
					break;

					case 5:
					IGT = (uint)Math.Round(vars.IGT_float.Current * 60);
					IGTold = (uint)Math.Round(vars.IGT_float.Old * 60); 
					tickrate = 60;
					if (vars.ODST_levelnameBad.Current.Length > 1) //Check that the level name actually exists in memory so a bunch of errors dont get spat out
					{
						if (vars.ODST_levelnameBad.Current[1] == '\\') {level = vars.ODST_levelnameBad2.Current;}
						else {level = vars.ODST_levelnameBad.Current;}
					}
					else {level = vars.ODST_levelnameBad2.Current;} //Streets are not a real level :)
					break;

					case 6:
					IGT = (uint)Math.Round(vars.IGT_float.Current * 60);
					IGTold = (uint)Math.Round(vars.IGT_float.Old * 60);
					tickrate = 60;
					level = vars.HR_levelname.Current;
					break;

				}

				if (settings["debugmode"])
				{
					print("IGT: " + IGT);
					print("IGTold: " + IGTold);
				}

				//Squiggily mess is squiggily. I have no idea how this works even though I wrote it :)
				if (settings["ILmode"]) //ILs
				{
					if (settings["Loopmode"])
					{
						if (vars.leveltime == 0)
						{
							if (vars.stateindicator.Current != 44 && !(vars.pgcrexists) && vars.startedlevel == level)  {vars.leveltime = IGT;}
						}
						else if ((IGT - IGTold) > 0 && (IGT - IGTold) < 300 && vars.startedlevel == level) {vars.leveltime = vars.leveltime + (IGT - IGTold);}
						
						if (vars.stateindicator.Current == 57 && vars.stateindicator.Old != 57 && vars.stateindicator.Old != 190) //add times
						{
							vars.ingametime = vars.ingametime + ((vars.leveltime) - ((vars.leveltime) % tickrate));
							vars.leveltime = 0;
							vars.pgcrexists = true;
							vars.forcesplit = true;
						}
						else if (vars.stateindicator.Current == 44 && vars.stateindicator.Old != 44)
						{
							if (!(vars.pgcrexists))
							{
								vars.ingametime = vars.ingametime + ((vars.leveltime) - ((vars.leveltime) % tickrate));
								vars.leveltime = 0;
								vars.forcesplit = true;
							}
							vars.pgcrexists = false;
						}
						else if (IGT < IGTold && IGT < 10 && vars.stateindicator.Current != 44)
						{
							if (!settings["IGTadd"])
							{
								if ((vars.leveltime % tickrate) > (0.5 * tickrate)) {vars.ingametime = vars.ingametime + (vars.leveltime + (tickrate - (vars.leveltime % tickrate)));}
								else {vars.ingametime = vars.ingametime + ((vars.leveltime) - ((vars.leveltime) % tickrate));}
							}
							else {vars.ingametime = vars.ingametime + vars.leveltime;}
							vars.leveltime = 0;
						}
						
						if (level != vars.startedlevel || vars.stateindicator.Current == 44) {vars.gametime = TimeSpan.FromMilliseconds((1000.0 / tickrate) * (vars.ingametime));}
						else {vars.gametime = TimeSpan.FromMilliseconds((1000.0 / tickrate) * (vars.ingametime + vars.leveltime));}		
					}
					else
					{
						if (vars.stateindicator.Current == 57 && vars.stateindicator.Old != 57 && vars.stateindicator.Old != 190) //add times
						{
							vars.pgcrexists = true;
							vars.forcesplit = true;
						}
						else if (vars.stateindicator.Current == 44 && vars.stateindicator.Old != 44)
						{
							if (!(vars.pgcrexists)) {vars.forcesplit = true;}
							vars.pgcrexists = false;
						}
						vars.gametime = TimeSpan.FromMilliseconds((1000.0 / tickrate) * (IGT));
					}
				}
				else //Fullgame or anylevel
				{
					if (vars.leveltime == 0)
					{
						if (vars.stateindicator.Current != 44 && !(vars.pgcrexists)) {vars.leveltime = IGT;}
					}
					else if ((IGT - IGTold) > 0 && (IGT - IGTold) < 300) {vars.leveltime = vars.leveltime + (IGT - IGTold);}

					if (test == 2) //Want to do the math on the loading screen for theatre timing
					{
						if (vars.stateindicator.Current == 44 && vars.stateindicator.Old != 44)
						{
							vars.ingametime = vars.ingametime + ((vars.leveltime) - ((vars.leveltime) % tickrate));
							vars.leveltime = 0;
						}
					}
					else
					{
						if (vars.stateindicator.Current == 57 && vars.stateindicator.Old != 57 && vars.stateindicator.Old != 190) //add times
						{
							vars.ingametime = vars.ingametime + ((vars.leveltime) - ((vars.leveltime) % tickrate));
							vars.leveltime = 0;
							vars.pgcrexists = true;
							vars.forcesplit = true;
						}
						else if (vars.stateindicator.Current == 44 && vars.stateindicator.Old != 44)
						{
							if (!(vars.pgcrexists))
							{
								vars.ingametime = vars.ingametime + ((vars.leveltime) - ((vars.leveltime) % tickrate));
								vars.leveltime = 0;
								vars.forcesplit = true;
							}
							vars.pgcrexists = false;
						}
						else if (IGT < IGTold && IGT < 10 && vars.stateindicator.Current != 44)
						{
							if (!settings["IGTadd"])
							{
								if ((vars.leveltime % tickrate) > (0.5 * tickrate)) {vars.ingametime = vars.ingametime + (vars.leveltime + (tickrate - (vars.leveltime % tickrate)));}
								else {vars.ingametime = vars.ingametime + ((vars.leveltime) - ((vars.leveltime) % tickrate));}
							}
							else {vars.ingametime = vars.ingametime + vars.leveltime;}
							vars.leveltime = 0;
						}
					}

					if (vars.stateindicator.Current == 44) {vars.gametime = (TimeSpan.FromMilliseconds((1000.0 / tickrate) * (vars.ingametime)) + vars.multigametime);}
					else {vars.gametime = (TimeSpan.FromMilliseconds((1000.0 / tickrate) * (vars.ingametime + vars.leveltime)) + vars.multigametime);}
				}
			}

			//RTA games load removal stuff. Moved here to prevent conflict with multigamepause and other types of timer pause logic
			else if (vars.gameindicator.Current == 0 && !((settings["IGTmode"]) || settings["ILmode"])) //Halo 1
			{
				if (vars.loading == false) //if not currently loading, determine whether we need to be.
				{
					if (vars.menuindicator.Current == 7) //between level loads.
					{
						if (vars.H1_levelname.Current != vars.H1_levelname.Old && vars.H1_levelname.Current != vars.startedlevel && 
						(vars.H1_levelname.Current == "a10" 
						|| vars.H1_levelname.Current == "a30" 
						|| vars.H1_levelname.Current == "a50" 
						|| vars.H1_levelname.Current == "b30" 
						|| vars.H1_levelname.Current == "b40" 
						|| vars.H1_levelname.Current == "c10" 
						|| vars.H1_levelname.Current == "c20" 
						|| vars.H1_levelname.Current == "c40" 
						|| vars.H1_levelname.Current == "d20" 
						|| vars.H1_levelname.Current == "d40")) //why does .contains not work for strings? eee.
						{
							vars.loading = true;
						}
					}
					else if (vars.stateindicator.Current == 44) {vars.loading = true;}	//main menu to level loads.
				}
				else //if currently loading, determine whether we need to not be.
				{
					if (vars.H1_tickcounter.Current == (vars.H1_tickcounter.Old + 1)) {vars.loading = false;}//determine whether to unpause the timer, ie tick counter starts incrementing again.
				}
			}
			else if (vars.gameindicator.Current == 1 && !(settings["ILmode"] || settings["IGTmode"])) //Halo 2
			{
				if (vars.loading == false ) //if not currently loading, determine whether we need to be
				{
					if (vars.menuindicator.Current == 7) //between level loads.
					{
						string H2_checklevel = vars.H2_levelname.Current;
						switch (H2_checklevel)
						{
							case "01a": //Armory
							if (vars.stateindicator.Current == 44 || vars.stateindicator.Current == 57) {vars.loading = true;}
							break;

							case "01b": //Cairo
							case "03a": //Outskirts
							case "03b": //Metropolis
							case "04a": //Arbiter
							case "05a": //Delta Halo
							case "06a": //Sacred Icon
							case "07a": //Gravemind
							case "08a": //Uprising
							case "07b": //High Charity
							if ((vars.H2_tickcounter.Current > 60 && vars.H2_fadebyte.Current == 1 && vars.H2_fadebyte.Old == 1 && vars.H2_letterbox.Current > 0.96 && vars.H2_letterbox.Old <= 0.96 && vars.H2_letterbox.Old != 0) || vars.stateindicator.Current == 44 || vars.stateindicator.Current == 57)
							{
								vars.loading = true;
							}
							break;

							case "04b": //Oracle
							case "05b": //Regret
							if (vars.lastinternal == false && (vars.H2_fadebyte.Current == 1 && vars.H2_letterbox.Current > 0.96 && vars.H2_letterbox.Old <= 0.96 && vars.H2_letterbox.Old != 0))
							{
								vars.watchers_h2bsp.UpdateAll(game);
								if (vars.H2_levelname.Current == "04b" && vars.H2_bspstate.Current == 5) {vars.lastinternal = true;}
								else if (vars.H2_levelname.Current == "05b" && vars.H2_bspstate.Current == 2) {vars.lastinternal = true;}

							}
							else if ((vars.H2_tickcounter.Current > 60 && vars.lastinternal == true && vars.H2_fadebyte.Current == 1 && vars.H2_fadebyte.Old == 1 && vars.H2_letterbox.Current > 0.96 && vars.H2_letterbox.Old <= 0.96 && vars.H2_letterbox.Old != 0) || vars.stateindicator.Current == 44 || vars.stateindicator.Current == 57)
							{
								vars.loading = true;	
								vars.lastinternal = false;
							}
							break;

							case "06b":	//Quarantine Zone
							if ((vars.H2_tickcounter.Current > 60 && vars.H2_fadebyte.Current == 1 && vars.H2_fadebyte.Old == 1 && vars.H2_letterbox.Current > 0.96 && vars.H2_letterbox.Old <= 0.96 && vars.H2_letterbox.Old != 0) || vars.stateindicator.Current == 44 || vars.stateindicator.Current == 57)
							{
								vars.watchers_h2bsp.UpdateAll(game);
								if (vars.H2_bspstate.Current == 4  || vars.stateindicator.Current == 44 || vars.stateindicator.Current == 57) {vars.loading = true;}
							}
							break;
						}

					}
					else if (vars.stateindicator.Current == 44 || vars.stateindicator.Current == 57) {vars.loading = true;}	//main menu to level loads.
				}
				else	//if currently loading, determine whether we need not be
				{
					if (vars.menuindicator.Current == 7) //between level loads.
					{
						string H2_checklevel = vars.H2_levelname.Current;
						switch (H2_checklevel)
						{
							case "01a": //Armory
							case "01b": //Cairo
							case "03b":	//Metropolis
							case "04a":	//Arbiter
							case "04b": //Oracle
							case "05a": //Delta Halo
							case "05b": //Regret
							case "06a": //Sacred Icon
							case "06b": //Quarantine Zone
							case "07a": //Gravemind
							case "08a": //Uprising
							case "07b": //High Charity
							case "08b": //The Great Journey
							if (vars.H2_fadebyte.Current == 0 && vars.H2_fadebyte.Old == 1 && vars.stateindicator.Current != 44 && vars.stateindicator.Current != 129)
							{
								vars.loading = false;
								vars.lastinternal = false;
							} else if (vars.H2_fadebyte.Current == 0 && vars.H2_tickcounter.Current > vars.H2_tickcounter.Old && vars.H2_tickcounter.Current > 10 && vars.stateindicator.Current != 44) {vars.loading = false;}
							break;

							case "03a": // Outskirts
							if (vars.stateindicator.Current != 44)
							{
								if (vars.H2_fadebyte.Current == 1 && vars.H2_tickcounter.Current >= 30 && vars.H2_tickcounter.Current < 40)
								{
									vars.watchers_h2bsp.UpdateAll(game);
									if (vars.H2_bspstate.Current == 0) {vars.loading = false;}
								}
								else if (vars.H2_fadebyte.Current == 0 && vars.H2_tickcounter.Current > vars.H2_tickcounter.Old && vars.H2_tickcounter.Current > 10 && vars.stateindicator.Current != 44) {vars.loading = false;}
							}
							break;	
						}
					}
				}
				//TGJ cutscene rubbish
				if (vars.H2_levelname.Current == "08b" && vars.H2_tgjreadyflag == false) 
				{
					vars.watchers_h2bsp.UpdateAll(game);
					if (vars.H2_bspstate.Current == 3)
					{
						vars.H2_tgjreadyflag = true;
						vars.H2_tgjreadytime = vars.H2_tickcounter.Current;
						print ("H2 tgj ready flag set");
					} 
				}
			}

			if (!settings["ILmode"])
			{
				//Save and quit splitting level tracking. Should probably get it working in other games, but eh
				if (settings["sqsplit"] && vars.gameindicator.Current == 0)
				{
					if (vars.levelloaded == "000") {vars.levelloaded = vars.startedlevel;}
					else if (vars.forcesplit2 == false && vars.stateindicator.Current == 44 && vars.H1_levelname.Current != vars.levelloaded && 
					(vars.H1_levelname.Current == "a10" 
						|| vars.H1_levelname.Current == "a30" 
						|| vars.H1_levelname.Current == "a50" 
						|| vars.H1_levelname.Current == "b30" 
						|| vars.H1_levelname.Current == "b40" 
						|| vars.H1_levelname.Current == "c10" 
						|| vars.H1_levelname.Current == "c20" 
						|| vars.H1_levelname.Current == "c40" 
						|| vars.H1_levelname.Current == "d20" 
						|| vars.H1_levelname.Current == "d40")) //determine if there is a level swap thus a split required
					{
						if (vars.H1_levelname.Current != vars.startedlevel) //dont split if loading the starting level, probably a reset/loopmode. Otherwise split.
						{
							vars.levelloaded = vars.H1_levelname.Current;
							vars.forcesplit2 = true;
						}
					}
				}


				//Moved multigamepuse logic here as was pausing 1 cycle late in RTA games previously. Also handles end game split for RTA and theatre games so not doing the same checks twice for no reason
				switch (test)
				{
					case 0:
					if (vars.H1_levelname.Current == "d40" && vars.H1_cinematic.Old == false && vars.H1_cinematic.Current == true && vars.H1_cutsceneskip.Current == false)
					{							
						vars.watchers_h1death.UpdateAll(game);
						if (vars.H1_deathflag.Current == false)
						{
							if (settings["anylevel"]) {vars.loading = true;} else {vars.multigamepause = true;}
							vars.forcesplit = true;
						}
					}
					break;

					case 1:
					if (vars.H2_levelname.Current == "08b" && (vars.H2_fadebyte.Current == 1 && vars.H2_letterbox.Current > 0.96 && vars.H2_letterbox.Old <= 0.96  && vars.H2_letterbox.Old != 0 && vars.H2_tgjreadyflag && ( vars.H2_tickcounter.Current > (vars.H2_tgjreadytime + 300))))
					{
						if (settings["anylevel"]) {vars.loading = true;} else {vars.multigamepause = true;}
						vars.H2_tgjreadyflag = false;
						vars.forcesplit = true;
					}
					break;

					case 2:
					if (vars.stateindicator.Current == 44 && vars.stateindicator.Old != 44 && vars.H3_levelname.Current == "130" && !settings["anylevel"])
					{
						vars.multigamepause = true;
						vars.forcesplit = true;
					}
					break;

					case 3:
					if (vars.stateindicator.Current == 57 && vars.stateindicator.Old != 57 && vars.stateindicator.Old != 190 && vars.H4_levelname.Current == "m90")
					{
						if (!settings["anylevel"]) {vars.multigamepause = true;}
					}
					break;

					case 5:
					if (vars.stateindicator.Current == 57 && vars.stateindicator.Old != 57 && vars.stateindicator.Old != 190 && vars.ODST_levelnameBad2.Current == "l300")
					{
						if (!settings["anylevel"]) {vars.multigamepause = true;}
					}
					break;

					case 6:
					if (vars.stateindicator.Current == 57 && vars.stateindicator.Old != 57 && vars.stateindicator.Old != 190 && vars.HR_levelname.Current == "m70")
					{
						if (!settings["anylevel"]) {vars.multigamepause = true;}
					}
					break;
				}

				if (settings["debugmode"] && vars.multigamepause) {print ("multigamepause is true");}
			}
		}
		else if (vars.multigamepause)
		{
			if (vars.menuindicator.Current == 7) 
			{
				switch (test)
				{
					case 0:
					if (vars.H1_levelname.Current == "a10" && vars.H1_bspstate.Current == 0 && vars.H1_tickcounter.Current > 280 && vars.H1_cinematic.Current == false && vars.H1_cinematic.Old == true) //Start on PoA
					{
						vars.watchers_h1xy.UpdateAll(game);
						if (vars.H1_xpos.Current < -55)
						{
							vars.multigamepause = false;
						}
					}
					break;
					
					case 1:
					if (vars.H2_levelname.Current == "01b" && vars.stateindicator.Current != 44 && vars.H2_fadebyte.Current == 0 && vars.H2_fadebyte.Old == 1 && vars.H2_tickcounter.Current < 30) //start on cairo
					{
						vars.multigamepause = false;
					}
					else if (vars.H2_levelname.Current == "01a" && vars.H2_tickcounter.Current > 26 &&  vars.H2_tickcounter.Current < 30) //start on armory
					{
						vars.multigamepause = false;
					}
					break;
					
					case 2:
					if (vars.H3_levelname.Current == "010" && vars.H3_theatertime.Current > 15 && vars.H3_theatertime.Current < 30)
					{
						vars.multigamepause = false;
					}
					break;
					
					case 3:
					if 	(vars.H4_levelname.Current == "m10" && vars.IGT_float.Current > 0.167 && vars.IGT_float.Current < 0.5)
					{
						vars.multigamepause = false;
					}
					break;
					
					case 5: //ODST
					if (vars.ODST_levelnameBad2.Current == "c100" && vars.IGT_float.Current > 0.167 && vars.IGT_float.Current < 0.5) //there was a bsp check here; do I still need it?
					{
						vars.multigamepause = false;
					}
					break;
					
					case 6:
					if 	(vars.HR_levelname.Current == "m10" && vars.IGT_float.Current > 0.167 && vars.IGT_float.Current < 0.5)
					{
						vars.multigamepause = false;
					}
					break;
				}

				if (settings["debugmode"] && !vars.multigamepause) {print ("multigamepause is false");}
			}
		}
	}
}





start 	//starts timer
{	
	string checklevel; 

	if (vars.menuindicator.Current == 7) 
	{
		byte test = vars.gameindicator.Current;
		vars.startedgame = test; //Why did 343 reuse reach level names in H4 smh my head!
		switch (test)
		{
			//Halo 1
			case 0:
			if (vars.H1_levelname.Current == "a10" && vars.H1_bspstate.Current == 0 && vars.H1_tickcounter.Current > 280 && vars.H1_cinematic.Current == false && vars.H1_cinematic.Old == true) //Start on PoA
			{
				vars.watchers_h1xy.UpdateAll(game);
				if (vars.H1_xpos.Current < -55)
				{
					vars.startedlevel = "a10";
					return true;
				}
			}
			else if ((settings["ILmode"] || settings["anylevel"]) && vars.H1_levelname.Current != "a10")	//Start on any level thats not PoA
			{
				checklevel = vars.H1_levelname.Current;
				switch (checklevel)
				{
					case "a30":
					if (((vars.H1_tickcounter.Current >= 182 && vars.H1_tickcounter.Current < 190) || (vars.H1_cinematic.Current == false && vars.H1_cinematic.Old == true && vars.H1_tickcounter.Current > 500 && vars.H1_tickcounter.Current < 900)) && vars.H1_cutsceneskip.Current == false) //2 cases, depending on whether cs is skipped
					{
						vars.startedlevel = checklevel;
						return true;
					}
					break;

					case "a50":
					case "b30":
					case "b40":
					case "c10":
					if (vars.H1_tickcounter.Current > 30 && vars.H1_tickcounter.Current < 1060 && vars.H1_cinematic.Current == false && vars.H1_cinematic.Old == true) //levels with unskippable intro cutscenes
					{
						vars.startedlevel = checklevel;
						return true;
					}
					break;
					
					case "c20":
					case "c40":
					case "d20":
					case "d40":
					if (vars.H1_cutsceneskip.Current == false && vars.H1_cutsceneskip.Old == true) //levels with skippable intro cutscenes
					{
						vars.startedlevel = checklevel;
						return true;
					}
					break;

					default:
					return false;
					break;			
				}
			} 
			break;
			

			//Halo 2
			case 1: 
			if (vars.H2_levelname.Current == "01a" && vars.H2_tickcounter.Current >= 26 &&  vars.H2_tickcounter.Current < 30) //start on armory
			{
				vars.startedlevel = "01a";
				return true;
			}
			else if (vars.H2_levelname.Current == "01b" && vars.stateindicator.Current != 44 && vars.H2_fadebyte.Current == 0 && vars.H2_fadebyte.Old == 1 && vars.H2_tickcounter.Current < 30) //start on cairo
			{
				vars.startedlevel = "01b";
				return true;
			}
			else if ((settings["anylevel"] || settings["ILmode"]) && vars.stateindicator.Current != 44) //start on any other level
			{	
				if (vars.H2_levelname.Current == "03a")
				{
					vars.watchers_h2bsp.UpdateAll(game);
					if (vars.H2_fadebyte.Current == 1 && vars.H2_tickcounter.Current >= 30 && vars.H2_tickcounter.Current < 40 && vars.H2_bspstate.Current == 0)
					{
						vars.startedlevel = "03a";
						return true;
					}
				}
				else if (vars.H2_fadebyte.Current == 0 && vars.H2_fadebyte.Old == 1 && vars.H2_tickcounter.Current < 120)
				{
					vars.startedlevel = vars.H2_levelname.Current;
					return true;
				}
			} 
			break;
			

			//Halo 3
			case 2:
			if (settings["ILmode"] && vars.IGT_float.Current > 0.167 && vars.IGT_float.Current < 0.5)
			{
				vars.startedlevel = vars.H3_levelname.Current;
				return true;
			}
			else if (settings["anylevel"] || vars.H3_levelname.Current == "010")
			{
				
				if (vars.stateindicator.Current != 44 && vars.H3_theatertime.Current > 15 && vars.H3_theatertime.Current < 30)
				{
					vars.startedlevel = vars.H3_levelname.Current;
					return true;
				}
			}
			break;
			

			//Halo 4
			case 3:
			if ((settings["ILmode"] || settings["anylevel"] || vars.H4_levelname.Current == "m10") && vars.IGT_float.Current > 0.167 && vars.IGT_float.Current < 0.5)
			{
				vars.startedlevel = vars.H4_levelname.Current;
				return true;
			}
			break;
			

			//ODST
			case 5:
			if ((settings["ILmode"] || settings["anylevel"] || vars.ODST_levelnameBad2.Current == "c100") && vars.IGT_float.Current > 0.167 && vars.IGT_float.Current < 0.5)
			{
				vars.startedlevel = vars.ODST_levelnameBad2.Current;
				return true;
			}
			break;
			

			//Reach
			case 6:
			if ((settings["ILmode"] || settings["anylevel"] || vars.HR_levelname.Current == "m10") && vars.IGT_float.Current > 0.167 && vars.IGT_float.Current < 0.5)
			{
				vars.startedlevel = vars.HR_levelname.Current;
				return true;
			}
			break;
		}
	}	
}



split
{ 
	if (vars.forcesplit2) //for sqsplit
	{
		vars.forcesplit2 = false;
		vars.partialreset = true;
		return true;
	}
	
	if (vars.menuindicator.Current == 7)
	{
		if (vars.forcesplit) //for IGT game splits and RTA end game splits
		{
			vars.forcesplit = false;
			vars.partialreset = true;
			if (settings["Loopmode"]) {vars.loopsplit = false;}
			return true;
		}

		if (!vars.multigamepause)
		{
			byte test = vars.gameindicator.Current;
			string checklevel;

			switch (test)
			{
				//Halo 1
				case 0:

				//Death counter check
				if (settings["deathcounter"])
				{
					if (vars.H1_deathflag.Current && !vars.H1_deathflag.Old)
					{
						print ("adding death");
						vars.DeathCounter += 1;
						vars.UpdateDeathCounter();
					}
				}

				
				checklevel = vars.H1_levelname.Current;
				
				//Unpause timer at IL start
				if (settings["Loopmode"] && vars.H1_levelname.Current == vars.startedlevel && vars.loading == true && vars.H1_tickcounter.Current < 1500)
				{
					switch (checklevel)
					{
						case "a10":
						if (vars.H1_bspstate.Current == 0 && vars.H1_tickcounter.Current > 280 && vars.H1_cinematic.Current == false && vars.H1_cinematic.Old == true) //PoA
						{
							vars.watchers_h1xy.UpdateAll(game);
							if (vars.H1_xpos.Current < -55)
							{
								vars.dirtybsps_byte.Clear();
								vars.loading = false;
							}
						}
						break;
						
						case "a30":
						case "a50":
						case "b30":
						case "b40":
						case "c10":
						if (vars.H1_tickcounter.Current > 30 && vars.H1_tickcounter.Current < 1060 && vars.H1_cinematic.Current == false && vars.H1_cinematic.Old == true) //levels with unskippable intro cutscenes
						{
							vars.dirtybsps_byte.Clear();
							vars.loading = false;
						}
						break;
						
						case "c20":
						case "c40":
						case "d20":
						case "d40":
						if (vars.H1_cutsceneskip.Current == false && vars.H1_cutsceneskip.Old == true) //levels with skippable intro cutscenes
						{
							vars.dirtybsps_byte.Clear();
							vars.loading = false;
						}
						break;				
					}
				}

				if (settings["bspmode"])
				{
					
					if (settings["bsp_cache"])
					{
						switch (checklevel)
						{
							case "a10":
							return (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_a10, x => x == vars.H1_bspstate.Current));
							break;
							
							case "a30":
							return (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_a30, x => x == vars.H1_bspstate.Current));
							break;
							
							case "a50":
							return (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_a50, x => x == vars.H1_bspstate.Current));
							break;
							
							case "b30":
							return (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_b30, x => x == vars.H1_bspstate.Current));
							break;
							
							case "b40":
							return (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_b40, x => x == vars.H1_bspstate.Current));
							break;
							
							case "c10":
							return (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_c10, x => x == vars.H1_bspstate.Current));
							break;
							
							case "c20":
							return (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_c20, x => x == vars.H1_bspstate.Current));
							break;
							
							case "c40":
							return (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_c40, x => x == vars.H1_bspstate.Current));
							break;
							
							case "d20":
							return (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_d20, x => x == vars.H1_bspstate.Current));
							break;
							
							case "d40":
							return (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_d40, x => x == vars.H1_bspstate.Current));
							break;
							
							default:
							return false;
							break;
						}
					}
					
					switch (checklevel)
					{
						case "a10":
						if (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_a10, x => x == vars.H1_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H1_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H1_bspstate.Current);
							return true;
						}
						break;
						
						case "a30":
						if (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_a30, x => x == vars.H1_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H1_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H1_bspstate.Current);
							return true;
						}
						break;
						
						case "a50":
						if (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_a50, x => x == vars.H1_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H1_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H1_bspstate.Current);
							return true;
						}
						break;
						
						case "b30":
						if (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_b30, x => x == vars.H1_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H1_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H1_bspstate.Current);
							return true;
						}
						break;
						
						case "b40":
						if (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_b40, x => x == vars.H1_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H1_bspstate.Current)))
						{
							if (vars.H1_bspstate.Current == 0)
							{
									vars.watchers_h1xy.UpdateAll(game);
							if (vars.H1_ypos.Current > (-19.344 - 0.2) && vars.H1_ypos.Current < (-19.344 + 0.2))
								{
									vars.dirtybsps_byte.Add(vars.H1_bspstate.Current);
									return true;
								} else
								{
									return false;
								}
							} 
							else
							{
								vars.dirtybsps_byte.Add(vars.H1_bspstate.Current);
								return true;
							}
						}
						break;
						
						case "c10":
						if (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_c10, x => x == vars.H1_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H1_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H1_bspstate.Current);
							return true;
						}
						break;
						
						case "c20":
						if (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_c20, x => x == vars.H1_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H1_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H1_bspstate.Current);
							return true;
						}
						break;
						
						case "c40":
						if (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_c40, x => x == vars.H1_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H1_bspstate.Current)) && vars.H1_tickcounter.Current > 30)
						{
							if (vars.H1_bspstate.Current == 0)
							{
								//update xy, check for match
								vars.watchers_h1xy.UpdateAll(game);
								if (vars.H1_xpos.Current > 171.87326 && vars.H1_xpos.Current < 185.818526 && vars.H1_ypos.Current > -295.3629 && vars.H1_ypos.Current < -284.356986)
								{
									vars.dirtybsps_byte.Add(vars.H1_bspstate.Current);
									return true;
								} else
								{
									return false;
								}
							} 
							else
							{
								vars.dirtybsps_byte.Add(vars.H1_bspstate.Current);
								return true;
							}
						}
						break;
						
						
						case "d20":
						if (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_d20, x => x == vars.H1_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H1_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H1_bspstate.Current);
							return true;
						}
						break;
						
						case "d40":
						if (vars.H1_bspstate.Current != vars.H1_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_d40, x => x == vars.H1_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H1_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H1_bspstate.Current);
							return true;
						}
						break;
						
						default:
						break;
					}
				}
				
				if (!settings["IGTmode"]) //Just leaving this here for debugging igt code. It's mostly all copypasta anyway
				{
					if (settings["ILmode"]) //IL End level splits
					{
						switch (checklevel)
						{
							case "a10":
							if (vars.H1_bspstate.Current == 6 && vars.H1_cutsceneskip.Old == false && vars.H1_cutsceneskip.Current == true)
							{
								vars.dirtybsps_byte.Clear();
								if (settings["Loopmode"]) {vars.loading = true;}
								return true;
							}
							break;
							
							case "a30": //so we don't false split on lightbridge cs
							if (vars.H1_bspstate.Current == 1 && vars.H1_cutsceneskip.Old == false && vars.H1_cutsceneskip.Current == true)
							{
								vars.dirtybsps_byte.Clear();
								if (settings["Loopmode"]) {vars.loading = true;}
								return true;
							}
							break;
							
							case "a50": //so we don't false split on prison or lift cs.
							if (vars.H1_bspstate.Current == 3 && vars.H1_cutsceneskip.Old == false && vars.H1_cutsceneskip.Current == true)
							{
								vars.watchers_h1fade.UpdateAll(game);
								if(vars.H1_fadelength.Current == 15)
								{
									vars.dirtybsps_byte.Clear();
									if (settings["Loopmode"]) {vars.loading = true;}
									return true;
								}
							}
							break;
							
							case "b30": //no longer false splits on the security button
							if (vars.H1_bspstate.Current == 0 && vars.H1_cinematic.Current == false && vars.H1_cutsceneskip.Old == false && vars.H1_cutsceneskip.Current == true)
							{
								vars.dirtybsps_byte.Clear();
								if (settings["Loopmode"]) {vars.loading = true;}
								return true;
							}
							break;
							
							case "b40": 
							if (vars.H1_bspstate.Current == 2 && vars.H1_cutsceneskip.Old == false && vars.H1_cutsceneskip.Current == true) //mandatory bsp load for any category
							{
								vars.dirtybsps_byte.Clear();
								if (settings["Loopmode"]) {vars.loading = true;}
								return true;
							}
							break;
							
							case "c10": //so we don't split on reveal cs
							if (vars.H1_bspstate.Current != 2 && vars.H1_cutsceneskip.Old == false && vars.H1_cutsceneskip.Current == true)
							{
								vars.dirtybsps_byte.Clear();
								if (settings["Loopmode"]) {vars.loading = true;}
								return true;
							}
							break;

							case "c20":
							if (vars.H1_cinematic.Current == true && vars.H1_cinematic.Old == false && vars.H1_tickcounter.Current > 30)
							{
								vars.dirtybsps_byte.Clear();
								if (settings["Loopmode"]) {vars.loading = true;}
								return true;
							}
							break;
							
							case "c40": //so dont false split on intro cutscene.
							if (vars.H1_tickcounter.Current > 30 && vars.H1_cutsceneskip.Old == false && vars.H1_cutsceneskip.Current == true)
							{
								vars.watchers_h1fade.UpdateAll(game); 
								if (vars.H1_fadebyte.Current != 1)	//so we dont false split on reverting to intro cutscene
								{
									vars.dirtybsps_byte.Clear();
									if (settings["Loopmode"]) {vars.loading = true;}
									return true;
								}
							}
							break;

							case "d20": //keyes -- won't false split on fullpath
							vars.watchers_h1fade.UpdateAll(game);
							if (vars.H1_fadebyte.Current == 1)
							{
								if (vars.H1_fadelength.Current == 30 && vars.H1_cinematic.Old == false && vars.H1_cinematic.Current == true)
								{
									vars.dirtybsps_byte.Clear();
									if (settings["Loopmode"]) {vars.loading = true;}
									return true;
								} else if (vars.H1_fadelength.Current == 60 && vars.H1_tickcounter.Current >= (vars.H1_fadetick.Current + 56) && vars.H1_tickcounter.Old < (vars.H1_fadetick.Current + 56)) //for the dumbass who does cutscene overlap. Nice timeloss nerd :P
								{
									vars.dirtybsps_byte.Clear();
									if (settings["Loopmode"]) {vars.loading = true;}
									return true;
								}
							}
							break;
							
							case "d40": //maw - will false split on bad ending but not bridge cs or death in end fadeout
							if (vars.H1_cinematic.Old == false && vars.H1_cinematic.Current == true && vars.H1_cutsceneskip.Current == false)
							{
								vars.watchers_h1death.UpdateAll(game);
								if (!vars.H1_deathflag.Current)
								{
									vars.dirtybsps_byte.Clear();
									if (settings["Loopmode"]) {vars.loading = true;}
									return true;
								}
							}
							break;
							
							default: //don't need bsp check for levels without multiple cutscenes
							return false;
							break;
						}
					}
					else	//fullgame or anylevel
					{
						if (vars.stateindicator.Current == 44 && vars.stateindicator.Old != 44) //split on loading screen
						{
							vars.dirtybsps_byte.Clear();
							return true;
						}
					}
				}
				break;



				//Halo 2
				case 1:

				if (settings["deathcounter"])
				{
					if (vars.H2_deathflag.Current && !vars.H2_deathflag.Old)
					{
						print ("adding death");
						vars.DeathCounter += 1;
						vars.UpdateDeathCounter();
					}
					
				}

				checklevel = vars.H2_levelname.Current;
				
				if (settings["Loopmode"] && vars.H2_levelname.Current == vars.startedlevel)
				{
					if (vars.H2_IGT.Current > 10 && vars.H2_IGT.Current < 30 && vars.loopsplit == false)
					{
						vars.dirtybsps_byte.Clear();
						vars.loopsplit = true;
					}
				}
				

				if (settings["bspmode"])
				{
					if (settings["bsp_cache"])
					{
						switch (checklevel)
						{
							case "01b":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_01b, x => x == vars.H2_bspstate.Current));
							break;
							
							case "03a":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_03a, x => x == vars.H2_bspstate.Current));
							break;
							
							case "03b":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_03b, x => x == vars.H2_bspstate.Current));
							break;
							
							case "04a":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_04a, x => x == vars.H2_bspstate.Current));
							break;
							
							case "04b":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_04b, x => x == vars.H2_bspstate.Current));
							break;
							
							case "05a":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_05a, x => x == vars.H2_bspstate.Current));
							break;
							
							case "05b":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_05b, x => x == vars.H2_bspstate.Current));
							break;
							
							case "06a":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_06a, x => x == vars.H2_bspstate.Current));
							break;
							
							case "06b":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_06b, x => x == vars.H2_bspstate.Current));
							break;
							
							case "07a":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_07a, x => x == vars.H2_bspstate.Current));
							break;
							
							case "08a":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_08a, x => x == vars.H2_bspstate.Current));
							break;
							
							case "07b":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_07b, x => x == vars.H2_bspstate.Current));
							break;
							
							case "08b":
							return (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_08b, x => x == vars.H2_bspstate.Current));
							break;
						
							
							default:
							return false;
							break;
							
						}
					}
					
					switch (checklevel)
					{
						case "01b":
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_01b, x => x == vars.H2_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H2_bspstate.Current)))
						{
							if (vars.H2_bspstate.Current == 0 && !(vars.dirtybsps_byte.Contains(2)))
							{return false;} // hacky workaround for the fact that the level starts on bsp 0 and returns there later
							vars.dirtybsps_byte.Add(vars.H2_bspstate.Current);
							return true;
						}
						break;
						
						case "03a":
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_03a, x => x == vars.H2_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H2_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H2_bspstate.Current);
							return true;
						}
						break;
						
						case "03b":
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_03b, x => x == vars.H2_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H2_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H2_bspstate.Current);
							return true;
						}
						break;
						
						case "04a":
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_04a, x => x == vars.H2_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H2_bspstate.Current)))
						{
							if (vars.H2_bspstate.Current == 0 && !(vars.dirtybsps_byte.Contains(3)))
							{return false;} // hacky workaround for the fact that the level starts on bsp 0 and returns there later
							vars.dirtybsps_byte.Add(vars.H2_bspstate.Current);
							return true;
						}
						break;
						
						case "04b":
						if (vars.H2_bspstate.Current == 3 && !(vars.dirtybsps_byte.Contains(3)))
						{
							print ("e");
							vars.dirtybsps_byte.Add(3);	//prevent splitting on starting bsp
						}
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_04b, x => x == vars.H2_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H2_bspstate.Current)))
						{
							print ("a");
							if (vars.H2_bspstate.Current == 0 && (vars.dirtybsps_byte.Contains(3)))
							{
								print ("b");
							return true;} // hacky workaround for the fact that the level starts on bsp 0 and returns there later
							
							vars.dirtybsps_byte.Add(vars.H2_bspstate.Current);
							return true;
						}
						break;
						
						case "05a":
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_05a, x => x == vars.H2_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H2_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H2_bspstate.Current);
							return true;
						}
						break;
						
						case "05b":
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_05b, x => x == vars.H2_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H2_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H2_bspstate.Current);
							return true;
						}
						break;
						
						case "06a":
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_06a, x => x == vars.H2_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H2_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H2_bspstate.Current);
							return true;
						}
						break;
						
						case "06b":
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_06b, x => x == vars.H2_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H2_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H2_bspstate.Current);
							return true;
						}
						break;
						
						case "07a":
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_07a, x => x == vars.H2_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H2_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H2_bspstate.Current);
							return true;
						}
						break;
						
						case "08a":
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_08a, x => x == vars.H2_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H2_bspstate.Current)))
						{
							if (vars.H2_bspstate.Current == 0 && !(vars.dirtybsps_byte.Contains(1)))
							{return false;} // hacky workaround for the fact that the level starts on bsp 0 and returns there later
							vars.dirtybsps_byte.Add(vars.H2_bspstate.Current);
							return true;
						}
						break;
						
						case "07b":
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old && Array.Exists((byte[]) vars.splitbsp_07b, x => x == vars.H2_bspstate.Current) && !(vars.dirtybsps_byte.Contains(vars.H2_bspstate.Current)))
						{
							vars.dirtybsps_byte.Add(vars.H2_bspstate.Current);
							return true;
						}
						break;
						
						case "08b":
						//TGJ -- starts 0 and in cs, then goes to 1, then 0, then 1, then 0, then 3 (skipping 2 cos it's skippable)
						//so I have jank logic cos it does so much backtracking and backbacktracking
						if (vars.H2_bspstate.Current != vars.H2_bspstate.Old)
						{
							vars.watchers_h2xy.UpdateAll(game);
							//print ("x: " + vars.H2_xpos.Current);
							//print ("y: " + vars.H2_ypos.Current);
							
							byte checkbspstate = vars.H2_bspstate.Current;
							switch (checkbspstate)
							{
								case 1:
								if (!(vars.dirtybsps_byte.Contains(1)) && vars.H2_xpos.Current > -2 && vars.H2_xpos.Current < 5 && vars.H2_ypos.Current > -35 && vars.H2_ypos.Current < -15)
								{
									vars.dirtybsps_byte.Add(1);
									//print ("first");
									return true;
								} else if (!(vars.dirtybsps_byte.Contains(21)) && (vars.dirtybsps_byte.Contains(10))  && vars.H2_xpos.Current > 15 && vars.H2_xpos.Current < 25 && vars.H2_ypos.Current > 15 && vars.H2_ypos.Current < 30)
								{
									vars.dirtybsps_byte.Add(21);
									//print ("third");
									return true;
								}
								
								break;
								
								case 0:
								if (!(vars.dirtybsps_byte.Contains(10)) && vars.H2_xpos.Current > -20 && vars.H2_xpos.Current < -10 && vars.H2_ypos.Current > 20 && vars.H2_ypos.Current < 30)
								{
									vars.dirtybsps_byte.Add(10);
									//print ("second");
									return true;
								} else if (!(vars.dirtybsps_byte.Contains(20)) && (vars.dirtybsps_byte.Contains(21))  && vars.H2_xpos.Current > 45 && vars.H2_xpos.Current < 55 && vars.H2_ypos.Current > -5 && vars.H2_ypos.Current < 10)
								{
									//print ("fourth");
									vars.dirtybsps_byte.Add(20);
									return true;
								}
								break;
								
								case 3:
								if (!(vars.dirtybsps_byte.Contains(3)))
								{
									vars.dirtybsps_byte.Add(3);
									return true;
								}
								break;
								
								default:
								break;
							}
						} 
						break;
					
						default:
						break;
					}
				}


				if (!settings["ILmode"]) //Split on loading screen
				{
					if (vars.stateindicator.Current == 44 && vars.stateindicator.Old != 44) 
					{
						vars.dirtybsps_byte.Clear();
						return true;
					}
				}
				break;
				


				//Halo 3
				case 2:

				if (settings["deathcounter"])
				{
					if (vars.H3_deathflag.Current && !vars.H3_deathflag.Old)
					{
						print ("adding death");
						vars.DeathCounter += 1;
						vars.UpdateDeathCounter();
					}
				}
				
				
				checklevel = vars.H3_levelname.Current;
				
				if (settings["Loopmode"] && vars.H3_levelname.Current == vars.startedlevel && vars.loopsplit == false)
				{
					if (vars.IGT_float.Current > 0.167 && vars.IGT_float.Current < 0.5)
					{
						vars.loopsplit = true;
						vars.dirtybsps_long.Clear();
					}
				}
					
				
				if (settings["bspmode"])
				{
					if (settings["bsp_cache"])
					{
						switch (checklevel)
						{
							case "010":
							return (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_010, x => x == vars.H3_bspstate.Current));
							break;
							
							case "020":
							return (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_020, x => x == vars.H3_bspstate.Current));
							break;
							
							case "030":
							return (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_030, x => x == vars.H3_bspstate.Current));
							break;
							
							case "040":
							return (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_040, x => x == vars.H3_bspstate.Current));
							break;
							
							case "050":
							return (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_050, x => x == vars.H3_bspstate.Current));
							break;
							
							case "070":
							return (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_070, x => x == vars.H3_bspstate.Current));
							break;
							
							case "100":
							return (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_100, x => x == vars.H3_bspstate.Current));
							break;
							
							case "110":
							return (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_110, x => x == vars.H3_bspstate.Current));
							break;
							
							case "120":
							return (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_120, x => x == vars.H3_bspstate.Current));
							break;
							
							
							default:
							return false;
							break;
						}
					}
					
					switch (checklevel)
					{
						case "010":
						if (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_010, x => x == vars.H3_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H3_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H3_bspstate.Current);
							return true;
						}
						break;
						
						case "020":
						if (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_020, x => x == vars.H3_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H3_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H3_bspstate.Current);
							return true;
						}
						break;
						
						case "030":
						if (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_030, x => x == vars.H3_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H3_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H3_bspstate.Current);
							return true;
						}
						break;
						
						case "040":
						if (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_040, x => x == vars.H3_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H3_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H3_bspstate.Current);
							return true;
						}
						break;
						
						case "050":
						if (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_050, x => x == vars.H3_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H3_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H3_bspstate.Current);
							return true;
						}
						break;
						
						case "070":
						if (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_070, x => x == vars.H3_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H3_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H3_bspstate.Current);
							return true;
						}
						break;
						
						
						case "100":
						if (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_100, x => x == vars.H3_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H3_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H3_bspstate.Current);
							return true;
						}
						break;
						
						case "110":
						if (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_110, x => x == vars.H3_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H3_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H3_bspstate.Current);
							return true;
						}
						break;
						
						case "120":
						if (vars.H3_bspstate.Current != vars.H3_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_120, x => x == vars.H3_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H3_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H3_bspstate.Current);
							return true;
						}
						break;
						
						default:
						break;
					} 
				} 
				
				if (!settings["ILmode"])	//IL end split
				{
					if (vars.stateindicator.Current == 44 && vars.stateindicator.Old != 44)
					{
						vars.dirtybsps_long.Clear();
						return true;
					}
				} 
				break;



				//Halo 4
				case 3:

				//Death counter code goes here if we ever bother to add it

				checklevel = vars.H4_levelname.Current;
				
				if (settings["Loopmode"] && vars.H4_levelname.Current == vars.startedlevel)
				{
					if (vars.IGT_float.Current > 0.167 && vars.IGT_float.Current < 0.5 && vars.loopsplit == false)
					{
						vars.loopsplit = true;
						vars.dirtybsps_long.Clear();
					}
				}
				
				
				if (settings["bspmode"])
				{
					
					if (settings["bsp_cache"])
					{
						switch (checklevel)
						{
							case "m10":
							return (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m10, x => x == vars.H4_bspstate.Current));
							break;
							
							case "m02":
							return (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m02, x => x == vars.H4_bspstate.Current));
							break;
							
							case "m30":
							return (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m30, x => x == vars.H4_bspstate.Current));
							break;
							
							case "m40":
							return (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m40, x => x == vars.H4_bspstate.Current));
							break;
							
							case "m50":
							return (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m50, x => x == vars.H4_bspstate.Current));
							break;
							
							case "m60":
							return (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m60, x => x == vars.H4_bspstate.Current));
							break;
							
							case "m70":
							return (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m70, x => x == vars.H4_bspstate.Current));
							break;
							
							case "m80":
							return (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m80, x => x == vars.H4_bspstate.Current));
							break;
							
							case "m90":
							return (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m90, x => x == vars.H4_bspstate.Current));
							break;
							
							
							default:
							return false;
							break;
							
						}	
					}
					
					switch (checklevel)
					{
						case "m10":
						if (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m10, x => x == vars.H4_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H4_bspstate.Current)))
						{
							//reset bug fix
							//actually can't think of a good way to fix it rn
							
							vars.dirtybsps_long.Add(vars.H4_bspstate.Current);
							return true;
						}
						break;
						
						case "m02":
						if (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m02, x => x == vars.H4_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H4_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H4_bspstate.Current);
							return true;
						}
						break;
						
						case "m30":
						if (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m30, x => x == vars.H4_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H4_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H4_bspstate.Current);
							return true;
						}
						break;
						
						case "m40":
						if (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m40, x => x == vars.H4_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H4_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H4_bspstate.Current);
							return true;
						}
						break;
						
						case "m50":
						if (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m50, x => x == vars.H4_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H4_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H4_bspstate.Current);
							return true;
						}
						break;
						
						case "m60":
						if (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m60, x => x == vars.H4_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H4_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H4_bspstate.Current);
							return true;
						}
						break;
						
						
						case "m70":
						if (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m70, x => x == vars.H4_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H4_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H4_bspstate.Current);
							return true;
						}
						break;
						
						case "m80":
						if (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m80, x => x == vars.H4_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H4_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H4_bspstate.Current);
							return true;
						}
						break;
						
						case "m90":
						if (vars.H4_bspstate.Current != vars.H4_bspstate.Old && !Array.Exists((ulong[]) vars.nosplitbsp_m90, x => x == vars.H4_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.H4_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.H4_bspstate.Current);
							return true;
						}
						break;
						
						default:
						break;
					} 
				} 
				break;
				


				case 5: //ODST

				//Death Counter
				if (settings["deathcounter"])
				{
					if (vars.ODST_deathflag.Current && !vars.ODST_deathflag.Old)
					{
						print ("adding death");
						vars.DeathCounter += 1;
						vars.UpdateDeathCounter();
					}
				}

				if (vars.ODST_levelnameBad.Current.Length > 1) //Check that the level name actually exists in memory so a bunch of errors dont get spat out
				{
					if (vars.ODST_levelnameBad.Current[1] == '\\') {checklevel = vars.ODST_levelnameBad2.Current;}
					else {checklevel = vars.ODST_levelnameBad.Current;}
				}
				else {checklevel = vars.ODST_levelnameBad2.Current;} //Streets are not a real level :)


				if (settings["Loopmode"] && checklevel == vars.startedlevel && vars.loopsplit == false)
				{
					if (vars.IGT_float.Current > 0.167 && vars.IGT_float.Current < 0.5)
					{
						vars.loopsplit = true;
						vars.dirtybsps_long.Clear();
					}
				}
				
				
				if (settings["bspmode"])
				{
					
					if (settings["bsp_cache"])
					{
						switch (checklevel)
						{
							case "h100":
							return (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_h100, x => x == vars.ODST_bspstate.Current));
							break;
							
							case "sc10":
							return (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_sc10, x => x == vars.ODST_bspstate.Current));
							break;
							
							case "sc11":
							if (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_sc11, x => x == vars.ODST_bspstate.Current))
							{
								vars.watchers_odst.UpdateAll(game); 
								if (vars.IGT_float.Current > 0.5)
								{
									return true;
								}
							}
							break;
							
							case "sc13":
							return (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_sc13, x => x == vars.ODST_bspstate.Current));
							break;
							
							case "sc12":
							return (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_sc12, x => x == vars.ODST_bspstate.Current));
							break;
							
							case "sc14":
							return (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_sc14, x => x == vars.ODST_bspstate.Current));
							break;
							
							case "sc15":
							return (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_sc15, x => x == vars.ODST_bspstate.Current));
							break;
							
							case "l200":
							return (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_l200, x => x == vars.ODST_bspstate.Current));
							break;
							
							case "l300":
							return (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_l300, x => x == vars.ODST_bspstate.Current));
							break;
							
							default:
							return false;
							break;
							
						}
						
					}
					
					switch (checklevel)
					{
						case "h100":
						if (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_h100, x => x == vars.ODST_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.ODST_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.ODST_bspstate.Current);
							return true;
						}
						break;
						
						case "sc10":
						if (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_sc10, x => x == vars.ODST_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.ODST_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.ODST_bspstate.Current);
							return true;
						}
						break;
						
						case "sc11":
						if (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_sc11, x => x == vars.ODST_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.ODST_bspstate.Current)))
						{
							vars.watchers_odst.UpdateAll(game); 
							if (vars.IGT_float.Current > 0.5)
							{
								vars.dirtybsps_long.Add(vars.ODST_bspstate.Current);
								return true;
							}
						}
						break;
						
						case "sc13":
						if (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_sc13, x => x == vars.ODST_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.ODST_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.ODST_bspstate.Current);
							return true;
						}
						break;
						
						case "sc12":
						if (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_sc12, x => x == vars.ODST_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.ODST_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.ODST_bspstate.Current);
							return true;
						}
						break;
						
						case "sc14":
						if (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_sc14, x => x == vars.ODST_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.ODST_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.ODST_bspstate.Current);
							return true;
						}
						break;
						
						case "sc15":
						if (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_sc15, x => x == vars.ODST_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.ODST_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.ODST_bspstate.Current);
							return true;
						}
						break;
						
						case "l200":
						if (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_l200, x => x == vars.ODST_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.ODST_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.ODST_bspstate.Current);
							return true;
						}
						break;
						
						case "l300":
						if (vars.ODST_bspstate.Current != vars.ODST_bspstate.Old && Array.Exists((ulong[]) vars.splitbsp_l300, x => x == vars.ODST_bspstate.Current) && !(vars.dirtybsps_long.Contains(vars.ODST_bspstate.Current)))
						{
							vars.dirtybsps_long.Add(vars.ODST_bspstate.Current);
							return true;
						}
						break;
						
						default:
						break;
					} 
				} 
				break;
				
				
				
				//Reach
				case 6:

				//Death counter check
				if (settings["deathcounter"])
				{
					if (vars.HR_deathflag.Current && !vars.HR_deathflag.Old)
					{
						print ("adding death");
						vars.DeathCounter += 1;
						vars.UpdateDeathCounter();
					}
				}

				checklevel = vars.HR_levelname.Current;
				
				if (settings["Loopmode"] && vars.HR_levelname.Current == vars.startedlevel)
				{
					if (vars.IGT_float.Current > 0.167 && vars.IGT_float.Current < 0.5 && vars.loopsplit == false)
					{
						vars.loopsplit = true;
						vars.dirtybsps_int.Clear();
					}
				}
				
				if (settings["bspmode"])
				{
					if (settings["bsp_cache"])
					{
						switch (checklevel)
						{
							case "m10":
							return (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m10, x => x == vars.HR_bspstate.Current));
							break;
							
							case "m20":
							return (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m20, x => x == vars.HR_bspstate.Current));
							break;
							
							case "m30":
							return (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m30, x => x == vars.HR_bspstate.Current));
							break;
							
							case "m35":
							return (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m35, x => x == vars.HR_bspstate.Current));
							break;
							
							case "m45":
							return (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m45, x => x == vars.HR_bspstate.Current));
							break;
							
							case "m50":
							return (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m50, x => x == vars.HR_bspstate.Current));
							break;
							
							case "m60":
							return (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m60, x => x == vars.HR_bspstate.Current));
							break;
							
							case "m70":
							return (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m70, x => x == vars.HR_bspstate.Current));
							break;
							
							
							default:
							break;
						}
					}
					
					
					switch (checklevel)
					{
						case "m10":
						/* 					if (vars.HR_bspstate.Current != vars.HR_bspstate.Old)
							{
							print ("new: " + vars.HR_bspstate.Current);
							print ("old: " + vars.HR_bspstate.Old);
							
							foreach (uint item in vars.dirtybsps_int) // Loop through List with foreach
							{
							print ("dirty: " + item);
							}
						} */
						
						if (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m10, x => x == vars.HR_bspstate.Current) && !(vars.dirtybsps_int.Contains(vars.HR_bspstate.Current)))
						{
							vars.dirtybsps_int.Add(vars.HR_bspstate.Current);
							return true;
						}
						break;
						
						case "m20":
						if (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m20, x => x == vars.HR_bspstate.Current) && !(vars.dirtybsps_int.Contains(vars.HR_bspstate.Current)))
						{
							vars.dirtybsps_int.Add(vars.HR_bspstate.Current);
							return true;
						}
						break;
						
						case "m30":
						if (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m30, x => x == vars.HR_bspstate.Current) && !(vars.dirtybsps_int.Contains(vars.HR_bspstate.Current)))
						{
							vars.dirtybsps_int.Add(vars.HR_bspstate.Current);
							return true;
						}
						break;
						
						case "m35":
						if (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m35, x => x == vars.HR_bspstate.Current) && !(vars.dirtybsps_int.Contains(vars.HR_bspstate.Current)))
						{
							vars.dirtybsps_int.Add(vars.HR_bspstate.Current);
							return true;
						}
						break;
						
						case "m45":
						if (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m45, x => x == vars.HR_bspstate.Current) && !(vars.dirtybsps_int.Contains(vars.HR_bspstate.Current)))
						{
							vars.dirtybsps_int.Add(vars.HR_bspstate.Current);
							return true;
						}
						break;
						
						case "m50":
						if (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m50, x => x == vars.HR_bspstate.Current) && !(vars.dirtybsps_int.Contains(vars.HR_bspstate.Current)))
						{
							vars.dirtybsps_int.Add(vars.HR_bspstate.Current);
							return true;
						}
						break;
						
						case "m60":
						if (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m60, x => x == vars.HR_bspstate.Current) && !(vars.dirtybsps_int.Contains(vars.HR_bspstate.Current)))
						{
							vars.dirtybsps_int.Add(vars.HR_bspstate.Current);
							return true;
						}
						break;
						
						case "m70":
						if (vars.HR_bspstate.Current != vars.HR_bspstate.Old && Array.Exists((uint[]) vars.splitbsp_m70, x => x == vars.HR_bspstate.Current) && !(vars.dirtybsps_int.Contains(vars.HR_bspstate.Current)))
						{
							vars.dirtybsps_int.Add(vars.HR_bspstate.Current);
							return true;
						}
						break;
						
						
						default:
						break;
					}
				}
				break;
			}
		}
	}
}


reset
{
	if ((settings["ILmode"])&& (!(settings["Loopmode"])) && vars.menuindicator.Current != 7 && timer.CurrentPhase != TimerPhase.Ended)
	{
		return true;
	}
	
	if ((!(settings["Loopmode"])) && vars.menuindicator.Current == 7)
	{
		byte test = vars.gameindicator.Current;
		switch (test)
		{
			//H1
			case 0:
			if (settings["ILmode"] || settings["anylevel"])
			{
				if (vars.H1_levelname.Current == vars.startedlevel && vars.startedgame == 0 && timer.CurrentPhase != TimerPhase.Ended)
				{
					return ((vars.H1_IGT.Current < vars.H1_IGT.Old && vars.H1_IGT.Current < 10) || (vars.stateindicator.Current == 44 && vars.H1_IGT.Current == 0));
				} 
			}
			else
			{
				if (vars.H1_levelname.Current == "a10" && vars.startedgame == 0 && timer.CurrentPhase != TimerPhase.Ended)
				{
					return ((vars.H1_IGT.Current < vars.H1_IGT.Old && vars.H1_IGT.Current < 10) || (vars.stateindicator.Current != 44 && vars.stateindicator.Old == 44 && vars.H1_tickcounter.Current < 60));
				} 
			}
			break;
			
			//H2
			case 1:
			if (settings["ILmode"] || settings["anylevel"])
			{
				if (vars.H2_levelname.Current == vars.startedlevel && vars.startedgame == 1 && timer.CurrentPhase != TimerPhase.Ended)
				{				
					return ((vars.H2_IGT.Current < vars.H2_IGT.Old && vars.H2_IGT.Current < 10) || (vars.stateindicator.Current == 44 && vars.H2_IGT.Current == 0)); 
				}
			}
			else
			{
				if ((vars.H2_levelname.Current == "01a" || (vars.H2_levelname.Current == "01b" && vars.startedlevel != "01a")) && vars.startedgame == 1 && timer.CurrentPhase != TimerPhase.Ended)
				{
					return ((vars.H2_IGT.Current < vars.H2_IGT.Old && vars.H2_IGT.Current < 10) || (vars.stateindicator.Current != 44 && vars.stateindicator.Old == 44 && vars.H2_tickcounter.Current < 60));
				}
			}
			break;
			
			//H3
			case 2:
			if (vars.startedgame == 2 && timer.CurrentPhase != TimerPhase.Ended)
			{
				if (settings["ILmode"])
				{
					return (vars.H3_levelname.Current == vars.startedlevel && vars.IGT_float.Current < vars.IGT_float.Old && vars.IGT_float.Current < 0.167);
				}
				else
				{
					if (settings["anylevel"]) //reset on all levels
					{
						return (vars.H3_levelname.Current == vars.startedlevel && vars.H3_theatertime.Current > 0 && vars.H3_theatertime.Current < 15);
					}
					return ((vars.H3_levelname.Current == "005" || vars.H3_levelname.Current == "010") && vars.H3_theatertime.Current > 0 && vars.H3_theatertime.Current < 15);	
				}
			} 
			break;
			
			//H4
			case 3:
			if (settings["ILmode"] || settings["anylevel"])
			{
				if (vars.H4_levelname.Current == vars.startedlevel && vars.startedgame == 3 && timer.CurrentPhase != TimerPhase.Ended)
				{
					return ((vars.IGT_float.Current < vars.IGT_float.Old && vars.IGT_float.Current < 0.167) || (vars.stateindicator.Current == 44 && vars.IGT_float.Current == 0));
				}
			}
			else
			{
				if (vars.H4_levelname.Current == "m10" && vars.startedgame == 3 && timer.CurrentPhase != TimerPhase.Ended)
				{
					return ((vars.IGT_float.Current < vars.IGT_float.Old && vars.IGT_float.Current < 0.167) || (vars.stateindicator.Current == 44 && vars.IGT_float.Current == 0));
				}
			}
			break;
			
			//ODST
			case 5:
			if (settings["anylevel"])
			{
				if (vars.ODST_levelnameBad.Current.Length > 1) //Check that the level name actually exists in memory so a bunch of errors dont get spat out
				{
					if (vars.ODST_levelnameBad2.Current == vars.startedlevel && (vars.ODST_levelnameBad.Current[1] == '\\' || vars.ODST_levelnameBad2.Current == "c100") && vars.startedgame == 5 && timer.CurrentPhase != TimerPhase.Ended)
					{
						return ((vars.IGT_float.Current < vars.IGT_float.Old && vars.IGT_float.Current < 0.167) || (vars.stateindicator.Current == 44 && vars.IGT_float.Current == 0));
					}
				}
			}
			else if (settings["ILmode"])
			{
				if (vars.ODST_levelnameBad2.Current == vars.startedlevel && vars.startedgame == 5 && timer.CurrentPhase != TimerPhase.Ended)
				{
					return (vars.IGT_float.Current < vars.IGT_float.Old && vars.IGT_float.Current < 0.167);
				}
			}
			else
			{
				if (vars.ODST_levelnameBad2.Current == "c100" && vars.startedgame == 5 && timer.CurrentPhase != TimerPhase.Ended)
				{
					return ((vars.IGT_float.Current < vars.IGT_float.Old && vars.IGT_float.Current < 0.167) || (vars.stateindicator.Current == 44 && vars.IGT_float.Current == 0));
				}
			}
			break;
			
			//Reach
			case 6:
			if (settings["ILmode"] || settings["anylevel"])
			{
				if (vars.HR_levelname.Current == vars.startedlevel && vars.startedgame == 6 && timer.CurrentPhase != TimerPhase.Ended)
				{
					return ((vars.IGT_float.Current < vars.IGT_float.Old && vars.IGT_float.Current < 0.167) || (vars.stateindicator.Current == 44 && vars.IGT_float.Current == 0));
				}
			}
			else
			{
				if (vars.HR_levelname.Current == "m10" && vars.startedgame == 6 && timer.CurrentPhase != TimerPhase.Ended)
				{
					return ((vars.IGT_float.Current < vars.IGT_float.Old && vars.IGT_float.Current < 0.167) || (vars.stateindicator.Current == 44 && vars.IGT_float.Current == 0));
				}
			}
			break;
		}
	}
}

isLoading
{
	byte test = vars.gameindicator.Current;
	
	if (vars.multigamepause) {return true;}
	
	if (settings["menupause"] && (vars.stateindicator.Current == 44 || vars.menuindicator.Current != 7)) {return true;}
	
	//also should prolly code load removal to work in case of restart/crash
	switch (test)
	{
		case 0: //halo 1
		if (settings["IGTmode"]) {return true;}
		else return vars.loading;
		break;
		
		case 1: //halo 2
		if ((settings["ILmode"] && vars.H2_levelname.Current != "01a") || settings["IGTmode"]) {return true;}
		else
		{
			//Graphics swap load pausing. Just leaving it here for now unless issues start happening
			if (vars.loading == false && vars.H2_graphics.Current == 1 && vars.stateindicator.Current == 255)
			{
				if ((vars.H2_tickcounter.Current == vars.oldtick) || (vars.H2_tickcounter.Current == vars.oldtick + 1)) {return true;} else {vars.oldtick = -2;}
				if (vars.H2_graphics.Old == 0) {vars.oldtick = vars.H2_tickcounter.Current;}
			}
			return vars.loading;
		}
		break;
		
		case 2:
		case 3:
		case 5:
		case 6:
		return true;
		break;
	}
}


gameTime
{
	if (vars.multigamepause && vars.forcesplit == false)
	{
		if (vars.multigametime != timer.CurrentTime.GameTime)
		{
			vars.ingametime = 0;
			vars.multigametime = timer.CurrentTime.GameTime;
		}
		return;
	}
	else if (vars.menuindicator.Current == 7 && (settings["IGTmode"] || !(vars.gameindicator.Current == 0 || (vars.gameindicator.Current == 1 && !settings["ILmode"]))))
	{
		return vars.gametime;
	}
}


exit
{
	//timer.IsGameTimePaused = false; //unpause the timer on gamecrash UNLESS it was paused for multi-game-pause option.
}