/**
 *
 * AXLX Framework
 * Copyright 2014-2015 Denis Aleksandrowicz. All Rights Reserved.
 *
 * This program is free software. You can redistribute and/or modify it
 * in accordance with the terms of the accompanying license agreement.
 *
 */
package axl.xdef.types
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.utils.setTimeout;
	
	import axl.utils.U;
	import axl.utils.binAgent.RootFinder;
	import axl.xdef.XSupport;
	import axl.xdef.interfaces.ixDef;

	/** Master class for XML DisplayList projects. Treat it as your stage */
	public class xRoot extends xSprite
	{
		protected var xsupport:XSupport;
		protected var CONFIG:XML;
		private var rootFinder:RootFinder;
		/** General  loading resources PREFIX.<br><code>pathPrefixes</code> argument for <code>Ldr.load</code> method.
		 * All elements with "src" attribute are using this.
		 * @see axl.utils.Ldr#load()*/
		public var sourcePrefixes:Array;
		
		/** Master class for XML DisplayList projects. Treat it as your stage */
		public function xRoot(definition:XML=null)
		{
			if(xsupport == null)
				xsupport = new XSupport();
			if(xsupport.root == null)
				xsupport.root = this;
			this.xroot = this;
			
			if(rootFinder == null)
				rootFinder = new RootFinder(this,XSupport);
			super(definition);
		}
		/** Returns reference to XML config - the project definition */
		public function get config():XML { return CONFIG }
		/** &lt;root> element definition. Setting it up for the first time fires up chain
		 * of instantiation all sub elements 
		 * @see axl.xdef.XSupport#pushReadyTypes2() 
		 * @see axl.xdef.XSupport#applyAttributes() */
		override public function set def(value:XML):void
		{
			// as xRoot is not called via XSupport.getReadyType
			// it must take care of parsing definition itself
			if(value == null || super.def != null)
				return;
			super.def = value;
			xsupport.pushReadyTypes2(value, this,'addChildAt',this);
			XSupport.applyAttributes(value, this);
		}
		
		
		// ADD - REMOVE
		/** Adds or removes one or more elements (config xml nodes) to stage (xml root node).
		 * @param v - String or Array of Strings - must reffer to <code>name</code> attribute of requested config node
		 * @param underChild - depth controll -name of existing element under which addition will occur
		 * @param onNotExist - Function to execute if one or more elements does not exist
		 * in specified node. By default it throws Error. Passiong function helps treat it gracefully
		 * @param indexModificator - depth controll - modifes addition index when "underChild" specified
		 * @param node - config xml node within which elements of <code>v</code> name are searched for
		 * @param forceNewElement - if object(s) of v name are already instantiated (available within <code>registry</code>),
		 * no new object will be instantiated unless <code>forceNewElement</code> flag is set to <code>true</code>
		 * */
		public function add(v:Object,underChild:String=null,onNotExist:Function=null,indexModificator:int=0,node:String='additions',forceNewElement:Boolean=false):void
		{
			if(v is Array)
				getAdditionsByName(v as Array, gotit,node,onNotExist,forceNewElement);
			else
				getAdditionByName(v as String, gotit,node,onNotExist,forceNewElement)
			function gotit(d:DisplayObject):void{
				
				if(underChild != null)
					addUnderChild(d,underChild,indexModificator);
				else
					addChild(d);
			}
		}
		/** Adds or removes one or more elements (config xml nodes) to any instantiated DisplayObjectContainer descendants.
		 * @param v - String or Array of Strings - must reffer to <code>name</code> attribute of requested config node
		 * @param intoChild - target DisplayObjectContainer ("name", "$refference" or DisplayObjectContainer itself) to add "v" to.
		 * @param onNotExist - Function to execute if one or more elements does not exist
		 * in specified node. By default it throws Error. Passiong function helps treat it gracefully
		 * @param node - config xml node within which elements of <code>v</code> name are searched for
		 * @param forceNewElement - if object(s) of v name are already instantiated (available within <code>registry</code>),
		 * no new object will be instantiated unless <code>forceNewElement</code> flag is set to <code>true</code>
		 * */
		public function addTo(v:Object,intoChild:Object,command:String='addChild',onNotExist:Function=null,node:String='additions',forceNewElement:Boolean=false):void
		{
			if(intoChild is String && intoChild.charAt(0) == "$")
				intoChild = binCommand(intoChild.substr(1));
			if(intoChild is String)
				intoChild =  xsupport.registered(String(intoChild));
				
			var c:DisplayObjectContainer = intoChild as DisplayObjectContainer;
			if(c == null)
			{
				U.log(this, "[addTo][ERROR] 'intoChild' (" + intoChild +") parameter refers to non existing object or it's not a DisplayObjectContainer descendant");
				return
			}
				
			if(v is Array)
				getAdditionsByName(v as Array, gotIt,node,onNotExist,forceNewElement);
			else
				getAdditionByName(v as String, gotIt,node,onNotExist,forceNewElement);
			function gotIt(o:Object):void {
				U.log(this, o, o.name, '[addTo]', c, c.name, 'via', command);
				c[command](o);
			}
		}
		/** Adds DisplayObject underneath another child specified by it's name
		 * @v - DisplayObject to add
		 * @param chname - depth controll -name of existing element under which addition will occur
		 * */
		public function addUnderChild(v:DisplayObject, chname:String,indexMod:int=0):void
		{
			var o:DisplayObject = getChildByName(chname);
			
			var i:int = o ? this.getChildIndex(o) : -1;
			var j:int = contains(v) ? getChildIndex(v) : int.MAX_VALUE;
			if(j < i)
			{
				U.log("Child", v, v.name, "already exists in this container and it is under child", o, o? o.name : null);
				return;
			}
			if(i > -1)
			{
				i+= indexMod;
				if(i<0)
					i=0;
				if(i < this.numChildren)
					this.addChildAt(v,i);
				else
					this.addChild(v);
			}
			else this.addChild(v);
		}
		
		/** Returns first XML child of Config[node] which matches it name */
		public function getAdditionDefByName(v:String,node:String='additions'):XML
		{
			return this.CONFIG[node].*.(@name==v)[0];
		}
		/** Instantiates element from loaded config node. Instantiated / loaded / cached object
		 * is an argument for callback. 
		 * <br>All objects are being created within <code>XSupport.getReadyType2</code> function. 
		 * <br>All objects are being cached within <code>registry</code> dictionary where
		 * xml attribute <b>name</b> is key for it. 
		 * @param v - name of the object (must match any child of <code>node</code>). Objects
		 * are being looked up by <b>name</b> attribute. E.g. v= 'foo' for
		 *  <pre>
		 * &lt;node>&lt;div name="foo"/>&lt;/node>
		 * </pre> 
		 * @param callback - Function of one argument - loaded element. Function will be executed 
		 * once element is available (elements with <code>src</code> attribute may need to require loading of their contents).
		 * @param node - name of the XML tag (not an attrubute!) that is a parent for searched element to instantiate.
		 * @see axl.xdef.XSupport#getReadyType2()
		 */
		public function getAdditionByName(v:String, callback:Function, node:String='additions',onError:Function=null,forceNewElement:Boolean=false):void
		{
			U.log('[xRoot][getAdditionByName]', v);
			if(v == null)
				return U.log("[xRoot][getAdditionByName] requesting non existing element", v);
			if(v.charAt(0) == '$')
			{
				v = XSupport.simpleSourceFinder(this,v) as String;
				if(v == null)
					v='ERROR';
			}
			else if((registry[v] != null ) && !forceNewElement)
			{
				U.log('[xRoot][getAdditionByName]',v, 'already exists in xRoot.registry cache');
				callback(registry[v]);
				return;
			}
			
			var xml:XML = getAdditionDefByName(v,node);
			if(xml== null)
			{
				U.log('[xRoot][getAdditionByName][WARINING] REQUESTED CHILD "' + v + '" DOES NOT EXIST IN CONFIG "' + node +  '" NODE');
				if(onError == null) 
					throw new Error(v + ' does not exist in additions node');
				else
				{
					if(onError.length > 0)
						onError(v);
					else
						onError()
					return;
				}
			}
			xsupport.getReadyType2(xml, callback,true,null,this);
		}
		
		/** Executes <code>getAdditionByName</code> in a loop. @see #getAdditionByName() */
		public function getAdditionsByName(v:Array, callback:Function,node:String='additions',onError:Function=null,forceNewElement:Boolean=false):void
		{
			var i:int = 0, j:int = v.length;
			next();
			function next():void
			{
				if(i<j)
					getAdditionByName(v[i++], ready,node,onError,forceNewElement);
			}
			
			function ready(v:DisplayObject):void
			{
				callback(v);
				next()
			}
		}
		
		/** Removes elements from the display list. Accepts arrays of display objects, their names and mixes of it.
		 * Skipps objects which are not part of the display list. */
		public function remove(...args):void
		{
			rmv.apply(null,args);
		}
		/** If child of name specified in argument exists - removes it. All animtions are performed
		 * based on individual class settings (xBitmap, xSprite, xText, etc)*/
		public function removeByName(v:String):void	{ removeChild(getChildByName(v)) }
		
		/**  removes array of objects from displaylist. can be actual displayObjects or their names */
		public function removeElements(args:Array):void
		{
			for(var i:int = args.length; i-->0;)
				args[i] is String ? removeByName(args[i]) : removeChild(args[i]);
		}
		
		/**  Uses registry to define child to remove. This can reach inside containers to remove specific element.
		 * The last registered element of name defined in V will be removed */
		public function removeRegistered(v:String):void
		{
			var dobj:DisplayObject = xsupport.registered(v) as DisplayObject;
			U.log('removeRegistered', v, dobj, dobj ? dobj.parent != null : null)
			if(dobj != null && dobj.parent != null)
				dobj.parent.removeChild(dobj);
		}
		/** executes <code>removeRegistered</code> in a loop */
		public function removeRegisteredGroup(v:Array):void
		{
			for(var i:int = 0; i < v.length; i++)
				removeRegistered(v[i]);
		}
		
		/** Removes elements from the display list. Accepts arrays of display objects, their names and mixes of it.
		 * Skipps objects which are not part of the display list. */
		public function rmv(...args):void
		{
			for(var i:int = 0,j:int = args.length, v:Object; i < j; i++)
			{	
				v = args[i]
				if(v is String)
					removeRegistered(v as String);
				else if(v is Array)
					removeRegisteredGroup(v as Array);
				else if(v is DisplayObject)
					removeChild(v as DisplayObject)
				else
					U.log("[xRoot][rmv][WARNING] - Can't remove: " + v + " - is unknow type");
			}
		}
		/** Dictionary of all <b>instantiated</b> objects which can be identified by <code>name</code> attribute*/
		public function get registry():Object { return xsupport.registry }
		/** Returns any <b>instantiated</b> object which <code>name</code> equals <code>v</code>*/
		public function registered(v:String):Object { return  xsupport.registered(v) }

		/** Animates an object if it owns an animation definition defined by <code>screenName</code> 
		 * @param objName - name of animatable object on the displaylist if param <code>c</code> is null
		 * @param screenName - name of the animation definition
		 * @param onComplete callback to call when all animations are complete
		 * @param c -any animatable object that contains meta property
		 * @see axl.xdef.XSupport#animByNameExtra()
		 * */
		public function singleAnimByMetaName(objName:String, screenName:String, onComplete:Function=null,c:ixDef=null):void
		{
			c = c || this.getChildByName(objName) as ixDef;
			U.log("[xRoot][singleAnimByMetaName][", screenName, '] - ', objName, c);
			if(c != null && c.meta.hasOwnProperty(screenName))
				XSupport.animByNameExtra(c, screenName, onComplete);
			else
			{
				if(onComplete != null)
					setTimeout(onComplete, 5);
			}
		}
		/** Scans through all registered objects and executes animation on these which own <code>screenName</code>
		 * defined animation in their meta property
		 * @param screenName - name of the animation definition
		 * @param onComplete callback to call when all animations are complete
		 * @see #singleAnimByMetaName()
		 * */
		public function animateAllRegisteredToScreen(screenName:String,onComplete:Function=null):void
		{
			var all:int=0;
			var reg:Object = xsupport.registry;
			for(var s:String in reg)
			{
				var c:ixDef = reg[s] as ixDef;
				if(c != null && c.meta.hasOwnProperty(screenName))
				{
					all++;
					singleAnimByMetaName(c.name,screenName,singleComplete,c);
				}
			}
			if(all < 1 && onComplete != null)
				onComplete();
			function singleComplete():void
			{
				if(--all == 0 && onComplete !=null)
					onComplete();
			}
		}
		
		/** Executes function(s) from string (eval style)
		 * @param v - string or array of strings to evaluate
		 * @param debug <ul>
		 * <li>1 -logs errors only</li>
		 * <li>2 -logs result of every command</li>
		 * <li>other -no logging at all</li>
		 * </ul>
		 * @return - latest result of evaluation (last element of array if so)
		 * @see axl.utils.binAgent.RootFinder#parseInput()
		 * */
		public function binCommand(v:Object,debug:int=1):*
		{
			if(rootFinder != null)
			{
				var i:int =0,r:*,a:Array = (v is Array) ? v as Array: [v],j:int = a.length;
				switch (debug)
				{
					case 1:
						for(;i<j;i++)
						{
							r = rootFinder.parseInput(a[i]);
							if(r is Error)
								U.log("ERROR BIN COMMAND", a[i], '\n' + r);
						}
						return r;
					case 2:
						for(;i<j;i++)
						{
							r=rootFinder.parseInput(a[i])
							U.log("binCommand", r, 'result of:', a[i]);
						}
						return r;
					default:
						for(;i<j;i++)
							r = rootFinder.parseInput(a[i]);
						return r;
				}
			}
			else
				U.log("Parser not available");
			return r;
		}
		
		/** If Regexp(regexp) matches <code>sel</code> executes <code>add</code> with <code>onTrue</code> as an argument, otherwise
		 * executes it with onFalse. @see #add() */
		public function addIfMatches(sel:String,regexp:String='.*',onTrue:Object=null,onFalse:Object=null):void
		{
			if(sel && sel.match(new RegExp(regexp)))
			{
				try { add.apply(null, (onTrue is Array) ? onTrue : [onTrue]) }
				catch(e:*) { U.log(this, "[addIfMatches]ERROR: invalid argument onTrue:", onTrue) }
			}
			else
			{
				try { add.apply(null, (onFalse is Array) ? onFalse : [onFalse]) }
				catch(e:*) { U.log(this, "[addIfMatches]ERROR: invalid argument onFalse:", onFalse) }
			}
		}
		/** Depending on if Regexp(regexp) matches <code>sel</code> executes <code>executeFromXML</code> 
		 * with onTrue or onFalse arguments @see #executeFromXML() */
		public function executeIfMatches(sel:String,regexp:String,onTrue:String,onFalse:String,node:String='additions'):void
		{
			if(sel && sel.match(new RegExp(regexp)))
				executeFromXML(onTrue,node)
			else
				executeFromXML(onFalse,node)
		}
		/** Gets instantiated object from registry or instantiates new from <code>node</code> and
		 * calls <code>execute()</code> method on it if objects owns it (<code>&lt;btn>, &lt;act></code>)*/
		public function executeFromXML(name:String,node:String='additions'):void
		{
			this.getAdditionByName(name, gotIt,node, gotIt);
			function gotIt(v:*):void
			{
				if(v && v.hasOwnProperty('execute'))
					v.execute();
				else
					U.log("EXECUTE >>"+name+"<< NOT AVAILABLE", node);
			}
		}
	}
}