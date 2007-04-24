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

/*  JavaScript: A MXML component for embedding Javascript in container HTML
 *  Author:  Abdul Qabiz (abdulqabiz3@yahoo.com) 
 *  Date:    June 16, 2006
 *  Version: 0.2
 *  @Updated on March 5, 2007 - remove comments from JS source before injecting.
 *  
*/

package com.abdulqabiz.utils
{


import flash.events.Event;
import flash.events.EventDispatcher;
import flash.net.*;
import mx.core.IMXMLObject;

[DefaultProperty("source")]

public class JavaScript extends EventDispatcher implements IMXMLObject 
{

	private var _source:String;
	private var _initialized:Boolean;

	public function JavaScript()
	{
		
	}

	public function set source(value:String):void 
	{
		if (value!=null)
		{

			
			_source = value;
			
			//old regexp
			//(/(\/\*([^*]|[\r\n]|(\*+([^*\/]|[\r\n])))*\*+\/)|(((?<!:)\/\/.*)/);
			var commentPattern:RegExp = /(\/\*([^*]|[\r\n]|(\*+([^*\/]|[\r\n])))*\*+\/)|((^|[^:\/])(\/\/.*))/g;
			
			//TBD:: replace all single quotes with double quotes - Needs to come up with better
			//regexp to keep single quotes within text as it is and only replace the one used in statements.
			//_source = _source.replace(/(\')/g,'\"');
		
			//remove all comments in js code	
			value = value.replace (commentPattern, "");
		
			//trace (_source);
			var u:URLRequest = new URLRequest ("javascript:eval('" + value + "');");
			navigateToURL(u,"_self");
		}
	}

	public function initialized(document:Object, id:String):void
	{

	
		_initialized = true;
	}

	override public function toString ():String
	{
		return _source;
	}
	
}

}

