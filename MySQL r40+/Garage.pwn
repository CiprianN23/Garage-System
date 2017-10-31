/*
*************************************************************************
				Garage System - MySQL r40+
					Made by Banditul
						02.05.2017

Credits:
Y_Less for sscanf2
Incognito for streamer
Yashas for I_ZCMD
BlueG and maddinat0r for MySQL
SA-MP Team for make it possibile
*************************************************************************
*/

//Includes
#include <a_samp>
#include <a_mysql>
#include <streamer>
#include <sscanf2>
#include <izcmd>

#if !defined strcpy
	#define strcpy(%0,%1,%2) strcat((%0[0] = EOS, %0), %1, %2)
#endif


//Defines
#define MAX_GARAGES 50 // Increase/Decrease at your will

// MySQL connection handle
new MySQL: SQL;

// MySQL configuration
#define		MYSQL_HOST 			"localhost"
#define		MYSQL_USER 			"root"
#define		MYSQL_PASSWORD 		""
#define		MYSQL_DATABASE 		"database"


//Garage system enum for holding data
enum E_GARAGES{
	//Saved Data
	Owner[MAX_PLAYER_NAME], // Hold the owner Name
	Owned, // Hold 
	Float: eX, // Hold exterior X coordonate ( usually the X where was created)
	Float: eY, // Hold exterior Y coordonate ( usually the Y where was created)
	Float: eZ, //Hold exterior Z coordonate ( usually the Z where was created)
	Price, // Hold the price of the garage (set when it's created)
	Size, // Hodl the garage size
	VirtualWorld, //Hold the virtual world of the garage(important to not have  different garages to share players/cars)

	//Unsaved Data
	MapiconID, // Hold the map icon ID
	PickupID, //Hold the pickup ID
	Text3D: Label // Hold the 3D Text Label
};
new GarageInfo[MAX_GARAGES][E_GARAGES];

//Garage type enum (for multiple garages types)
enum E_GarageType{
	InteriorID, // Hold the interior ID

	Float: intX, // Hold the Interior X of the garage
	Float: intY, // Hold the Interior Y of the garage
	Float: intZ // // Hold the Interior Z of the garage
};

new GarageInteriors[][E_GarageType] = {
	{1, 404.8766,-293.0546,997.1705}, // Small Garage
	{1, 673.4003,-204.4471,982.4297}, // Medium Garage
	{1,122.5266,-397.4305,1190.3938} // Big Garage
};

new PlayerGarageID[MAX_PLAYERS];

public OnFilterScriptInit(){
	//CreateDynamicObject(modelid, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz, worldid = -1, interiorid = -1, playerid = -1, Float:streamdistance = STREAMER_OBJECT_SD, Float:drawdistance = STREAMER_OBJECT_DD, areaid = -1, priority = 0);

	new MySQLOpt: option_id = mysql_init_options();

	mysql_set_option(option_id, AUTO_RECONNECT, true); // it automatically reconnects when loosing connection to mysql server

	mysql_log(ALL);

	SQL = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE, option_id); // AUTO_RECONNECT is enabled for this connection handle only
	if (SQL == MYSQL_INVALID_HANDLE || mysql_errno(SQL) != 0)
	{
		print("MySQL connection failed. Server is shutting down.");
		SendRconCommand("exit"); // close the server if there is no connection
		return 1;
	}

	print("MySQL connection is successful.");

	//Small Garage
	CreateDynamicObject(6387,402.2000100,-261.1000100,996.7000100,0.0000000,0.0000000,0.0000000, .interiorid = 1); //object(century03_law2) (1)
	CreateDynamicObject(16773,406.2999900,-294.0000000,996.7000100,0.0000000,0.0000000,0.0000000, .interiorid = 1); //object(door_savhangr1) (1)
	CreateDynamicObject(16773,404.7000100,-228.2000000,996.5999800,0.0000000,0.0000000,0.0000000, .interiorid = 1); //object(door_savhangr1) (2)

	//Medium Garage
	CreateDynamicObject(10784,656.7999900,-248.1000100,981.0000000,0.0000000,0.0000000,0.0000000, .interiorid = 1); //object(aircarpark_04_sfse) (1)
	CreateDynamicObject(16775,628.0000000,-279.7000100,980.7999900,0.0000000,0.0000000,90.0000000, .interiorid = 1); //object(door_savhangr2) (1)
	CreateDynamicObject(16775,672.7999900,-202.8000000,981.0999800,0.0000000,0.0000000,359.5000000, .interiorid = 1); //object(door_savhangr2) (2)

	//Big garage
	CreateDynamicObject(7244,72.6000000,-379.3999900,1183.8000000,0.0000000,0.0000000,0.0000000, .interiorid = 1); //object(vgnpolicecparkug) (2)
	CreateDynamicObject(8378,103.8000000,-350.7000100,1191.4000000,0.0000000,0.0000000,0.0000000, .interiorid = 1); //object(vgsbighngrdoor) (1)
	CreateDynamicObject(6959,121.6000000,-336.2999900,1185.4000000,0.0000000,0.0000000,0.0000000, .interiorid = 1); //object(vegasnbball1) (1)
	CreateDynamicObject(6959,122.9000000,-334.7000100,1201.6000000,270.7500000,180.0000000,92.0000000, .interiorid = 1); //object(vegasnbball1) (2)
	CreateDynamicObject(16773,123.4000000,-397.0000000,1189.4000000,0.0000000,0.0000000,270.0000000, .interiorid = 1); //object(door_savhangr1) (1)

	LoadGarages();

	print("***********************************");
	print("Garage System Loaded.");
	print("***********************************\n");
	
	return 1;
}

public OnPlayerConnect(playerid) {
	PlayerGarageID[playerid] = 0;
	return 1;
}

LoadGarages(){
	new Cache: result, ID, rows,countsuccess, countfailed;
	//The query
	result = mysql_query(SQL,"SELECT * FROM `garages` ORDER BY `ID` ASC", true);

	rows = cache_num_rows();
	//If there is any data, load it
	if(rows)
	{
		// Loop through all rows 
        for (new row; row < rows; row++) 
        {
        	cache_get_value_name_int(row, "ID", ID);

        	// Check if the ID is invalid (out of range) 
            if ((ID < 1) || (ID >= MAX_GARAGES)) 
            { 
                // Count the amount of failed garages entries (invalid ID's) 
                countfailed++; 
                // Add a message to the server-console to inform the admin about the wrong ID 
                printf("*** ERROR: Invalid ID found in table \"garages\": %i", ID); 
                // Continue with the next garage entry from the MySQL query 
                continue; 
            }

            cache_get_value_name(row, "Owner", GarageInfo[ID][Owner], MAX_PLAYER_NAME);
            cache_get_value_name_int(row, "Owned", GarageInfo[ID][Owned]);
            cache_get_value_name_int(row, "Size", GarageInfo[ID][Size]);
            cache_get_value_name_int(row, "Price", GarageInfo[ID][Price]);
            cache_get_value_name_float(row,"eX", GarageInfo[ID][eX]);
            cache_get_value_name_float(row,"eY", GarageInfo[ID][eY]);
            cache_get_value_name_float(row,"eZ", GarageInfo[ID][eZ]);

            GarageInfo[ID][VirtualWorld] = ID;

            // Create the 3DText, mapicon and pickup that appears at the garage entrance 
            Garage_Update(ID);

            // Count the succesfully loaded garage entries 
            countsuccess++; 

        }
	}
	// Print the amount of garages entries loaded for debugging 
    printf("*** >>> Garages loaded: %i (successful: %i, failed: %i)", rows, countsuccess, countfailed); 
    printf(""); 

    // Clear the cache to prevent memory-leaks 
    cache_delete(result); 
}

// This function updates (destroys and re-creates) the pickup, map-icon and 3DText label near the garage's entrance
Garage_Update(GarageID) {
	// Setup local variables
	new Msg[64], Float:x, Float:y, Float:z;

	// Get the coordinates of the garage's pickup (usually near the door)
	x = GarageInfo[GarageID][eX];
	y = GarageInfo[GarageID][eY];
	z = GarageInfo[GarageID][eZ];

	// Destroy the pickup, map-icon and 3DText near the garage's entrance (if they exist)
	if (IsValidDynamicPickup(GarageInfo[GarageID][PickupID]))
		DestroyDynamicPickup(GarageInfo[GarageID][PickupID]);
	if (IsValidDynamicMapIcon(GarageInfo[GarageID][MapiconID]))
		DestroyDynamicMapIcon(GarageInfo[GarageID][MapiconID]);
	if (IsValidDynamic3DTextLabel(GarageInfo[GarageID][Label]))
		DestroyDynamic3DTextLabel(GarageInfo[GarageID][Label]);

	// Add a new pickup at the garage's location (usually near the door), green = free, blue = owned
	if (GarageInfo[GarageID][Owned] == 1)
	{
		// Create a blue garage-pickup (garage is owned)
 		GarageInfo[GarageID][PickupID] = CreateDynamicPickup(1272, 1, x, y, z, 0);
		// Create the 3DText that appears above the garage-pickup (displays the name of the owner and the id of the garage)
		format(Msg, sizeof(Msg), "ID: %i\nOwned by: %s\n/enter", GarageID, GarageInfo[GarageID][Owner]);
		GarageInfo[GarageID][Label] = CreateDynamic3DTextLabel(Msg, 0x008080FF, x, y, z + 1.0, 50.0);
	}
	else
	{
        // Create a green garage-pickup (garage is free)
		GarageInfo[GarageID][PickupID] = CreateDynamicPickup(1273, 1, x, y, z, 0);
		// Create the 3DText that appears above the garage-pickup (displays the price of the garage)
		format(Msg, sizeof(Msg), "Garage available for\n$%i\n/buygarage", GarageInfo[GarageID][Price]);
		GarageInfo[GarageID][Label] = CreateDynamic3DTextLabel(Msg, 0x008080FF, x, y, z + 1.0, 50.0);
		// Add a streamed icon to the map (green garage), type = 31, color = 0, world = 0, interior = 0, playerid = -1, drawdist = 150.0
		GarageInfo[GarageID][MapiconID] = CreateDynamicMapIcon(x, y, z, 31, 0, 0, 0, -1, 150.0);
	}
}

// This function sets ownership to the given player
Garage_SetOwner(playerid, GarageID) {
	// Setup local variables
	new Name[MAX_PLAYER_NAME], Msg[128];

	// Get the player's name
	GetPlayerName(playerid, Name, sizeof(Name));

	// Set the garage as owned
	GarageInfo[GarageID][Owned] = 1;
	// Store the owner-name for the garage
	strcpy(GarageInfo[GarageID][Owner], Name, sizeof(Name));

	//Take player money
	GivePlayerMoney(playerid, -GarageInfo[GarageID][Price]);

	// Also, update the pickup and map-icon for this garage
	Garage_Update(GarageID);

	mysql_format(SQL, Msg, sizeof(Msg), "UPDATE `garages` SET `Owner` = '%e' , `Owned` = 1 WHERE `ID` = %i" , GarageInfo[GarageID][Owner] , GarageID);
	mysql_tquery(SQL, Msg);

	// Let the player know he bought the garage
	format(Msg, sizeof(Msg), "You've bought the garage for $%i", GarageInfo[GarageID][Price]);
	SendClientMessage(playerid, -1, Msg);


	return 1;
}
// This function returns "1" if the given player is the owner of the given garage
Garage_PlayerIsOwner(playerid, GarageID)
{
	new Name[MAX_PLAYER_NAME];
	GetPlayerName(playerid, Name , MAX_PLAYER_NAME);
	if(strcmp(GarageInfo[GarageID][Owner], Name, false) == 0)
		return 1;

	// If the player doesn't own the garage, return 0
	return 0;
}

CMD:creategarage(playerid,params[]) {
	
	if(!IsPlayerAdmin(playerid)) // Replace with your admin verification
		return SendClientMessage(playerid, -1, "You are not an admin."); 

	// If the player is the driver of a vehicle, exit the command 
    if(GetPlayerVehicleID(playerid) != 0) 
    	return SendClientMessage(playerid, -1, "You must be on foot to create a garage."); 

	// Setup local variables 
    new buyprice, size, ID; 

    if (sscanf(params, "iI(0)", buyprice, size)) {
    	SendClientMessage(playerid, -1, "Syntax: \"/creategarage <price> <size(default 0)>\"");
    	return SendClientMessage(playerid, -1, "Size: 0 - Small Garage , 1 - Medium Garage, 2 - Big Garage.");
    }

    // Exit the function if the player entered an invalid maxlevel 
    if ((size < 0) || (size > 2)) return SendClientMessage(playerid, -1, "Size must be from 0 to 2."); 

    // Find the first free GarageID 
    for (ID = 1; ID < MAX_GARAGES; ID++) 
        if (!IsValidDynamicPickup(GarageInfo[ID][PickupID])) // Check if an empty garage-index has been found (PickupID is 0)
            break; // Stop searching, the first free GarageID has been found now 

    // Exit the function if the maximum amount of garages has been reached 
    if (ID == MAX_GARAGES) return SendClientMessage(playerid, -1, "The maximum amount of garages has been reached.");

    // Check if the garage-limit hasn't been reached yet
	// This would seem to double-check the pickup-id, but in case there was no free garageslot found (GarageID points
	// to the last index, the last index would hold a garage, so be sure to not overwrite it
	if (!IsValidDynamicPickup(GarageInfo[ID][PickupID]))
	{
		// Setup some local variables
		new Float:x, Float:y, Float:z, Msg[128];
		// Get the player's position
		GetPlayerPos(playerid, x, y, z);
		// Set some default data
		GarageInfo[ID][Owned] = 0;
		GarageInfo[ID][Owner][0] = EOS;
		GarageInfo[ID][eX] = x;
		GarageInfo[ID][eY] = y;
		GarageInfo[ID][eZ] = z;
		GarageInfo[ID][Price] = buyprice;
		GarageInfo[ID][Size] = size;

		// Add the pickup and 3DText at the location of the garage-entrance (where the player is standing when he creates the garage)
		Garage_Update(ID);

		//Insert data into MySQL databse
		mysql_format(SQL, Msg, sizeof(Msg), "INSERT INTO `garages` (ID , eX , eY, eZ  , Owner, Price, Size) VALUES (%i , %f , %f, %f , '%e', %i , %i)" , ID, x, y, z , GarageInfo[ID][Owner], buyprice, size);
		mysql_tquery(SQL, Msg);

		// Inform the player that he created a new garage
		format(Msg, sizeof(Msg), "{00FF00}You've succesfully created a garage with ID: {FFFF00}%i", ID);
		SendClientMessage(playerid, -1, Msg);
	}
	else
		SendClientMessage(playerid, -1, "The maximum amount of garages has been reached");

    return 1;
}

// This command lets the player enter the garage if he's the owner
CMD:enter(playerid, params[]) {

	// Check if the player isn't inside a vehicle (the player must be on foot to use this command)
	if (GetPlayerVehicleSeat(playerid) == -1)
	{
		// Setup local variables
		new GarageID, IntID;
		// Loop through all garages
		for (GarageID = 1; GarageID < MAX_GARAGES; GarageID++)
		{
			// Check if the garage exists
			if (IsValidDynamicPickup(GarageInfo[GarageID][PickupID]))
			{
				// Check if the player is in range of the garage-pickup
				if (IsPlayerInRangeOfPoint(playerid, 2.5, GarageInfo[GarageID][eX], GarageInfo[GarageID][eY], GarageInfo[GarageID][eZ]))
				{
					
					// The garage isn't open to the public, so keep anyone out who isn't the owner of the garage
					if (Garage_PlayerIsOwner(playerid, GarageID) == 0)
					{
						// Let the player know that this garage isn't open to the public and he can't enter it
						SendClientMessage(playerid, -1, "You are not the owner of this garage.");
						return 1;
					}
					

					// The player is the owner, let him in

					// Get the interior to put the player in
					IntID = GarageInfo[GarageID][Size]; // Get the szie of the garage

					//Store the GarageID where player enter
					PlayerGarageID[playerid] = GarageID;

					// Set the position of the player at the spawn-location of the garage's interior
					if(GetPlayerVehicleID(playerid) != 0){
						SetPlayerPosEx(playerid, GarageInteriors[IntID][intX], GarageInteriors[IntID][intY], GarageInteriors[IntID][intZ] , 1, GarageInfo[GarageID][VirtualWorld]);
						SetVehiclePosEx(GetPlayerVehicleID(playerid),playerid ,GarageInteriors[IntID][intX], GarageInteriors[IntID][intY], GarageInteriors[IntID][intZ] , 1, GarageInfo[GarageID][VirtualWorld]);
					}
					else{
						SetPlayerPosEx(playerid, GarageInteriors[IntID][intX], GarageInteriors[IntID][intY], GarageInteriors[IntID][intZ] , 1, GarageInfo[GarageID][VirtualWorld]);
					}

					// Exit the function
					return 1;
				}
			}
		}
	}

	// If no garage was in range, allow other script to use this command too (garage-script for example)
	return 0;
}

// This command lets the player exit the garage
CMD:exitgarage(playerid,params[]) {

	if(PlayerGarageID[playerid] != 0) {
		new GarageID = PlayerGarageID[playerid];
		if(GetPlayerVehicleID(playerid) != 0){
			SetPlayerPosEx(playerid, GarageInfo[GarageID][eX] , GarageInfo[GarageID][eY], GarageInfo[GarageID][eZ]);
			SetVehiclePosEx(GetPlayerVehicleID(playerid),playerid ,GarageInfo[GarageID][eX] , GarageInfo[GarageID][eY], GarageInfo[GarageID][eZ]);
		}
		else{
			SetPlayerPosEx(playerid, GarageInfo[GarageID][eX] , GarageInfo[GarageID][eY], GarageInfo[GarageID][eZ]);
		}
		SendClientMessage(playerid, -1 , "You exit the garage.");
	}
	return 1;
}

// This command lets the player buy a garage when he's standing in range of a garage that isn't owned yet
CMD:buygarage(playerid, params[])
{
	// Check if the player isn't inside a vehicle (the player must be on foot to use this command)
	if (GetPlayerVehicleSeat(playerid) == -1)
	{
		// Check if the player is near a garage-pickup
		for (new GarageID = 1; GarageID < MAX_GARAGES; GarageID++)
		{
			// Check if the garage exists
			if (IsValidDynamicPickup(GarageInfo[GarageID][PickupID]))
			{
				// Check if the player is in range of the garage-pickup
				if (IsPlayerInRangeOfPoint(playerid, 2.5, GarageInfo[GarageID][eX], GarageInfo[GarageID][eY], GarageInfo[GarageID][eZ]))
				{
				    // Check if the garage isn't owned yet
				    if (GarageInfo[GarageID][Owned] == 0)
				    {
				        // Check if the player can afford this garage
				        if (GetPlayerMoney(playerid) >= GarageInfo[GarageID][Price])
				            Garage_SetOwner(playerid, GarageID); // Give ownership of the garage to the player
				        else
				            SendClientMessage(playerid, -1, "You cannot afford this garage"); // The player cannot afford this garage
				    }
				    else
				    {
				    	// Setup local variables
						new Msg[128];
				        // Let the player know that this garage is already owned by a player
						format(Msg, sizeof(Msg), "This garage is already owned by {FFFF00}%s", GarageInfo[GarageID][Owner]);
						SendClientMessage(playerid, -1, Msg);
				    }

					// The player was in range of a garage-pickup, so stop searching for the other garage pickups
				    return 1;
				}
			}
		}

		// All garages have been processed, but the player wasn't in range of any garage-pickup, let him know about it
		SendClientMessage(playerid, -1, "To buy a garage, you have to be near a garage-pickup");
	}
	else
	    SendClientMessage(playerid, -1, "You can't buy a garage when you're inside a vehicle");

	// Let the server know that this was a valid command
	return 1;
}
// This command lets the player delete a garage
CMD:delgarage(playerid, params[]) {

	// Setup local variables
	new Msg[128], Name[24];

	// Check if the player isn't inside a vehicle (the admin-player must be on foot to use this command)
	if (GetPlayerVehicleSeat(playerid) == -1)
	{
		// Loop through all garages
		for (new GarageID = 1; GarageID < MAX_GARAGES; GarageID++)
		{
			// Check if the garage exists
			if (IsValidDynamicPickup(GarageInfo[GarageID][PickupID]))
			{
				// Check if the player is in range of the garage-pickup
				if (IsPlayerInRangeOfPoint(playerid, 2.5, GarageInfo[GarageID][eX], GarageInfo[GarageID][eY], GarageInfo[GarageID][eZ]))
				{
					// Get the name of the owner (if the garage is owned)
					if (GarageInfo[GarageID][Owned] == 1)
					{
						// Loop through all players to find the owner (if he's online)
						for (new pid = 0 , j = GetPlayerPoolSize(); pid <= j; pid++)
						{
							// Check if this player is online
						    if (IsPlayerConnected(pid))
						    {
						        // Get that player's name
						        GetPlayerName(pid, Name, sizeof(Name));
						        // Compare if this player has the same name as the owner of the garage
								if (strcmp(GarageInfo[GarageID][Owner], Name, false) == 0)
								{
									SendClientMessage(pid, -1, "Your garage is being deleted.");
								}
						    }
						}
					}

					// Clear all data of the garage
					GarageInfo[GarageID][Owner][0] = EOS;
					GarageInfo[GarageID][eX] = 
					GarageInfo[GarageID][eY] = 
					GarageInfo[GarageID][eZ] = 0.0;
					GarageInfo[GarageID][Price] = 
					GarageInfo[GarageID][Size] = 
					GarageInfo[GarageID][Owned] = 0;

					// Destroy the mapicon, 3DText and pickup for the garage
					DestroyDynamicPickup(GarageInfo[GarageID][PickupID]);
					DestroyDynamicMapIcon(GarageInfo[GarageID][MapiconID]);
					DestroyDynamic3DTextLabel(GarageInfo[GarageID][Label]);
					GarageInfo[GarageID][PickupID] = 
					GarageInfo[GarageID][MapiconID] = 0;

					mysql_format(SQL, Msg, sizeof(Msg), "DELETE FROM `garages` WHERE `ID` = %i LIMIT 1" , GarageID);
					mysql_tquery(SQL, Msg);

					// Also let the player know he deleted the garage
					format(Msg, 128, "{00FF00}You have deleted the garage with ID: {FFFF00}%i", GarageID);
					SendClientMessage(playerid, -1, Msg);

					// Exit the function
					return 1;
				}
			}
		}

		// There was no garage in range, so let the player know about it
		SendClientMessage(playerid, -1, "No garage in range to delete");
	}
	else
	    SendClientMessage(playerid, -1, "You must be on foot to delete a garage");

	// Let the server know that this was a valid command
	return 1;
}


SetPlayerPosEx(playerid, Float: x, Float: y, Float: z , interiorid = 0, virtualworld = 0) {
	SetPlayerVirtualWorld(playerid, virtualworld);
	SetPlayerInterior(playerid, interiorid);
	SetPlayerPos(playerid, x, y, z);
	Streamer_UpdateEx(playerid, x, y, z , .freezeplayer = 1);
	SetCameraBehindPlayer(playerid);
}
SetVehiclePosEx(vehicleid, playerid, Float: x, Float: y, Float: z , interiorid = 0, virtualworld = 0) {
	SetVehicleVirtualWorld(vehicleid, virtualworld);
	LinkVehicleToInterior(vehicleid, interiorid);
	SetVehiclePos(vehicleid, x, y, z);
	SetVehicleZAngle(vehicleid, 90.0);
	PutPlayerInVehicle(playerid, vehicleid, 0);
	Streamer_UpdateEx(playerid, x, y, z , .freezeplayer = 1);
}

