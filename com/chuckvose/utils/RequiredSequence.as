package com.chuckvose.utils
{
	import flash.events.*;
	import flash.utils.*;
	
	public class RequiredSequence extends EventDispatcher
	{
		public var flags:Object;
		public var callingClass:Object;
		public var timers:Object;
		
		public static const WAKEUP:String = 'wakeup';
		
		public function RequiredSequence (_callingClass:USAToday)
		{
			callingClass = _callingClass;
			timers = new Object();
			flags = new Object();
		}
		
		/**
		 * Declare our interest in event dispatches with the string flagName. When
		 * we see one of these events dispatched notify all listeners that a new 
		 * event has fired so that they can check to see if their conditions are
		 * satisfied
		 * 
		 * @param flagName String the string that will be dispatched when the 
		 * event we're waiting for is completed
		 */
		public function addFlag(flagName:String):void
		{
			if (flags[flagName] == null) {
				flags[flagName] = false;
			}
			callingClass.addEventListener(flagName, completeFlag);
		}
		
		/**
		 * Watch for an event dispatch with the string flagName and run f when
		 * we see it. If we already have a note that flagName has been seen
		 * then we just get to run f. 
		 * 
		 * @param flagName String the string that will be dispatched when the 
		 * event we're waiting for is completed
		 * @param f Function the function that we will run after we see the
		 * event dispatch we're interested in.
		 */
		public function requireFlag (flagName : String, f : Function):void
		{
			if (isComplete(flagName)) {
				f.call();
			}
			else {
				addFlag(flagName);
				addEventListener(RequiredSequence.WAKEUP, function g (e:Event) {
					if (isComplete(flagName)) {
						stopWatching(flagName, g);
						f.call();
					}
				});
			}
		}
		
		/**
		 * Watch for an event dispatch with the string flagName and run f when
		 * we see it. If we already have a note that flagName has been seen
		 * then we just get to run f. Unlike requireFlag this will repeatedly
		 * fire for events so it'll work for the Observer model. 
		 * 
		 * @param flagName String the string that will be dispatched when the 
		 * event we're waiting for is completed
		 * @param f Function the function that we will run after we see the
		 * event dispatch we're interested in.
		 * @see requireFlag
		 */
		public function requireFlagRepeatedly (flagName : String, f : Function):void
		{
			if (isComplete(flagName) && flags[flagName] != null) {
				f.call();
				unComplete(flagName);
			}
			else {
				addFlag(flagName);
				addEventListener(RequiredSequence.WAKEUP, function g (e:Event) {
					if (isComplete(flagName)) {
						f.call();
						unComplete(flagName);
					}
				});
			}
		}
		
		/**
		 * Require this flag and retry n times until we get it damnit!
		 * 
		 * @param flagName String the string that will be dispatched when the 
		 * event we're waiting for is completed
		 * @param retry Function the function that will eventually dispatch the
		 * string we're waiting for
		 * @param after Function the function that we will run after we see the
		 * event dispatch we're interested in.
		 * 
		 * @see requireFlag
		 */
		public function requireFlagWithRetry (flagName : String, retry : Function, after : Function = null, retries = 5, timeout = 2000):void 
		{
			timers[flagName] = new Timer(timeout, retries);
			timers[flagName].start();
			timers[flagName].addEventListener('timer', function () {
				retry.call();
			});
			
			if (isComplete(flagName)) {
				after.call();
				timers[flagName].stop();
			}
			else {
				addFlag(flagName);
				addEventListener(RequiredSequence.WAKEUP, function g (e:Event) {
					if (isComplete(flagName)) {
						stopWatching(flagName, g);
						after.call();
						timers[flagName].stop();
					}
				});
			}
		}
		
		/**
		 * Require this flag and retry n times until we get it damnit! If that
		 * doesn't pan out though we should probably just error out and run some 
		 * consolation function
		 * 
		 * @param flagName String the string that will be dispatched when the 
		 * event we're waiting for is completed
		 * @param retry Function the function that will eventually dispatch the
		 * string we're waiting for
		 * @param after Function the function that we will run after we see the
		 * event dispatch we're interested in.
		 * @param consolation Function the function that gets run if we run out 
		 * of retries
		 * 
		 * @see requireFlag
		 */
		public function requireFlagWithRetryAndFailure (flagName : String, retry : Function, after : Function, consolation : Function, retries = 5, timeout = 2000):void 
		{
			timers[flagName] = new Timer(timeout, retries);
			timers[flagName].start();
			timers[flagName].addEventListener('timer', function () {
				retry.call();
			});
			timers[flagName].addEventListener('timerComplete', function () {
				consolation.call();
			});
			
			if (isComplete(flagName)) {
				after.call();
				timers[flagName].stop();
			}
			else {
				addFlag(flagName);
				addEventListener(RequiredSequence.WAKEUP, function g (e:Event) {
					if (isComplete(flagName)) {
						stopWatching(flagName, g);
						after.call();
						timers[flagName].stop();
					}
				});
			}
		}
		
		/**
		 * Require this flag and retry n times until we get it damnit!
		 * 
		 * @param flagName String the string that will be dispatched when the 
		 * event we're waiting for is completed
		 * @param retry Function the function that will eventually dispatch the
		 * string we're waiting for
		 * @param after Function the function that we will run after we see the
		 * event dispatch we're interested in.
		 * 
		 * @see requireFlag
		 */
		public function requireFlagWithFailure (flagName : String, after : Function, consolation : Function, timeout = 2000):void 
		{
			timers[flagName] = new Timer(timeout, 1);
			timers[flagName].start();
			timers[flagName].addEventListener('timerComplete', function () {
				consolation.call();
			});
			
			if (isComplete(flagName)) {
				after.call();
				timers[flagName].stop();
			}
			else {
				addFlag(flagName);
				addEventListener(RequiredSequence.WAKEUP, function g (e:Event) {
					if (isComplete(flagName)) {
						stopWatching(flagName, g);
						after.call();
						timers[flagName].stop();
					}
				});
			}
		}
		
		/**
		 * Convinience function to require multiple flags for a sequence. Can't
		 * be run as a retry unfortunately.
		 * 
		 * @param flags Array an Array of strings that will be dispatched when the 
		 * events we're waiting for is completed
		 * @param f Function the function that we will run after we see the
		 * event dispatches we're interested in.
		 * @see requireFlag
		 */
		public function requireFlags (flags : Array, f : Function):void
		{
			var goodToGo:Boolean = true;
			for each (var flagName:String in flags) {
				if (!isComplete(flagName)) {
					goodToGo = false;
					break;
				}
			}
			if (goodToGo) {
				f();
			}
			else {
				for (flagName in flags) {
					addFlag(flagName);
				}
				addEventListener(RequiredSequence.WAKEUP, function g (e:Event) {
					var goodToGo:Boolean = true;
					for each (var flagName:String in flags) {
						if (!isComplete(flagName)) {
							goodToGo = false;
							break;
						}
					}
					if (goodToGo) {
						stopWatchingGroup(flags, g);
						f();
					}
				});
			}
		}
		
		/**
		 * Notify all subscribers that a new event is in so they can check to see
		 * if all their conditions are satisfied.
		 * 
		 * @param e Event 
		 * @see requireFlag
		 */
		public function completeFlag(e:Event):void
		{
			flags[e.type] = true;
			dispatchEvent(new Event(RequiredSequence.WAKEUP));
		}
		
		/**
		 * We're finally satisfied so we'll unsubscribe this flag. This is usually
		 * done directly by using requireFlag
		 * 
		 * @param flagName String the string that will be dispatched when the 
		 * event we're waiting for is completed
		 * @param f Function the function that we will run after we see the
		 * event dispatch we're interested in. (Note: this function will not
		 * be run again, it's merely needed to remove the listener)
		 */
		public function stopWatching(flagName : String, f : Function):void
		{
			callingClass.removeEventListener(flagName, completeFlag);
			removeEventListener(RequiredSequence.WAKEUP, f);
		}
		
		/**
		 * We're finally satisfied so we'll unsubscribe these flags. This is usually
		 * done directly by using requireFlags
		 * 
		 * @param flags Array an Array of strings that will be dispatched when the 
		 * events we're waiting for are completed
		 * @param f Function the function that we will run after we see the
		 * event dispatch we're interested in. (Note: this function will not
		 * be run again, it's merely needed to remove the listener)
		 * @see stopWatching
		 */
		public function stopWatchingGroup(flags : Array, f : Function):void
		{
			for each (var flagName:String in flags) {
				stopWatching(flagName, f);
			}
		}
		
		/**
		 * Many events want to stay subscribed to the list but they need to have
		 * their state reset so that they aren't run each time ANY event comes in. 
		 * Because we send one generic event dispatch any time any of our registered
		 * events completes we need to reset the flag's success state.
		 * 
		 * @param flagName String the string that will be dispatched when the 
		 * event we're waiting for is completed
		 */
		public function unComplete(flagName:String):void
		{
			flags[flagName] = false;
		}
		
		/**
		 * Are we interested in this flag already?
		 * 
		 * @param flagName String the string that will be dispatched when the 
		 * event we're waiting for is completed
		 * @return Boolean whether or not this flag exists in the watchlist
		 */
		public function hasFlag(flagName:String):Boolean
		{
			return flags.hasProperty(flagName);
		}
		
		/**
		 * Has this event already fired?
		 * 
		 * @param flagName String the string that will be dispatched when the 
		 * event we're waiting for is completed
		 * @return Boolean whether or not this flag is marked as having fired or not
		 */
		public function isComplete(flagName:String):Boolean
		{
			return flags[flagName];
		}
	}
}