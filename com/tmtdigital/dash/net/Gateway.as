﻿/**
 *
 * Gateway.as
 *
 * Description:  Class that provides an interface between different components.  This class will be used
 *               to abstract out all external and internal interface interactions.  The external interface
 *               is used to connect many different instances of the Dash Media Player on the page at once.
 *               This means that you can quite literally have playlists and nodes on the page at a time talking to 
 *               one another as if they were connected internally.

 *
 * Author:   Travis Tidwell ( travist@tmtdigital.com )
 *
 **/

package com.tmtdigital.dash.net
{
   import com.tmtdigital.dash.DashPlayer;	
   import com.tmtdigital.dash.display.media.MediaPlayer;
   import com.tmtdigital.dash.utils.Utils;
   import com.tmtdigital.dash.net.Service;  
   import com.tmtdigital.dash.config.Params;  

   import flash.external.*;
   import flash.utils.*;
   import flash.events.*;
   import flash.net.*;

   public class Gateway
   {
      /**
       * Load the interface for a connection between multiple instances of the Dash Media Player
       * on the page at a time.
       */
      public static function loadGateway( _onLoaded:Function )
      {
         onLoaded = _onLoaded;
         external = false;
         javaScriptReady = false;
         callbacksAdded = false;
         loaded = false;
			
         // Add all of the connections.
         addConnects();
			
         // Check the interface.
         if( checkInterface() ) {
            
            // Interface is ready.
            onReady();			
         }
         else {
            // Start the timer check.
            startTimerCheck();
         }
      }
      
      /**
       * Add all of the connections to the connects array.
       */
      private static function addConnects()
      {
         // Declare a new connects array.
         connects = new Array();
         
         // If they wish to connect to another player.
         if( Params.flashVars.connect ) {
            
            // If they have an "_and_" within their connection, then
            // this means that there are multiple connecions to be made.
            if ( Params.flashVars.connect.indexOf('_and_') >= 0) {
            
               // Set up the connection by spliting the connect string.
               connects = Params.flashVars.connect.split('_and_');
            } else {
            
               // Add our single connection to our array.
               connects.push( Params.flashVars.connect );
            }
         }	
      }		
      
      /**
       * Checks to see if the interface is available.
       *
       * @return - True (ready), False (not ready)
       */
      private static function checkInterface() : Boolean
      {
         if( Params.flashVars.connect ) {      
            // Check the interface.
            if ( ExternalInterface.available ) {
               
               // Add all of the callbacks.
               if( addCallbacks() ) {
                  
                  // Check the JavaScript.
                  if ( isJavaScriptReady() ) {
                     
                     // We are ready!
                     return true;
                  }		
               }
            } 	
         }
         else {
            return true;
         }
         
         return false;
      }		
      
      /**
       * Called when our system is ready to go...
       */
      private static function onReady()
      {
         // If we want to connect and our java script is ready...
         if( Params.flashVars.connect && javaScriptReady && (Params.flashVars.connect != Params.flashVars.id) ) {
            // We want an external connection.
            external = true;
            // Register for our dash player object.
            ExternalInterface.call("dashRegisterObject", Params.flashVars.id );
         }
         else {
            // Initialize our gateway...
         	initialize();
         }					
      }

      /**
       * Adds all of our ExternalInterface callback routines.
       *
       * @return - True if the callback registration was successful.
       */
      private static function addCallbacks() : Boolean
      {
         // Make sure we have not already added our callbacks.
         if( !callbacksAdded ) {
         
            // Try to register all of our callbacks.
            try {
               // Register for all our callbacks.
               ExternalInterface.addCallback( "initialize", initialize );	
               ExternalInterface.addCallback( "spawn", spawn );               				
               ExternalInterface.addCallback( "loadNode", loadNode );
               ExternalInterface.addCallback( "isNodeLoaded", isNodeLoaded );
               ExternalInterface.addCallback( "loadPlaylist", loadPlaylist );
               ExternalInterface.addCallback( "setPlaylistVote" , setPlaylistVote );
               ExternalInterface.addCallback( "setPlaylistUserVote" , setPlaylistUserVote );					
               ExternalInterface.addCallback( "setVote" , setVote );
               ExternalInterface.addCallback( "setUserVote" , setUserVote );					
					ExternalInterface.addCallback( "loadPrev", loadPrev );
               ExternalInterface.addCallback( "loadNext", loadNext );
               ExternalInterface.addCallback( "prevPage", prevPage );
               ExternalInterface.addCallback( "nextPage", nextPage );
               ExternalInterface.addCallback( "setFilter", setFilter );
               ExternalInterface.addCallback( "setPlaylist", setPlaylist );               
               ExternalInterface.addCallback( "loadMedia", loadMedia );
               ExternalInterface.addCallback( "playMedia", playMedia );
               ExternalInterface.addCallback( "pauseMedia", pauseMedia );
               ExternalInterface.addCallback( "stopMedia", stopMedia );
               ExternalInterface.addCallback( "setSeek", setSeek );
               ExternalInterface.addCallback( "setVolume", setVolume );
               ExternalInterface.addCallback( "getVolume", getVolume );
               ExternalInterface.addCallback( "resetControls", resetControls );
               ExternalInterface.addCallback( "enableControls", enableControls );
               ExternalInterface.addCallback( "setControlState", setControlState );
               ExternalInterface.addCallback( "setControlTime", setControlTime );
               ExternalInterface.addCallback( "setControlVolume", setControlVolume );
               ExternalInterface.addCallback( "setControlProgress", setControlProgress );
               ExternalInterface.addCallback( "setControlSeek", setControlSeek );
               ExternalInterface.addCallback( "controlUpdate", controlUpdate );
               ExternalInterface.addCallback( "setMaximize", setMaximize );
               ExternalInterface.addCallback( "setFullScreen", setFullScreen );
               ExternalInterface.addCallback( "setMenu", setMenu );
               ExternalInterface.addCallback( "showInfo", showInfo );
               ExternalInterface.addCallback( "setSkin", setSkin );
               ExternalInterface.addCallback( "serviceCall", serviceCall );
               callbacksAdded = true;					
            } catch (error:SecurityError) {
               trace("A SecurityError occurred: " + error.message + "\n");
            } catch (error:Error) {
               trace("An Error occurred: " + error.message + "\n");
            }			
         }
         
         // Return if our callbacks were registered.
         return callbacksAdded;
      }

      /**
       * Starts a timer for re-checking the interface to see if it is ready.
       */
      private static function startTimerCheck()
      {
         // Declare the readyTime if we have not already done so.
         if( !readyTimer ) {
            readyTimer = new Timer(200);
            readyTimer.addEventListener(TimerEvent.TIMER, timerHandler);
         }
         
         // Reset our retries and start the counter.
         retries = 0;
         readyTimer.start();
      }
      
      /**
       * Checks to see if javascript is ready to go.
       *
       * @return - True if JavaScript is ready.
       */
      private static function isJavaScriptReady():Boolean
      {
         if( !javaScriptReady )
         {
            // If we wish to connect to external interfaces, then
            // we will need to perform this check.  Otherwise, just
            // set the ready flag to true since all communication will
            // be internal.
            
            if( Params.flashVars.connect ) {
               javaScriptReady = ExternalInterface.call("isDashReady");
            }
            else {
               javaScriptReady = true;
            }
         }
         
         return javaScriptReady;
      }

      /**
       * Called every timer interval to recheck our external interface.
       *
       * @param - The timer event object.
       */
       
      private static function timerHandler(event:TimerEvent):void
      {
         if( checkInterface() || (retries++ >= 5) ) {
            readyTimer.stop();
            onReady();
         }			
      }

      /**
       * Called when our JavaScript gateway returns from the registration...
       */
       
      public static function initialize() 
      {
         if( !loaded ) {
            loaded = true;
         	onLoaded();
         }
      }
      
      /**
       * Spawns a player...
       */
      public static function spawn( callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSpawn", connect );
            }
         } else {			
         	ExternalInterface.call( "dashSpawnWindow", Params.playerPath );
			}
      }
      
      public static function setActive() 
      {
         if( Params.flashVars.playlistonly ) {
            ExternalInterface.call( "dashSetActivePlaylist", Params.flashVars.id );
         }
         else {
            ExternalInterface.call( "dashSetActivePlayer", Params.flashVars.id )
         }
      }
		
      /**
       * Loads a node
       */
      public static function loadNode( node:* = null, callExternal:Boolean = false )
      {
         if ( callExternal && external && node ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashLoadNode", connect, node.nid );
            }
         } else {
            DashPlayer.loadNode( Params.flashVars.cacheload ? node : node.nid );
         }
      }

      public static function playMedia( _file:String = null, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashPlay", connect, _file );
            }
            setActive();				
         } else if( DashPlayer.media ) {
            loadMedia( _file );
            DashPlayer.media.playFile();
         }
      }

      public static function pauseMedia( callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashPause", connect );
            }
         } else if( DashPlayer.media ) {
            DashPlayer.media.pauseFile();
         }
      }

      public static function stopMedia( callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashStop", connect );
            }
         } else if( DashPlayer.media ) {
               DashPlayer.media.stopFile();
         }
      }

      public static function setSeek( time:Number, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSeek", connect, time );
            }
         } else if( DashPlayer.media ) {
               DashPlayer.media.setSeek( time );
         }
      }

      public static function setVolume( vol:Number, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashVolume", connect, vol );
            }
         } else if( DashPlayer.media ) {
               DashPlayer.media.setVolume( vol );
         }
      }

      public static function getVolume( callExternal:Boolean = false ):Number
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               return ExternalInterface.call( "dashGetVolume", connect );
            }
         } else if( DashPlayer.media ) {
            return DashPlayer.media.getVolume();
         }

         return 0;
      }

      public static function setFullScreen( on:Boolean, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetFullScreen", connect, on );
            }
         } else {
            DashPlayer.toggleFullScreen( on );
         }
      }

      public static function setMaximize(  max:Boolean, tween:Boolean = true, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetMaximize", connect, max, tween );
            }
         } else {
            DashPlayer.setMaximize( max, tween );
         }
      }

      public static function setMenu( on:Boolean, tween:Boolean = true, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetMenu", connect, on, true );
            }
         } else if( DashPlayer.dash.node ) {
            DashPlayer.dash.node.fields.menu.toggleMenuMode( on, tween );
         }	
      }
	
      public static function showInfo( on:Boolean, tween:Boolean = true, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashShowInfo", connect, on, true );
            }
         } else if( DashPlayer.dash.node ) {
            DashPlayer.dash.node.fields.showInfo( on, tween );
         }	
      }

      public static function isNodeLoaded( callExternal:Boolean = false ):Boolean
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               return ExternalInterface.call( "dashIsNodeLoaded", connect );
            }
         } else if( DashPlayer.dash.node )  {
            return DashPlayer.dash.node.loaded;
         }

         return false;
      }

      public static function resetControls( callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashResetControls", connect );
            }
         } else {
            if( DashPlayer.dash.playlist && DashPlayer.dash.playlist.media ) {
               DashPlayer.dash.playlist.media.controlBar.reset();
            }
            
            if( DashPlayer.dash.node && DashPlayer.dash.node.fields && DashPlayer.dash.node.fields.media ) {
               DashPlayer.dash.node.fields.media.controlBar.reset();
            }
         }
      }

      public static function enableControls( enable:Boolean, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashEnableControls", connect, enable );
            }
         } else {
            if( DashPlayer.dash.playlist && DashPlayer.dash.playlist.media ) {
               DashPlayer.dash.playlist.media.controlBar.enable( enable );
            }
            
            if( DashPlayer.dash.node && DashPlayer.dash.node.fields && DashPlayer.dash.node.fields.media ) {
               DashPlayer.dash.node.fields.media.controlBar.enable( enable );
            }
         }
      }

      public static function setControlState( state:String, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetControlState", connect, state );
            }
         } else {
            if( DashPlayer.dash.playlist && DashPlayer.dash.playlist.media ) {
               DashPlayer.dash.playlist.media.controlBar.setState( state );
            }
            
            if( DashPlayer.dash.node && DashPlayer.dash.node.fields && DashPlayer.dash.node.fields.media ) {
               DashPlayer.dash.node.fields.media.controlBar.setState( state );
            }
         }
      }

      public static function setControlTime( time:Number, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetControlTime", connect, time );
            }
         } else {
            if( DashPlayer.dash.playlist && DashPlayer.dash.playlist.media ) {
               DashPlayer.dash.playlist.media.controlBar.setTotalTime( time );
            }
            
            if( DashPlayer.dash.node && DashPlayer.dash.node.fields && DashPlayer.dash.node.fields.media ) {
               DashPlayer.dash.node.fields.media.controlBar.setTotalTime( time );
            }
         }
      }

      public static function setControlVolume( vol:Number, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetControlVolume", connect, vol );
            }
         } else {
            if( DashPlayer.dash.playlist && DashPlayer.dash.playlist.media ) {
               DashPlayer.dash.playlist.media.controlBar.setVolume( vol );
            }
            
            if( DashPlayer.dash.node && DashPlayer.dash.node.fields && DashPlayer.dash.node.fields.media ) {
               DashPlayer.dash.node.fields.media.controlBar.setVolume( vol );
            }
         }
      }

      public static function setControlProgress( progress:Number, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetControlProgress", connect, progress );
            }
         } else {
            if( DashPlayer.dash.playlist && DashPlayer.dash.playlist.media ) {
               DashPlayer.dash.playlist.media.controlBar.setProgress( progress );
            }
            
            if( DashPlayer.dash.node && DashPlayer.dash.node.fields && DashPlayer.dash.node.fields.media ) {
               DashPlayer.dash.node.fields.media.controlBar.setProgress( progress );
            }
         }
      }

      public static function setControlSeek( seek:Number, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetControlSeek", connect, seek );
            }
         } else {
            if( DashPlayer.dash.playlist && DashPlayer.dash.playlist.media ) {
               DashPlayer.dash.playlist.media.controlBar.setSeekValue( seek );
            }
            
            if( DashPlayer.dash.node && DashPlayer.dash.node.fields && DashPlayer.dash.node.fields.media ) {
               DashPlayer.dash.node.fields.media.controlBar.setSeekValue( seek );
            }
         }
      }

      public static function controlUpdate( playTime:Number, totalTime:Number, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashControlUpdate", connect, playTime, totalTime );
            }
         } else {
            if( DashPlayer.dash.playlist && DashPlayer.dash.playlist.media ) {
               DashPlayer.dash.playlist.media.controlBar.update( playTime, totalTime );
            }
            
            if( DashPlayer.dash.node && DashPlayer.dash.node.fields && DashPlayer.dash.node.fields.media ) {
               DashPlayer.dash.node.fields.media.controlBar.update( playTime, totalTime );
            }
         }
      }

      public static function setVote( vote:Object, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetVote", connect, vote );
            }
         } else if( DashPlayer.dash.node )  {
            DashPlayer.dash.node.fields.voter.setVote( vote, "node" );
         }		
      }

      public static function setUserVote( vote:Object, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetUserVote", connect, vote );
            }
         } else if( DashPlayer.dash.node )  {
            DashPlayer.dash.node.fields.voter.setUserVote( vote, "node" );
         }		
      }

      public static function setPlaylistVote( nodeId:Number, vote:Object, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetPlaylistVote", connect, nodeId, vote );
            }
         } else if( DashPlayer.dash.playlist )  {
            DashPlayer.dash.playlist.setVote( nodeId, vote );
         }		
      }

      public static function setPlaylistUserVote( nodeId:Number, vote:Object, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetPlaylistUserVote", connect, nodeId, vote );
            }
         } else if( DashPlayer.dash.playlist )  {
            DashPlayer.dash.playlist.setUserVote( nodeId, vote );
         }		
      }

      public static function loadPlaylist( playlistName:String = null, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashLoadPlaylist", connect, playlistName );
            }
         } else if( DashPlayer.dash.playlist )  {
            DashPlayer.dash.playlist.loadPlaylist( playlistName );
         }
      }

      public static function loadPrev( loop:Boolean = false, playAfter:Boolean = false, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashLoadPrev", connect, loop, playAfter );
            }
         } else if( DashPlayer.dash.playlist && DashPlayer.dash.playlist.pager )  {
            DashPlayer.dash.playlist.pager.loadPrev( playAfter );
         }
      }

      public static function loadNext( loop:Boolean = false, playAfter:Boolean = false, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashLoadNext", connect, loop, playAfter );
            }
         } else if( DashPlayer.dash.playlist && DashPlayer.dash.playlist.pager ) {
            DashPlayer.dash.playlist.pager.loadNext( playAfter );
         }
      }

      public static function prevPage( loop:Boolean = false, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashPrevPage", connect, loop );
            }
         } else if( DashPlayer.dash.playlist && DashPlayer.dash.playlist.pager ) {
            DashPlayer.dash.playlist.pager.prevPage();
         }
      }

      public static function nextPage( loop:Boolean = false, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashNextPage", connect, loop );
            }
         } else if( DashPlayer.dash.playlist && DashPlayer.dash.playlist.pager ) {
            DashPlayer.dash.playlist.pager.nextPage();
         }
      }

      public static function setFilter( argument:String, index:Number = 0, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetFilter", connect, argument, index );
            }
         } else if( DashPlayer.dash.playlist ) {
            DashPlayer.dash.playlist.setFilter( argument, index );
         }
      }

      public static function setPlaylist( message:Object, callExternal:Boolean = false )
      {
         if ( callExternal && external ) {
            for each (var connect:String in connects) {
               ExternalInterface.call( "dashSetPlaylist", connect, message );
            }
         } else if( DashPlayer.dash.playlist ) {
            DashPlayer.dash.playlist.setPlaylist( message );
         }
      }

      private static function loadMedia( _file:String ):void
      {
         if ( _file ) {
            DashPlayer.media.initialize();
            DashPlayer.media.loadMediaFile( Utils.getMediaFile( {path:_file} ) );
         }
      }

      private static function setSkin( skinName:String ):void
      {
         DashPlayer.setSkin( skinName );
      }

      private static function serviceCall( command:String, arguments:Array ):void
      {
         if ( Params.flashVars.externalservice ) {
            var message:Object = new Object();
            message.command = command;
            message.onSuccess = onSuccess;
            message.onFailed = null;
            message.args = arguments;			
            Service.serviceCall( message );
         }
      }

      public static function debug( arg:String )
      {
         ExternalInterface.call( "dashDebug", arg );
      }

      private static function onSuccess( ... args )
      {
         ExternalInterface.call( "dashServiceReturn", args );
      }

      private static var callbacksAdded:Boolean;
      private static var javaScriptReady:Boolean;
      private static var external:Boolean;
      private static var readyTimer:Timer;
      private static var retries:uint;		
      private static var onLoaded:Function;
      private static var loaded:Boolean;
      private static var connects:Array;
   }
}