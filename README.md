# UnminableVehicles

Adds admin options to
 - Prevent vehicles from being mined
 - Teleport players to spawn and make them unable to move after they mined/rotated a vehicle (Only works if vehicles can be mined)

### Commands

 - /unminable_vehicles_set_teleport : Sets the teleport location to your current position. Can only be used by admins
 - /unminable_vehicles_enable_movement : Reenables movement for stuck players. Can be used by any player (if only 1 player is online)

# Changelog
0.0.5

 - Messages will also be sent to ChatToFile 
 
0.0.4
 - fixed fluid wagons being minable without consequences
 - teleported players can't mine
 - added option to disallow shooting while waiting for punishment

0.0.3
 - prevent teleported players from building and entering a vehicle
 - removed "forgotten" debug code
 
0.0.2
 - fixed potential desync

0.0.1
 - initial release
