package ayyo.player.view.impl.controllbar {
	import flash.geom.Rectangle;
	import flash.display.Shape;
	import ayyo.player.view.api.IVolumeBar;

	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;
	import org.osflash.signals.natives.sets.InteractiveObjectSignalSet;

	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;

	/**
	 * @author Aziz Zaynutdinov (actionsmile at icloud.com)
	 */
	public class VolumeBar extends Sprite implements IVolumeBar {
		private static const WIDTH : uint = 40;
		[Embed(source="./../../../../../../assets/controlbar/icon.audio.png")]
		private var AudioGraphics : Class;
		/**
		 * @private
		 */
		private var isCreated : Boolean;
		/**
		 * @private
		 */
		private var _icon : Bitmap;
		/**
		 * @private
		 */
		private var _pattern : DashedPattern;
		/**
		 * @private
		 */
		private var _action : Signal;
		/**
		 * @private
		 */
		private var _matrix : Matrix;
		/**
		 * @private
		 */
		private var _signals : InteractiveObjectSignalSet;
		/**
		 * @private
		 */
		private var _alphaPattern : AlphaDashedPattern;
		/**
		 * @private
		 */
		private var _currentVolume : Number;
		/**
		 * @private
		 */
		private var _bar : Shape;

		public function VolumeBar(autoCreate : Boolean = true) {
			autoCreate && this.create();
		}

		public function create() : void {
			if (!this.isCreated) {
				this._matrix = new Matrix();
				this.mouseChildren = false;
				this._icon = new AudioGraphics() as Bitmap;
				this._pattern = new DashedPattern();
				this._alphaPattern = new AlphaDashedPattern();
				this._bar = new Shape();
				
				this._bar.x = 11;
				
				this.addChild(this._icon);
				this.addChild(this._bar);
				this.alpha = .8;
				this.volume = 1;
				
				const rect : Rectangle = this.getBounds(this);
				this.graphics.clear();
				this.graphics.beginFill(0, 0);
				this.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
				
				this.isCreated = true;
			}
		}

		public function enable() : void {
			this.signals.mouseDown.add(this.onMouseDown);
			this.signals.rollOver.add(this.onRolloverRollout);
			this.signals.rollOut.add(this.onRolloverRollout);
		}

		public function disable() : void {
			this.signals.mouseDown.remove(this.onMouseDown);
			this.signals.rollOver.remove(this.onRolloverRollout);
			this.signals.rollOut.remove(this.onRolloverRollout);
		}

		public function dispose() : void {
			if (this.isCreated) {
				this.isCreated = false;
			}
		}

		public function get view() : DisplayObject {
			return this;
		}

		public function get action() : ISignal {
			return this._action ||= new Signal(Number);
		}

		public function get signals() : InteractiveObjectSignalSet {
			return this._signals ||= new InteractiveObjectSignalSet(this);
		}

		public function set volume(value : Number) : void {
			if (!isNaN(value) && this._currentVolume != value) {
				value = value < 0 ? 0 : (value > 1 ? 1 : value);
				this._icon.alpha = value == 0 ? .3 : 1;
				const visibleBar : uint = value * WIDTH;
				this._bar.graphics.clear();
				this._bar.graphics.beginBitmapFill(this._alphaPattern);
				this._bar.graphics.drawRect(0, 0, WIDTH, 10);
				this._bar.graphics.beginBitmapFill(this._pattern);
				this._bar.graphics.drawRect(0, 0, visibleBar, 10);
				
				this._currentVolume = value;
				this.action.dispatch(this._currentVolume);
			}
		}

		// Handlers
		private function onMouseDown(event : MouseEvent) : void {
			this.stage.addEventListener(MouseEvent.MOUSE_UP, this.onMouseRelease);
			this.signals.enterFrame.add(this.onEnterFrame);
		}

		private function onEnterFrame(event : Event) : void {
			if (this.mouseX <= this.width && this.mouseX >= 0) this.volume = (this.mouseX - this._icon.width - this._icon.x) / WIDTH;
		}

		private function onMouseRelease(event : MouseEvent) : void {
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, this.onMouseRelease);
			this.signals.enterFrame.remove(this.onEnterFrame);
		}
		
		private function onRolloverRollout(event : MouseEvent) : void {
			this.alpha = event.type == MouseEvent.ROLL_OVER ? 1 : .8;
		}
	}
}
