/*
	Author:  Abdul Qabiz (abdulqabiz3@yahoo.com) 
	Copyright (c) 2007 Abdul Qabiz (http://www.abdulqabiz.com)
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
	in the documentation and/or other materials provided with the distribution.
	* Neither the name of the <ORGANIZATION> nor the names of its contributors may be used to endorse
	or promote products derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
	A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
	PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package com.abdulqabiz.utils
{
	import mx.managers.CursorManager;
	import mx.core.UIComponent;
	import flash.events.*;


	public class CursorPool extends Object
	{
		static private var instance:CursorPool = null;

		static public function getInstance ():CursorPool
		{
			if (!instance)
			{
				instance = new CursorPool ();
			}

			return instance;
		}

		
		private var registry:Object;
		private var cursorID:int;


		public function CursorPool ()
		{
			registry = new Object ();
		}

		public function register (component:UIComponent, cursorAttributes:CursorAttributes):void
		{
			if (component)
			{
				registry[String (component)] = cursorAttributes;
				component.addEventListener ("mouseOver", handleMouseOver);
				component.addEventListener ("mouseOut", handleMouseOut);
			}
		}

		public function unregister (component:UIComponent):void
		{
			component.removeEventListener ("mouseOver", handleMouseOver);
			component.removeEventListener ("mouseOut", handleMouseOut);
			delete registry[String (component)];
		}

		private function handleMouseOver (event:MouseEvent):void
		{
			var component:UIComponent = UIComponent (event.target);
			var ca:CursorAttributes = registry[String (component)];
			
			if (cursorID)
			{
				CursorManager.removeCursor (cursorID);
			}
			cursorID = CursorManager.setCursor (ca.cursorType, ca.priority, ca.xOffset, ca.yOffset);
		}

		private function handleMouseOut (event:MouseEvent):void
		{
			CursorManager.removeCursor (cursorID);		
		}
	}


}
