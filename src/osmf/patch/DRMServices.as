/*****************************************************
 *  
 *  Copyright 2009 Adobe Systems Incorporated.  All Rights Reserved.
 *  
 *****************************************************
 *  The contents of this file are subject to the Mozilla Public License
 *  Version 1.1 (the "License"); you may not use this file except in
 *  compliance with the License. You may obtain a copy of the License at
 *  http://www.mozilla.org/MPL/
 *   
 *  Software distributed under the License is distributed on an "AS IS"
 *  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 *  License for the specific language governing rights and limitations
 *  under the License.
 *   
 *  
 *  The Initial Developer of the Original Code is Adobe Systems Incorporated.
 *  Portions created by Adobe Systems Incorporated are Copyright (C) 2009 Adobe Systems 
 *  Incorporated. All Rights Reserved. 
 *  
 *****************************************************/
// Rustem EQUAL
package osmf.patch {
	import org.osmf.events.DRMEvent;
	import org.osmf.events.MediaError;
	import org.osmf.events.MediaErrorCodes;
	import org.osmf.traits.DRMState;
	import org.osmf.utils.OSMFStrings;

	import flash.errors.IllegalOperationError;
	import flash.events.DRMAuthenticationCompleteEvent;
	import flash.events.DRMAuthenticationErrorEvent;
	import flash.events.DRMErrorEvent;
	import flash.events.DRMStatusEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.StatusEvent;
	import flash.net.drm.DRMContentData;
	import flash.net.drm.DRMManager;
	import flash.net.drm.DRMVoucher;
	import flash.net.drm.LoadVoucherSetting;
	import flash.system.SystemUpdater;
	import flash.system.SystemUpdaterType;
	import flash.utils.ByteArray;

	[ExcludeClass]
	/**
	 * Dispatched when either anonymous or credential-based authentication is needed in order
	 * to playback the media.
	 *
	 * @eventType org.osmf.events.DRMEvent.DRM_STATE_CHANGE
	 */
	[Event(name='drmStateChange', type='org.osmf.events.DRMEvent')]
	/**
	 * @private
	 * 
	 * The DRMServices class is a utility class to adapt the Flash Player's DRM
	 * to the OSMF-style DRM API.  DRMServices handles triggering updates to
	 * the DRM subsystem, as well as triggering the appropriate events when
	 * authentication is needed, complete, or failed.
	 *  
	 *  @langversion 3.0
	 *  @playerversion Flash 10.1
	 *  @playerversion AIR 1.5
	 *  @productversion OSMF 1.0
	 */
	// internal class DRMServices extends EventDispatcher
	public class DRMServices extends EventDispatcher {
		/**
		 * @private
		 */
		private var _drmManager : DRMManager;
		// The flash player's internal DRM error codes
		/**
		 * @private 
		 */
		public static const DRM_AUTHENTICATION_FAILED : int = 3301;
		/**
		 * @private 
		 */
		public static const DRM_NEEDS_AUTHENTICATION : int = 3330;
		/**
		 * @private 
		 */
		public static const DRM_CONTENT_NOT_YET_VALID : int = 3331;
		private var _drmState : String = DRMState.UNINITIALIZED;
		private var _lastToken : ByteArray;
		private var drmContentData : DRMContentData;
		private var voucher : DRMVoucher;
		private var _customToken : ByteArray;
		// Rustem
		// this is static, since the SystemUpdater needs to be trated as a singleton.  Only one update at a time.
		private static var UPDATER : SystemUpdater;

		/**
		 * Constructor.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.0
		 *  
		 */
		public function get drmManager() : DRMManager {
			return this._drmManager ||= DRMManager.getDRMManager();
		}

		/**
		 * The current state of the DRM for this media.  The states are explained
		 * in the DRMState enumeration in the org.osmf.drm package.
		 * @see DRMState
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.0
		 */
		public function get drmState() : String {
			return _drmState;
		}

		// Rustem
		public function set lastToken(bytes : ByteArray) : void {
			this.lastToken.clear();
			this.lastToken.writeBytes(bytes);
		}

		public function get lastToken() : ByteArray {
			return this._lastToken ||= new ByteArray();
		}

		/**
		 * The metadata property is specific to the DRM for the Flash Player.  Once set, authentication
		 * and voucher retrieval is started.  This method may trigger an update to the DRM subsystem.  Metadata
		 * forms the basis for content data.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.0
		 */
		public function set drmMetadata(value : Object) : void {
			this.lastToken.clear();
			if (value is DRMContentData) {
				this.drmContentData = value as DRMContentData;
				this.retrieveVoucher();
			} else {
				try {
					this.drmContentData = new DRMContentData(value as ByteArray);
					this.retrieveVoucher();
				} catch (argError : ArgumentError) {
					this.updateDRMState(DRMState.AUTHENTICATION_ERROR, new MediaError(argError.errorID, "DRMContentData invalid"));
				} catch (error : IllegalOperationError) {
					function onComplete(event : Event) : void {
						DRMServices.UPDATER.removeEventListener(Event.COMPLETE, onComplete);
						drmMetadata = value;
					}

					this.update(SystemUpdaterType.DRM);
					DRMServices.UPDATER.addEventListener(Event.COMPLETE, onComplete);
				}
			}
		}

		public function get drmMetadata() : Object {
			return drmContentData;
		}

		/**
		 * Authenticates the media.  Can be used for both anonymous and credential-based
		 * authentication.
		 * 
		 * @param username The username.  Should be null for anonymous authentication.
		 * @param password The password.  Should be null for anonymous authentication.
		 * 
		 * @throws IllegalOperationError If the metadata hasn't been set.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.0
		 */
		public function authenticate(username : String = null, password : String = null) : void {
			if (drmContentData == null) {
				throw new IllegalOperationError(OSMFStrings.getString(OSMFStrings.DRM_METADATA_NOT_SET));
			}
			this.drmManager.addEventListener(DRMAuthenticationErrorEvent.AUTHENTICATION_ERROR, this.authError);
			this.drmManager.addEventListener(DRMAuthenticationCompleteEvent.AUTHENTICATION_COMPLETE, this.authComplete);

			if (password == null && username == null) {
				this.retrieveVoucher();
			} else {
				this.drmManager.authenticate(drmContentData.serverURL, drmContentData.domain, username, password);
			}
		}

		/**
		 * Authenticates the media using an object which serves as a token.  Can be used
		 * for both anonymous and credential-based authentication.
		 * 
		 * @param token The token to use for authentication.
		 * 
		 * @throws IllegalOperationError If the metadata hasn't been set.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.0
		 */
		public function authenticateWithToken(token : Object) : void {
			if (drmContentData == null) {
				throw new IllegalOperationError(OSMFStrings.getString(OSMFStrings.DRM_METADATA_NOT_SET));
			}
			drmManager.setAuthenticationToken(drmContentData.serverURL, drmContentData.domain, token as ByteArray);
			retrieveVoucher();
		}

		/**
		 * Returns the start date for the playback window.  Returns null if authentication 
		 * hasn't taken place.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.0
		 */
		public function get startDate() : Date {
			if (voucher != null) {
				return voucher.playbackTimeWindow ? voucher.playbackTimeWindow.startDate : voucher.voucherStartDate;
			} else {
				return null;
			}
		}

		/**
		 * Returns the end date for the playback window.  Returns null if authentication 
		 * hasn't taken place.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.0
		 */
		public function get endDate() : Date {
			if (voucher != null) {
				return voucher.playbackTimeWindow ? voucher.playbackTimeWindow.endDate : voucher.voucherEndDate;
			} else {
				return null;
			}
		}

		/**
		 * Returns the length of the playback window, in seconds.  Returns NaN if
		 * authentication hasn't taken place.
		 * 
		 * Note that this property will generally be the difference between startDate
		 * and endDate, but is included as a property because there may be times where
		 * the duration is known up front, but the start or end dates are not (e.g. a
		 * one week rental).
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.0
		 */
		public function get period() : Number {
			if (voucher != null) {
				return voucher.playbackTimeWindow ? voucher.playbackTimeWindow.period : (voucher.voucherEndDate && voucher.voucherStartDate) ? (voucher.voucherEndDate.time - voucher.voucherStartDate.time) / 1000 : 0;
			} else {
				return NaN;
			}
		}

		/**
		 * @private
		 * 
		 * Signals failures from the DRMsubsystem not captured though the 
		 * DRMServices class.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.0
		 */
		public function inlineDRMFailed(error : MediaError) : void {
			updateDRMState(DRMState.AUTHENTICATION_ERROR, error);
		}

		/**
		 * @private
		 * Signals DRM is available, taken from the inline netstream APIs.
		 * Assumes the voucher is available.
		 * 	
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.0
		 */
		public function inlineOnVoucher(event : DRMStatusEvent) : void {
			drmContentData = event.contentData;
			onVoucherLoaded(event);
		}

		/**
		 * @private
		 * 
		 * Triggers and update of the DRM subsystem.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.0
		 */
		public function update(type : String) : SystemUpdater {
			updateDRMState(DRMState.DRM_SYSTEM_UPDATING);
			if (DRMServices.UPDATER == null) // An update hasn't been triggered
			{
				DRMServices.UPDATER = new SystemUpdater();
				// If there is an update already happening, just wait for it to finish.
				this.toggleErrorListeners(DRMServices.UPDATER, true);
				DRMServices.UPDATER.update(type);
			} else {
				// If there is an update already happening, just wait for it to finish.
				this.toggleErrorListeners(DRMServices.UPDATER, true);
			}

			return DRMServices.UPDATER;
		}

		// Rustem
		public function set customTokenString(bytes : String) : void {
			this.customToken.clear();
			this.customToken.writeUTFBytes(bytes);
		}

		public function get customToken() : ByteArray {
			return this._customToken ||= new ByteArray();
		}

		// Rustem/
		// Internals
		//
		/**
		 * Downloads the voucher for the metadata specified.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10.1
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.0
		 */
		private function retrieveVoucher() : void {
			updateDRMState(DRMState.AUTHENTICATING);

			drmManager.addEventListener(DRMErrorEvent.DRM_ERROR, onDRMError);
			drmManager.addEventListener(DRMStatusEvent.DRM_STATUS, onVoucherLoaded);
			// Rustem
			this.drmManager.setAuthenticationToken(this.drmContentData.serverURL, this.drmContentData.domain, this.customToken);
			// Rustem/
			drmManager.loadVoucher(drmContentData, LoadVoucherSetting.ALLOW_SERVER);
		}

		private function onVoucherLoaded(event : DRMStatusEvent) : void {
			if (event.contentData == drmContentData) {
				var now : Date = new Date();
				if (event.voucher && (
				(   event.voucher.voucherEndDate == null || event.voucher.voucherEndDate.time >= now.time) && (   event.voucher.voucherStartDate == null || event.voucher.voucherStartDate.time <= now.time)
				)
				) {
					this.voucher = event.voucher;
					this.removeEventListeners();

					if (voucher.playbackTimeWindow == null) {
						this.updateDRMState(DRMState.AUTHENTICATION_COMPLETE, null, voucher.voucherStartDate, voucher.voucherEndDate, period, this.lastToken);
					} else {
						this.updateDRMState(DRMState.AUTHENTICATION_COMPLETE, null, voucher.playbackTimeWindow.startDate, voucher.playbackTimeWindow.endDate, voucher.playbackTimeWindow.period, this.lastToken);
					}
				} else  // Only force refresh if voucher was good, and has expired (local voucher).
				{
					this.forceRefreshVoucher();
				}
			}
		}

		// Rustem
		public function forceRefresh() : void {
			return;
		}

		// Rustem/
		private function forceRefreshVoucher() : void {
			this.drmManager.setAuthenticationToken(this.drmContentData.serverURL, this.drmContentData.domain, this.customToken);
			this.drmManager.loadVoucher(this.drmContentData, LoadVoucherSetting.FORCE_REFRESH);
		}

		private function onDRMError(event : DRMErrorEvent) : void {
			if (event.contentData == this.drmContentData) {
				switch(event.errorID) {
					case DRM_CONTENT_NOT_YET_VALID:
						this.forceRefreshVoucher();
						break;
					case DRM_NEEDS_AUTHENTICATION:
						this.updateDRMState(DRMState.AUTHENTICATION_NEEDED, null, null, null, 0, null, event.contentData.serverURL);
						break;
					default:
						this.removeEventListeners();
						this.updateDRMState(DRMState.AUTHENTICATION_ERROR, new MediaError(event.errorID, event.text));
						break;
				}
			}
		}

		private function removeEventListeners() : void {
			this.drmManager.removeEventListener(DRMErrorEvent.DRM_ERROR, onDRMError);
			this.drmManager.removeEventListener(DRMStatusEvent.DRM_STATUS, onVoucherLoaded);
		}

		private function authComplete(event : DRMAuthenticationCompleteEvent) : void {
			this.drmManager.removeEventListener(DRMAuthenticationErrorEvent.AUTHENTICATION_ERROR, authError);
			this.drmManager.removeEventListener(DRMAuthenticationCompleteEvent.AUTHENTICATION_COMPLETE, authComplete);
			this.lastToken = event.token;
		}

		private function authError(event : DRMAuthenticationErrorEvent) : void {
			this.drmManager.removeEventListener(DRMAuthenticationErrorEvent.AUTHENTICATION_ERROR, authError);
			this.drmManager.removeEventListener(DRMAuthenticationCompleteEvent.AUTHENTICATION_COMPLETE, authComplete);

			this.updateDRMState(DRMState.AUTHENTICATION_ERROR, new MediaError(event.errorID, event.toString()));
		}

		private function toggleErrorListeners(updater : SystemUpdater, on : Boolean) : void {
			if (on) {
				updater.addEventListener(Event.COMPLETE, onUpdateComplete);
				updater.addEventListener(Event.CANCEL, onUpdateComplete);
				updater.addEventListener(IOErrorEvent.IO_ERROR, onUpdateError);
				updater.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onUpdateError);
				updater.addEventListener(StatusEvent.STATUS, onUpdateError);
			} else {
				updater.removeEventListener(Event.COMPLETE, onUpdateComplete);
				updater.removeEventListener(Event.CANCEL, onUpdateComplete);
				updater.removeEventListener(IOErrorEvent.IO_ERROR, onUpdateError);
				updater.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onUpdateError);
				updater.removeEventListener(StatusEvent.STATUS, onUpdateError);
			}
		}

		private function onUpdateComplete(event : Event) : void {
			this.toggleErrorListeners(DRMServices.UPDATER, false);
		}

		private function onUpdateError(event : Event) : void {
			this.toggleErrorListeners(DRMServices.UPDATER, false);
			this.updateDRMState(DRMState.AUTHENTICATION_ERROR, new MediaError(MediaErrorCodes.DRM_SYSTEM_UPDATE_ERROR, event.toString()));
		}

		private function updateDRMState(newState : String, error : MediaError = null, start : Date = null, end : Date = null, period : Number = 0, token : Object = null, prompt : String = null) : void {
			this._drmState = newState;
			this.dispatchEvent(new DRMEvent(DRMEvent.DRM_STATE_CHANGE, newState, false, false, start, end, period, prompt, token, error));
		}
	}
}
