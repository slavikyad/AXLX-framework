package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.ColorTransform;
	
	import axl.utils.AO;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDisplay;
	
	public class xSprite extends Sprite implements ixDisplay
	{
		public var onElementAdded:Function;
		
		protected var xdef:XML;
		protected var xmeta:Object={};
		public var onAnimationComplete:Function;
		private var eventAnimComplete:Event = new Event(Event.COMPLETE);
		
		protected var xfilters:Array
		protected var xtrans:ColorTransform;
		protected var xtransDef:ColorTransform;
		
		public function xSprite(definition:XML=null)
		{
			addEventListener(Event.ADDED, elementAdded);
			addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			xdef = definition;
			super();
			parseDef();
		}
		
		protected function addedToStageHandler(e:Event):void
		{
			if(meta.addedToStage == null)
				return;
			this.reset();
			XSupport.animByName(this, 'addedToStage', animComplete);
		}
		
		protected function elementAdded(e:Event):void
		{
			if(onElementAdded != null)
				onElementAdded(e);
		}
		
		public function get def():XML { return xdef }
		public function get meta():Object { return xmeta }
		public function set meta(v:Object):void { xmeta =v }
		public function get eventAnimationComplete():Event {return eventAnimComplete }
		public function reset():void { 
			AO.killOff(this);
			XSupport.applyAttributes(def, this);	
		}

		public function set def(value:XML):void { 
			xdef = value;
			parseDef();
		}
		
		private function animComplete():void {	this.dispatchEvent(this.eventAnimationComplete) }
		
		override public function addChild(child:DisplayObject):DisplayObject
		{
			super.addChild(child);
			var c:ixDisplay = child as ixDisplay;
			if(c != null && c.meta.addChild != null)
			{
				c.reset();
				XSupport.animByName(c, 'addChild', animComplete);
			}
			return child;
		}
		
		override public function addChildAt(child:DisplayObject, index:int):DisplayObject
		{
			super.addChildAt(child, index);
			var c:ixDisplay = child as ixDisplay;
			if(c != null && c.meta.addChild != null)
			{
				c.reset();
				XSupport.animByName(c, 'addChild',animComplete);
			}
			return child;
		}
		
		override public function removeChild(child:DisplayObject):DisplayObject
		{
			if(child == null)
				return child;
			var f:Function = super.removeChild;
			var c:ixDisplay = child as ixDisplay;
			if(c != null)
			{
				AO.killOff(c);
				XSupport.animByName(c, 'removeChild', acomplete);
			} else { acomplete() }
			function acomplete():void { f(child) }
			return child;
		}
		
		override public function removeChildAt(index:int):DisplayObject
		{
			var f:Function = super.removeChildAt;
			var c:ixDisplay = super.getChildAt(index) as ixDisplay;
			if(c != null)
			{
				AO.killOff(c);
				XSupport.animByName(c, 'removeChild', acomplete);
			} else { acomplete() } 
			function acomplete():void { f(index) }
			return c as DisplayObject;
		}
		
		protected function parseDef():void
		{
			if(xdef==null)
				return;
			XSupport.drawFromDef(def.graphics[0], this);
			XSupport.pushReadyTypes(def, this);
			XSupport.applyAttributes(def, this);
			//xtransform = this.transform.colorTransform;
		}
		
		public function get xtransform():ColorTransform { return xtrans }
		public function set xtransform(v:ColorTransform):void { xtrans =v; this.transform.colorTransform = v;
			if(xtransDef == null)
				xtransDef = new ColorTransform();
		}
		public function set transformOn(v:Boolean):void { this.transform.colorTransform = (v ? xtrans : xtransDef ) }
		
		override public function set filters(v:Array):void
		{
			xfilters = v;
			super.filters=v;
		}
		
		public function set filtersOn(v:Boolean):void {	super.filters = (v ? xfilters : null) }
		public function get filtersOn():Boolean { return filters != null }
		
		
		public function ctransform(prop:String,val:Number):void {
			if(!xtrans)
				xtrans = new ColorTransform();
			xtrans[prop] = val;
			this.transform.colorTransform = xtrans;
		}
		
		public function linkButton(xmlName:String, onClick:Function):xButton
		{
			var b:xButton = getChildByName(xmlName) as xButton;
			if(b != null)
			{
				b.onClick = onClick;
				this.setChildIndex(b, this.numChildren-1);
			}
			return b;
		}
	}
}