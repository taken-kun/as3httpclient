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

 /**
	_________________________________________________________________________________________________________________

	QueryString is a util class to get the query-string (name-value) pairs passed to html container of flex-apps.	
	@class QueryString (public)
	@author Abdul Qabiz (mail at abdulqabiz dot com) 
	@version 1.0 (4/24/2007)
	@availability 9.0+
	@usage<code>new QueryString ();</code>
	@example
		<code>
			queryString = new QueryString ();
		</code>
	__________________________________________________________________________________________________________________

	*/
package com.abdulqabiz.utils 
{
	import flash.external.*;
	import flash.utils.*;

	public class QueryString 
	{

		private var _queryString:String;
		private var _all:String;
		private var _params:Object;
		
		public function get queryString():String
		{
			return _queryString;
		}
		public function get url():String
		{
			return _all;
		}
		public function get parameters():Object
		{
			return _params;
		}		

		
		public function QueryString()
		{
		
			readQueryString();
		}

		private function readQueryString():void
		{
			_params = {};
			try 
			{
				_all =  ExternalInterface.call("window.location.href.toString");
				_queryString = ExternalInterface.call("window.location.search.substring", 1);
				if(_queryString)
				{
				
					var params:Array = _queryString.split('&');
					var length:uint = params.length;
					
					for (var i:uint=0,index:int=-1; i<length; i++) 
					{
						var kvPair:String = params[i];
						if((index = kvPair.indexOf("=")) > 0)
						{
							var key:String = kvPair.substring(0,index);
							var value:String = kvPair.substring(index+1);
							_params[key] = value;
						}
					}
				}
			}catch(e:Error) { trace("Some error occured. ExternalInterface doesn't work in Standalone player."); }
		}

	}
}
