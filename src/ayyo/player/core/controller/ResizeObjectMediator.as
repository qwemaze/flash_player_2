package ayyo.player.core.controller {
	import org.osmf.media.MediaPlayerSprite;
	import robotlegs.bender.framework.api.ILogger;
	import flash.geom.Rectangle;
	import me.scriptor.additional.api.IResizable;

	import robotlegs.bender.extensions.mediatorMap.api.IMediator;

	import org.osflash.signals.ISignal;
	import org.osflash.signals.natives.NativeSignal;

	import flash.events.Event;
	import flash.events.IEventDispatcher;

	/**
	 * @author Aziz Zaynutdinov (actionsmile at icloud.com)
	 */
	public class ResizeObjectMediator implements IMediator {
		[Inject]
		public var item : IResizable;
		[Inject(name="screen")]
		public var screen : Rectangle;
		[Inject]
		public var dispatcher : IEventDispatcher;
		[Inject]
		public var logger : ILogger;
		[Inject]
		public var player : MediaPlayerSprite;
		/**
		 * @private
		 */
		private var _reszied : ISignal;

		public function initialize() : void {
			this.logger.debug("{0} under resize controll", [this.item]);
			this.reszied.add(this.onApplicationReszied);
			this.onApplicationReszied(null);
		}

		public function destroy() : void {
			this.reszied.remove(this.onApplicationReszied);
			this.dispatcher = null;
			this.item = null;
			this.screen = null;
			this.logger = null;
			this._reszied = null;
		}

		public function get reszied() : ISignal {
			return this._reszied ||= new NativeSignal(this.dispatcher, Event.RESIZE);
		}

		// Handlers
		/**
		 * @eventType flash.events.Event.RESIZE
		 */
		private function onApplicationReszied(event : Event) : void {
			this.player.width = this.screen.width;
			this.player.height = this.screen.height;
			this.item.resize(this.screen.clone());
		}
	}
}
