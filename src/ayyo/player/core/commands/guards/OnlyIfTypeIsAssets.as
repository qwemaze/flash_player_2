package ayyo.player.core.commands.guards {
	import ayyo.player.core.model.DataType;
	import ayyo.player.events.BinDataEvent;

	import robotlegs.bender.framework.api.IGuard;

	/**
	 * @author Aziz Zaynutdinov (actionsmile at icloud.com)
	 */
	public class OnlyIfTypeIsAssets implements IGuard {
		[Inject]
		public var event : BinDataEvent;

		public function approve() : Boolean {
			var result : Boolean = this.event.dataType == DataType.ASSETS;
			this.event = null;
			return result;
		}
	}
}
