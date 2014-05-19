//   _____ _____   __          ___   _  _____ _    _ ______ _      ______ 
//  / ____|  __ \ /\ \        / / \ | |/ ____| |  | |  ____| |    |  ____|
// | (___ | |__) /  \ \  /\  / /|  \| | (___ | |__| | |__  | |    | |__   
//  \___ \|  ___/ /\ \ \/  \/ / | . ` |\___ \|  __  |  __| | |    |  __|  
//  ____) | |  / ____ \  /\  /  | |\  |____) | |  | | |____| |____| |     
// |_____/|_| /_/    \_\/  \/   |_| \_|_____/|_|  |_|______|______|_|     
//
//	Spawn Shelf San Andreas: Multiplayer Role Play Gamemode Script v.0.01
//
//	Created by: 	Ben Cherrington
//	Special Thanks: David Engles
//					Adam Smith

//-----------------------------------------INCLUDES-----------------------------------------//
#include <a_samp> //Without this, we won't be able to use all samp functions/callbacks.
#include <a_mysql> //This handles all MySQL stuff.
#include <zcmd> //This is ZCMD this is a great little command processor.
#include <foreach> //This is foreach by YSI.
#include <sscanf2> //this is sscanf2 by YSI.

//-----------------------------------------DEFINES-----------------------------------------//

#define	COLOR_PURPLE	0xC2A2DAAA
#define	COLOR_YELLOW	0xFFFFCCAA
#define	COLOR_WHITE		0xFFFFFFAA

#define	DIALOG_REGISTER	6287
#define	DIALOG_LOGIN	6288

#define SQL_HOST	"localhost"
#define SQL_USER	"root"
#define SQL_PASS	""
#define SQL_DB		"hacserver"

new bool:oocToggle[MAX_PLAYERS];

static mysql, Name[MAX_PLAYERS][24], IP[MAX_PLAYERS][16];

enum pInfo
{
	ID,
	Password,
	Admin,
	VIP,
	Money,
	Float:PosX,
	Float:PosY,
	Float:PosZ,
	Float:Health,
	Skin
}

new PlayerInfo[MAX_PLAYERS][pInfo];

//-----------------------------------------STOCKS-----------------------------------------//

//This stock takes a given string, searches for a "_" and replaces it with " ".
stock strreplace(string[], find, replace)
{
	for(new i=0; string[i]; i++)
	{
		if(string[i] == find)
		{
			string[i] = replace;
		}
	}
}

//This stock takes a given player ID, gets their player name, then using the above stock it replaces the "_" with a " " and returns the result.
stock GetName(playerid)
{
    new name[24];
    GetPlayerName(playerid, name, sizeof(name));
    strreplace(name, '_', ' ');
    return name;
}

//This stock takes the given radius, player ID, string and colour and displays the message only to players within the radius.
stock ProxiDetector(Float:radi, playerid, string[], color)
{
	new Float:x,Float:y,Float:z;
	GetPlayerPos(playerid,x,y,z);
	foreach(Player,i)
	{
		if(IsPlayerInRangeOfPoint(i,radi,x,y,z))
		{
			SendClientMessage(i,color,string);
		}
	}
}

//This stock only displays OOC chat to players who have it enabled.
stock oocChat(color, string[])
{
	foreach(Player,i)
	{
		if(!oocToggle[i])
		{
		SendClientMessage(i,color,string);
		}
	}
}

//-----------------------------------------CALLBACKS-----------------------------------------//

//This is the main function which executes when the server loads, right now it just prints the gamemode version to the console.
main()
{
	print("\n-------------------------------------");
	print(" This is the WIP HAC Gamemode v0.001");
	print("-------------------------------------\n");
}

//This runs when the gamemode script is first loaded, so far it disables the default GTA yellow interior markers, disables stunt bonus' and removes markers.
public OnGameModeInit()
{
	mysql_log(LOG_ERROR | LOG_WARNING | LOG_DEBUG);
    mysql = mysql_connect(SQL_HOST, SQL_USER, SQL_DB, SQL_PASS);
    if(mysql_errno(mysql) != 0) print("Could not connect to database!");
	
	DisableInteriorEnterExits();
	EnableStuntBonusForAll(0);
	ShowPlayerMarkers(0);
	SetGameModeText("SS-SAMP-RP");
	return 1;
}

//This runs when ever a player connects. Right now it sets their name to white, and toggles the OOC chat to "on".
public OnPlayerConnect(playerid)
{
	TogglePlayerSpectating(playerid, true);
	SetPlayerFacingAngle(playerid,224.2720);
	SetPlayerCameraPos(playerid, 1252.1219,-778.5645,109.4652);
	SetPlayerCameraLookAt(playerid,1252.1219,-778.5645,109.4652);
	SetPlayerColor(playerid, COLOR_WHITE);
	
	new query[128];
	GetPlayerName(playerid, Name[playerid], 24);
	GetPlayerIp(playerid, IP[playerid], 16);
	mysql_format(mysql, query, sizeof(query), "SELECT `Password`, `ID` FROM `players` WHERE `Username` = '%e' LIMIT 1", Name[playerid]);
    mysql_tquery(mysql, query, "OnAccountCheck", "i", playerid);
	return 1;
}

forward OnAccountCheck(playerid);

public OnAccountCheck(playerid)
{
	new rows, fields;
	cache_get_data(rows, fields, mysql);
	if(rows)
	{
		cache_get_field_content(0, "Password", PlayerInfo[playerid][Password], mysql, 129);
		PlayerInfo[playerid][ID] = cache_get_field_content_int(0, "ID");
		printf("%s", PlayerInfo[playerid][Password]);
		ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "In order to play, you need to login.", "Login", "Quit");
	}
	else
	{
		ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", "In order to play, you need to register.", "Register", "Quit");
	}
	return 1;
}

forward OnAccountLoad(playerid);
forward OnAccountRegister(playerid);

public OnAccountLoad(playerid)
{
	PlayerInfo[playerid][Admin] = cache_get_field_content_int(0, "Admin");
	PlayerInfo[playerid][VIP] = cache_get_field_content_int(0, "VIP");
	PlayerInfo[playerid][Money] = cache_get_field_content_int(0, "Money");
	PlayerInfo[playerid][PosX] = cache_get_field_content_float(0, "PosX");
	PlayerInfo[playerid][PosY] = cache_get_field_content_float(0, "PosY");
	PlayerInfo[playerid][PosZ] = cache_get_field_content_float(0, "PosZ");
	PlayerInfo[playerid][Health] = cache_get_field_content_float(0, "Health");
	PlayerInfo[playerid][Skin] = cache_get_field_content_int(0, "Skin");
	
	SetSpawnInfo(playerid, 0, PlayerInfo[playerid][Skin], PlayerInfo[playerid][PosX], PlayerInfo[playerid][PosY], PlayerInfo[playerid][PosZ], 0, 0, 0, 0, 0, 0, 0);
	GivePlayerMoney(playerid, PlayerInfo[playerid][Money]);
	SetPlayerHealth(playerid, PlayerInfo[playerid][Health]);
	SendClientMessage(playerid, -1, "Successfully logged in!");
	TogglePlayerSpectating(playerid, false);
	return 1;
}

public OnAccountRegister(playerid)
{
	PlayerInfo[playerid][ID] = cache_insert_id();
	printf("New account registered. ID: %d", PlayerInfo[playerid][ID]);
	return OnAccountLoad(playerid);
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_LOGIN:
		{
			if(!response) Kick(playerid);
			new query[100];
			if(!strcmp(inputtext, PlayerInfo[playerid][Password]))
			{
				mysql_format(mysql, query, sizeof(query), "SELECT * FROM `players` WHERE `Username` = '%e' LIMIT 1", Name[playerid]);
				mysql_tquery(mysql, query, "OnAccountLoad", "i", playerid);
			}
			else
			{
				ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "In order to play, you need to login.\nWrong Password!", "Login", "Quit");
			}
		}
		case DIALOG_REGISTER:
		{
			if(!response) return Kick(playerid);
			if(strlen(inputtext) < 6) return ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_PASSWORD, "Register", "In order to play, you need to register.\nYour password must be at least 6 characters long!", "Register", "Quit");
			new query[300];
			mysql_format(mysql, query, sizeof(query), "INSERT INTO `players` (`Username`, `Password`, `IP`, `Admin`, `VIP`, `Money`, `PosX`, `PosY`, `PosZ`, `Health`, `Skin`) VALUES ('%e', '%s', '%s', 0, 0, 0, 1317.179809, -915.674011, 37.903450, 100, 0)", Name[playerid], inputtext, IP[playerid]);
			mysql_tquery(mysql, query, "OnAccountRegister", "i", playerid);
		}
	}
	return 1;
}

//This executes when ever a player types into the chat box when it's not a command.
public OnPlayerText(playerid, text[])
{
	new message[128];
	format(message, sizeof(message), "%s says: %s", GetName(playerid), text);
	ProxiDetector(30.0, playerid, message, -1);
	return 0;
}

//This executes on player disconnect.
public OnPlayerDisconnect(playerid, reason)
{
	new query[168], Float:pos[3], Float:health;
	GetPlayerHealth(playerid, health);
	GetPlayerPos(playerid, pos[0], pos[1], pos[2]);
	mysql_format(mysql, query, sizeof(query), "UPDATE `players` SET `Admin`=%d, `VIP`=%d, `Money`=%d, `PosX`=%f, `PosY`=%f, `PosZ`=%f, `Health`=%f, `Skin`=%d WHERE `ID`=%d", PlayerInfo[playerid][Admin], PlayerInfo[playerid][VIP], PlayerInfo[playerid][Money], pos[0], pos[1], pos[2], health, PlayerInfo[playerid][Skin], PlayerInfo[playerid][ID]);
	mysql_tquery(mysql, query, "", "");
	return 1;
}

//This executes when the player spawns, I use it to set their location for debugging.
public OnPlayerSpawn(playerid)
{
	SetPlayerSkin(playerid, PlayerInfo[playerid][Skin]);
	SetPlayerPos(playerid, PlayerInfo[playerid][PosX], PlayerInfo[playerid][PosY], PlayerInfo[playerid][PosZ]);
	return 1;
}

//-----------------------------------------COMMANDS-----------------------------------------//

//This command allows the user to enter /skin [sinid] to temp set their skin in-game. [DEBUG]
CMD:skin(playerid, params[])
{
	new skin[10];
	if(sscanf(params, "s[100]", skin))
	{
		SendClientMessage(playerid, -1, "USAGE: /skin [skin id]");
		return 1;
	}
	else
	{
		new string[128], skinid = strval(skin);
		if(skinid < 299)
		{
			format(string, sizeof(string), "Your skin has been set to ID:%s.", skinid);
			SetPlayerSkin(playerid, skinid);
			PlayerInfo[playerid][Skin] = skinid;
		}
		else
		{
			SendClientMessage(playerid, -1, "This is not a valid skin ID.");
			return 1;
		}
	}
	return 1;
}

//This command lets the user spawn a motorbike on their current location. [DEBUG]
CMD:bike(playerid, params[])
{
	new Float:vehicle[3];
	GetPlayerPos(playerid, vehicle[0], vehicle[1], vehicle[2]);
	CreateVehicle(468, vehicle[0], vehicle[1], vehicle[2], 90, 0, 1, -1);
	return 1;
}

//Like the /bike command this spawns a helicopter. [DEBUG]
CMD:heli(playerid, params[])
{
	new Float:vehicle[3];
	GetPlayerPos(playerid, vehicle[0], vehicle[1], vehicle[2]);
	CreateVehicle(425, vehicle[0], vehicle[1], vehicle[2], 90, 0, 1, -1);
	return 1;
}

//This command allows the user to emote using /me [action] to produce "* Player_Name performs action. *".
CMD:me(playerid, params[])
{
	new string[128], action[100];
	if(sscanf(params, "s[100]", action))
	{
		SendClientMessage(playerid, -1, "USAGE: /me [action]");
		return 1;
	}
	else
	{
		format(string, sizeof(string), "* %s %s *", GetName(playerid), action);
		ProxiDetector(30.0, playerid, string, COLOR_PURPLE);
	}
	return 1;
}

//This command allows the user to shout using /shout [message].
CMD:shout(playerid, params[])
{
    new string[128], shout[100];
    if(sscanf(params, "s[100]", shout))
    {
        SendClientMessage(playerid, -1, "USAGE: /(s)hout [message]");
        return 1;
    }
    else
    {
        format(string, sizeof(string), "%s shouts: %s!",GetName(playerid),shout);
        ProxiDetector(50.0, playerid, string, -1);
    }
    return 1;
}
//This command simply allows the user to use /s rather than /shout to execute the above command.
CMD:s(playerid, params[]) return cmd_shout(playerid, params);

//This command allows the user to talk to others in Out Of Character chat using /ooc [message].
CMD:ooc(playerid, params[])
{
	if(!oocToggle[playerid])
	{
		new string[128], outofcharacter[100];
		if(sscanf(params, "s[100]", outofcharacter))
		{
			SendClientMessage(playerid, -1, "USAGE: /(o)oc [message]");
			return 1;
		}
		else
		{
		format(string, sizeof(string), "((%s: %s))", GetName(playerid), outofcharacter);
		oocChat(COLOR_YELLOW, string);
		}
	}
	else
	{
	SendClientMessage(playerid, -1, "You have disabled OOC. Use /toggleooc to enable.");
	}
	return 1;
}
//This command allows the user to use the above command simply with /o [message].
CMD:o(playerid, params[]) return cmd_ooc(playerid, params);

//This command uses the same system as local chat, but to talk in Out Of Character chat locally.
CMD:b(playerid, params[])
{
	new string[128], localooc[100];
	if(sscanf(params, "s[100]", localooc))
	{
		SendClientMessage(playerid, -1, "USAGE: /b [message]");
		return 1;
	}
	else
	{
		format(string, sizeof(string), "((%s says: %s))", GetName(playerid), localooc);
		ProxiDetector(30.0, playerid, string, COLOR_YELLOW);
	}
	return 1;
}

//This command toggles the users ability to both see and type into the OOC chat.
CMD:toggleooc(playerid, params[])
{
	new status[10], string[128];
	if(oocToggle[playerid])
	{
	oocToggle[playerid] = false;
	status = "on";
	}
	else
	{
	oocToggle[playerid] = true;
	status = "off";
	}
	format(string, sizeof(string), "You have turned OOC chat %s.", status);
	SendClientMessage(playerid, -1, string);
	return 1;
}

//This command will tell the user their current X, Y and Z location and print it to the console. [DEBUG]
CMD:loc(playerid, params[])
{
	new string[128],Float:x,Float:y,Float:z;
	GetPlayerPos(playerid,x,y,z);
	format(string, sizeof(string), "x:%f y:%f z:%f", x, y, z);
	SendClientMessage(playerid, -1, string);
	printf(string);
	return 1;
}
