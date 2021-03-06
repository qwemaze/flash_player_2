package ayyo.player.view.impl.controllbar {
	import ayyo.player.core.model.PlayerCommands;

	import flash.display.Bitmap;
	import flash.events.MouseEvent;

	/**
	 * @author Aziz Zaynutdinov (actionsmile at icloud.com)
	 */
	public class ScreenStateSwitcher extends AbstractButton {
		[Embed(source="./../../../../../../assets/controlbar/normalscreen.png")]
		private var NormalscreenGraphics : Class;
		[Embed(source="./../../../../../../assets/controlbar/fullscreen.png")]
		private var FullscreenGraphics : Class;
		/**
		 * @private
		 */
		private var _fullscreen : Bitmap;
		/**
		 * @private
		 */
		private var _normalscreen : Bitmap;

		public function ScreenStateSwitcher(autoCreate : Boolean = true) {
			super(autoCreate);
		}

		override protected function createButton() : void {
			super.createButton();
			this._fullscreen = new FullscreenGraphics() as Bitmap;
			this._normalscreen = new NormalscreenGraphics() as Bitmap;
			this.alpha = .8;
			this.addChild(this._fullscreen);
			this.enable();
		}

		override protected function onButtonClick(event : MouseEvent) : void {
			super.onButtonClick(event);
			if (this._fullscreen.parent) {
				this._fullscreen.parent.removeChild(this._fullscreen);
				this.addChild(this._normalscreen);
				this.action.dispatch(PlayerCommands.FULLSCREEN);
			} else if (this._normalscreen.parent) {
				this._normalscreen.parent.removeChild(this._normalscreen);
				this.addChild(this._fullscreen);
				this.action.dispatch(PlayerCommands.NORMALSCREEN);
			}
		}

		override protected function enableButton() : void {
			super.enableButton();
			this.signals.rollOver.add(this.onRolloverRollout);
			this.signals.rollOut.add(this.onRolloverRollout);
		}
		
		override protected function disableButton() : void {
			super.disableButton();
			this.signals.rollOver.remove(this.onRolloverRollout);
			this.signals.rollOut.remove(this.onRolloverRollout);
		}
		
		//	Handlers
		private function onRolloverRollout(event : MouseEvent) : void {
			this.alpha = event.type == MouseEvent.ROLL_OVER ? 1 : .8;
		}
	}
}
