package code.google.as3httpclient
{
	import flash.net.URLRequestHeader;
	
	/**
	 * This class is used by the SocketURLLoader to parse the HTTP response header
	 * 
	 * @see SocketURLLoader
	 */
	public class HTTPResponseHeader
	{
		private var _protocol_str:String;
		private var _status_int:int;
		private var _message_str:String;
		private var _contentLength_num:Number;
		
		private var _headers_arr:Array;
		private var _headers_obj:Object;
		
		/**
		 * @param completeHeader_str This is the complete HTTP response header.
		 */
		public function HTTPResponseHeader(completeHeader_str:String)
		{
			_headers_arr = new Array();
			_headers_obj = new Object();
			
			_parseHeader(completeHeader_str);
		};
		
		private function _parseHeader(completeHeader_str:String):void
		{
			var headers_arr:Array = completeHeader_str.split(HTTP_SEPARATOR);
			
			var info_str:String = headers_arr.shift() as String;
			var info_arr:Array = info_str.split(" ");
			
			_protocol_str = info_arr[0];
			_status_int = parseInt(info_arr[1]);
			if (info_arr.length > 2)
			{
				_message_str = info_arr[2];
			};
			
			var header_str:String;
			var name_str:String;
			var value_str:String;
			var header:URLRequestHeader
			var headerContent_arr:Array;
			
			for each (header_str in headers_arr)
			{
				headerContent_arr = header_str.split(": ");
				name_str = headerContent_arr[0];
				value_str = headerContent_arr[1];
				header = new URLRequestHeader(name_str, value_str);
				_headers_arr.push(header);
				_headers_obj[name_str] = value_str;
			};
		};
		
		/**
		 * Contains the protocol of the response
		 */
		public function get protocol():String
		{
			return _protocol_str;
		};
		
		/**
		 * Contains the status of the response
		 */
		public function get status():int
		{
			return _status_int;
		};
		
		/**
		 * Contains an array of URLRequestHeaders.
		 * 
		 * @see http://livedocs.adobe.com/flex/2/langref/flash/net/URLRequestHeader.html flash.net.URLRequestHeader
		 */
		public function get headers():Array
		{
			return _headers_arr;
		};
		
		/**
		 * This object contains all headers as a hash / lookup table. They are 
		 * inserted with the header name as key and header value as value.<br />
		 * <br />
		 * Note that if a header with the same name is found more then once it will 
		 * overwrite the previously set one.
		 */
		public function get headerObject():Object
		{
			return _headers_obj;
		};
		
		/**
		 * The message which is send along with the status code.
		 */
		public function get message():String
		{
			return _message_str;
		};
	};
};