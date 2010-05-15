﻿package com.tmtdigital.dash.display.voter
{
   import com.tmtdigital.dash.display.Skinable;
   import com.tmtdigital.dash.events.DashEvent;
   import com.tmtdigital.dash.net.Service;    

   // Import all dependencies
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   
   // Declare our Voter class.
   public class Voter extends Skinable
   {
      // The Voter constructor.		
      public function Voter( _skin:MovieClip, _userMode:Boolean = false )
      {
         userMode = _userMode;
         super( _skin );			
      }
      
      // Sets the skin for our voter.
      public override function setSkin( _skin:MovieClip )
      {
         super.setSkin( _skin );
         nodeId = 0;
         tag = "vote";
         cache = false;
         
         if( skin ) {
            // Set the skin elements.
            votes = skin.votes;
            voter = skin.voter;
            selected = skin.selected;
            
            if( voter && voter.fill_mc ) {
               voter.fill_mc.width = 0;
            }
            
            if( selected && selected.fill_mc ) {
               selected.fill_mc.width = 0;
            }
            
            // Set the user mode.
            setUserMode();		
         }
      }		
      
      // Sets the user mode for this voter.
      private function setUserMode()
      {
         if( votes ) {
            votes.visible = userMode;
         }
         
         if( voter ) {
            voter.visible = userMode;
         }
         
         if( votes && userMode ) {				
            // Iterate through all the hit regions.
            var i:int = votes.numChildren;
            while (i--)
            {				
               // Get the vote at this location.
               var vote:* = votes.getChildAt(i);
               
               // Setup each hit region for voting.
               vote.buttonMode = true;
               vote.mouseChildren = false;
               vote.addEventListener( MouseEvent.CLICK, onSetVote );
               vote.addEventListener( MouseEvent.MOUSE_OVER, onVoteOver );
            }		
            
            // Called when the mouse exits the voter.
            skin.addEventListener( MouseEvent.MOUSE_OUT, onOut );				
         }
      }
      
      // Sets the tag name.
      public function setTag( _tag:String ) {
         tag = _tag;			
      }		
      
      // Gets a vote from Drupal.
      public function getVote( _nodeId:Number, _cache:Boolean = false )
      {
         // Store the node Id and drupal connection.
         nodeId = _nodeId;
         cache = _cache;
         
         // Get the vote from Drupal.
         var cmd:String = userMode ? Service.GET_USER_VOTE : Service.GET_VOTE;
         Service.call( cmd, onVoteGet, null, "node", nodeId, tag );
      }
      
      // The return function from Drupal.
      private function onVoteGet( vote:Object )
      {
         // Set the selected fill width
         if( vote && selected && selected.fill_mc ) {
            selected.fill_mc.width = vote.value;
         }
         
		 vote.voteType = userMode ? "userVote" : "vote";
         dispatchEvent( new DashEvent( DashEvent.VOTE_GET, vote ) );			
      }		
      
      // Set the selected vote.
      public function setVote( vote:Object )
      {
         // Set the selected fill width
         if( vote && selected && selected.fill_mc ) {
            selected.fill_mc.width = vote.value;
         }
      }			
      
      // Called when the user makes a vote.
      private function onSetVote( event:MouseEvent ) 
      {
         // Get the value of the vote that was clicked.
         voteValue = event.target.name.substr(1);
            
         if( cache ) {
            setVote( {value:voteValue} );
         }
         else {
            processVote();
         }
      }
      
      // Processes the cached vote.
      public function processVote()
      {
         // Check to see if the node Id is valid.
         if( nodeId ) {
            
            // If the vote value is zero then delete the vote.
            if( voteValue == 0 ) {
               dispatchEvent( new DashEvent( DashEvent.PROCESSING ) );	
               Service.call( Service.DELETE_VOTE, onVoteDelete, null, "node", nodeId, tag );
            }
            else {
               dispatchEvent( new DashEvent( DashEvent.PROCESSING ) );
               Service.call( Service.SET_VOTE, onVoteSet, null, "node", nodeId, voteValue, tag );
            }
         }
      }
      
      // The return function from Drupal.
      private function onVoteSet( vote:Object )
      {
         // Set the selected fill width
         setVote( {value: (userMode ? voteValue : vote.value)} );	
		 vote.voteType = userMode ? "userVote" : "vote";
         dispatchEvent( new DashEvent( DashEvent.VOTE_SET, vote ) );		
      }	
      
      private function onVoteDelete( vote:Object )
      {
			vote.type = userMode ? "userVote" : "vote";			
         dispatchEvent( new DashEvent( DashEvent.VOTE_DELETE, vote ) );
      }	
      
      // Called when the user hovers over a vote.
      private function onVoteOver( event:MouseEvent ) 
      {
         if( voter && voter.fill_mc ) {
            voter.fill_mc.width = event.target.name.substr(1);
         }
      }		
      
      // Called when the user moves his mouse out.
      private function onOut( event:MouseEvent ) 
      {
         if( voter && voter.fill_mc ) {
            voter.fill_mc.width = 0;
         }
      }		
      
      // Declare all of our child movie clips
      public var votes:MovieClip;
      public var selected:MovieClip;
      public var voter:MovieClip;	
      
      // Keep track of what mode we are in.
      private var userMode:Boolean;
      private var cache:Boolean;
      private var voteValue:Number;
      
      // Store the node Id and vote tag.
      private var nodeId:Number;
      private var tag:String;
   }
}