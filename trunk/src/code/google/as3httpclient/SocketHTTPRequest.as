package code.google.as3httpclient
{
	import flash.net.URLRequestMethod;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.net.URLVariables;
	import flash.net.URLRequestHeader;
	
	/**
	 * This class is used by the SocketURLLoader class. The URLRequest class could not be extended,
	 * which is the reason that this class exists. It will extract more information from the url
	 * then the normal URLRequest.
	 * 
	 * @see SocketURLLoader
	 * @see http://livedocs.adobe.com/flex/2/langref/flash/net/URLRequest.html flash.net.URLRequest
	 */
	public class SocketHTTPRequest
	{
		/**
		 * Will create an instance of SocketHTTPRequest from the given URLRequest.
		 * 
		 * @param request The request used to create the SocketHTTPRequest instance.
		 */
		static public function createInstanceFromURLRequest(request:URLRequest):SocketHTTPRequest
		{
			var instance:SocketHTTPRequest = new SocketHTTPRequest();
			instance.url = request.url;
			instance.data = request.data;
			if (request.contentType)
			{
				instance.contentType = request.contentType;
			};
			instance.method = request.method;
			instance.requestHeaders = request.requestHeaders;
			
			return instance;
		};
		
		/**
		 * The contentType of the request, the default value is ContentType.APPLICATION_X_WWW_FORM_URLENCODED
		 * 
		 * @see ContentType
		 */
		public var contentType:String;
		
		/**
		 * The request headers to be included in the request. Note that the Content-Length header 
		 * is automatically set is the content has length. The Content-Type header is also 
		 * included by default.
		 */
		public var requestHeaders:Array;
		
		/**
		 * The given data will be handled differently depending on a few variables.<br />
		 * <br />
		 * If method is set to POST and contentType is set to ContentType.APPLICATION_X_WWW_FORM_URLENCODED:
		 * If data is ByteArray it will be written as is to the request, else the toString() method will 
		 * be called and the result will be written to the request.<br />
		 * <br />
		 * If method is set to POST and contentType is set to ContentType.MULTIPART_FORM_DATA:<br />
		 * If data is URLVariables it will create a part for each entry. This part will look 
		 * like this:<br />
		 * <br />
		 * "--{separator}"<br />
		 * Content-Disposition: form-data; name="{urlVariableName}"<br />
		 * {content}<br />
		 * <br />
		 * {separator} will be replaced by the separator.<br />
		 * {urlVariableName} will be replaced by the name of the the URLVariables entry.<br />
		 * {content} will be replaced by the data. If data is ByteArray it will be written directly, 
		 * 			 else the toString() method will be called and the result will be written.<br />
		 * @see http://livedocs.adobe.com/flex/2/langref/flash/utils/ByteArray.html flash.utils.ByteArray
		 * @see http://livedocs.adobe.com/flex/2/langref/flash/net/URLVariables.html flash.net.URLVariables
		 * 
		 * @throws ArgumentError Is thrown when method is POST,ContentType.MULTIPART_FORM_DATA and the data
		 * 						 is NOT of type URLVariables.
		 */
		public var data:Object;
		
		/*
			Getters / setters
		*/
		private var _url_str:String;
		private var _method_str:String;
		
		/*
			Getters
		*/
		private var _port_int:int;
		private var _baseURL_str:String;
		private var _extendedURL_str:String;
		
		/**
		 * Creates a new SocketHTTPRequest.<br />
		 * Defeaults the method to URLRequestMethod.GET and contentType to 
		 * ContentType.APPLICATION_X_WWW_FORM_URLENCODED.<br />
		 * <br />
		 * Note that the SocketHTTPRequest currently only supports urls that start 
		 * with http://.<br />
		 * @param url_str If given it will be passed to the url setter.
		 */
		public function SocketHTTPRequest(url_str:String = null)
		{
			requestHeaders = new Array();
			contentType = ContentType.APPLICATION_X_WWW_FORM_URLENCODED;
			method = URLRequestMethod.GET;
			if (url_str)
			{
				url = url_str;
			};
		};
		
		private function _parseURL():void
		{
			var url_str:String = _url_str;

			/*
				In the code below the url is parsed. This should be replaced by a 
				regular expression to reduce the amount of code.
			
				We currently only support requests that start with http://
			*/
			if (url_str.substr(0, 7) == "http://")
			{
				/*
					ignore authentication entry, use request headers to apply authentication
					In a future version we might decide to automatically convert these entries
					into an authentication header
				*/
				var authenticationEnd_int:int = url_str.indexOf("@");
				
				var hasAuthentication_bool:Boolean;
				if (authenticationEnd_int > -1)
				{
					hasAuthentication_bool = true;
				} else
				{
					authenticationEnd_int = 7;
				};
				
				/*
					Find the start of the port
				*/
				var portStart_int:int = url_str.indexOf(":", authenticationEnd_int);
				var hasPort_bool:Boolean;
				var portEnd_int:int;
				
				if (portStart_int > -1)
				{
					/*
						port found, extract it
					*/
					hasPort_bool = true;
					portEnd_int = url_str.indexOf("/", portStart_int);
					if (portEnd_int == -1)
					{
						portEnd_int = url_str.length;
					};
					_port_int = parseInt(url_str.substring(portStart_int + 1, portEnd_int));
				};
				
				/*
					The next if statement will extract the base url and set the extendedURLStart_int
					variable
				*/
				var extendedURLStart_int:int;
				if (hasAuthentication_bool && hasPort_bool)
				{
					_baseURL_str = url_str.substring(authenticationEnd_int + 1, portStart_int);
					extendedURLStart_int = portEnd_int;
				} else if (hasAuthentication_bool)
				{
					extendedURLStart_int = url_str.indexOf("/", authenticationEnd_int);
					if (extendedURLStart_int == -1)
					{
						extendedURLStart_int = url_str.length;
					};
					
					_baseURL_str = url_str.substring(authenticationEnd_int + 1, extendedURLStart_int);
				} else if (hasPort_bool)
				{
					_baseURL_str = url_str.substring(7, portStart_int);
					extendedURLStart_int = portEnd_int;
				} else
				{
					extendedURLStart_int = url_str.indexOf("/", 7);
					if (extendedURLStart_int == -1)
					{
						extendedURLStart_int = url_str.length;
					};
					
					_baseURL_str = url_str.substring(7, extendedURLStart_int);				
				};
				
				/* 
					if the extendedURLStart_int is smaller then the total url, get it from the url
				*/
				if (extendedURLStart_int > -1 && extendedURLStart_int < url_str.length)
				{
					_extendedURL_str = url_str.substr(extendedURLStart_int);
				};
			} else
			{
				throw new Error("SocketHTTPRequest: could not parse url, the url did not start with 'http://', this feature is not implemented yet");
			};
		};
		
		/**
		 * This method will construct the request and return it as a ByteArray. This 
		 * ByteArray can be used directly to make the request on the socket.
		 * 
		 * @see http://livedocs.adobe.com/flex/2/langref/flash/utils/ByteArray.html flash.utils.ByteArray
		 */
		public function constructRequest():ByteArray
		{
			/*
				If the method is POST, call both __constructHeader and __constrcutData methods.
			*/
			
			var methodIsPost_bool:Boolean = (method == URLRequestMethod.POST);
			
			var requestBA:ByteArray;
			if (methodIsPost_bool)
			{
				/*
					Create a boundary variable which might be needed for the MultiPart
					content type.
				*/
				var boundary_str:String = "------------Ij5Ef1Ef1Ij5Ij5cH2ei4gL6KM7KM7";
				
				var dataBA:ByteArray = __constructData(boundary_str);
				var contentLength_num:Number = dataBA.length;
				if (contentType == ContentType.MULTIPART_FORM_DATA)
				{
					contentLength_num -= 4;
				};
				requestBA = __constructHeader(contentLength_num, boundary_str);
				//add data
				requestBA.writeBytes(dataBA, 0, dataBA.length);
			} else
			{
				requestBA = __constructHeader(0, null);
			};
			
			return requestBA;
		};
		
		/**
		 * This method constructs the header of the request.
		 * 
		 * @param contentLength_num The length of the content.
		 * @param boundary_str The boundary which is only used if contentType is ContentType.MULTIPART_FORM_DATA
		 */
		protected function __constructHeader(contentLength_num:Number, boundary_str:String):ByteArray
		{
			var header_str:String = "";
			
			/*
				Add data to the extended URL if its given and the method is GET
			*/
			var extendedUrl_str:String = extendedURL ? extendedURL : "/";
			
			if (method == URLRequestMethod.GET && data)
			{
				if (extendedUrl_str.indexOf("?") == -1)
				{
					extendedUrl_str += "?";
				};
				
				extendedUrl_str += data.toString();
			};
			
			/*
				Create the first line of the header
			*/
			header_str += method + " " + extendedUrl_str + " HTTP/1.1" + HTTP_SEPARATOR;

			/*
				If a content length is given, add the request header for it
			*/
			if (contentLength_num)
			{
				header_str += "Content-Length: " + contentLength_num + HTTP_SEPARATOR;
			};
			
			/*
				Add the content type
			*/
			if (contentType)
			{
				header_str += "Content-Type: " + contentType;
			};
			
			/*
				If the content type is of multipart, add a boundary
			*/
			if (contentType == ContentType.MULTIPART_FORM_DATA)
			{
				header_str += "; boundary=" + boundary_str;
			};
			header_str += HTTP_SEPARATOR;

			/*
				Add additional request headers
			*/
			if(requestHeaders)
			{
				var requestHeader:URLRequestHeader;
				for each (requestHeader in requestHeaders)
				{
					header_str += requestHeader.name + ": " + requestHeader.value + HTTP_SEPARATOR;
				};
			};
			
			/*
				Add the host of the request
			*/
			var serverURL_str:String = baseURL;
			if (port)
			{
				serverURL_str += ":" + port;
			};			
			header_str += "Host: " + serverURL_str + HTTP_SEPARATOR;
			
			/*
				End the header
			*/
			header_str += HTTP_SEPARATOR;
			
			var headerBA:ByteArray = new ByteArray();
			headerBA.writeUTFBytes(header_str);
			
			return headerBA;
		};
		
		/**
		 * This method constructs the data that is send with the request. More information on 
		 * how data is handled can be found at the data property.
		 * 
		 * @see #data
		 */
		protected function __constructData(boundary_str:String):ByteArray
		{
			var dataBA:ByteArray = new ByteArray();
			
			if (data)
			{
				
				switch (contentType)
				{
					default:
					case ContentType.APPLICATION_X_WWW_FORM_URLENCODED:
						
						if (data is ByteArray)
						{
							dataBA.writeBytes(data as ByteArray, 0, (data as ByteArray).length);
						} else
						{
							dataBA.writeUTFBytes(data.toString());
						};
						
						break;
					case ContentType.MULTIPART_FORM_DATA:
					
						if (data is URLVariables)
						{
							
							var i:String;
							var value:Object;
							
							for (i in data)
							{
								value = data[i];
								dataBA.writeUTFBytes("--" + boundary_str + HTTP_SEPARATOR);
								dataBA.writeUTFBytes("Content-Disposition: form-data; name=\"" + i + "\"" + HTTP_SEPARATOR);
								dataBA.writeUTFBytes(HTTP_SEPARATOR);
								if (value is ByteArray)
								{
									dataBA.writeBytes(value as ByteArray, 0, (value as ByteArray).length);
								} else
								{
									dataBA.writeUTFBytes(value.toString());
								};
								dataBA.writeUTFBytes(HTTP_SEPARATOR);
							};							
							dataBA.writeUTFBytes("--" + boundary_str + "--" + HTTP_SEPARATOR);
						} else
						{
							throw new ArgumentError("SocketHTTPRequest: cannot create data stream when content type is set to MULTIPART_FORM_DATA and data is not of type URLVariables");
						};
					
						break;
					
				};
			};
			
			return dataBA;			
		};
		
		/**
		 * The url of the request. Note that currently only url's which start with http://
		 * can be parsed.
		 */
		public function get url():String
		{
			return _url_str;
		};
		
		public function set url(url_str:String):void
		{
			_url_str = url_str;
			_parseURL();
		};
		
		/**
		 * The method of the request. The default method is GET, valid values are 
		 * URLRequestMethod.GET and URLRequestMethod.POST.
		 * 
		 * @see http://livedocs.adobe.com/flex/2/langref/flash/net/URLRequestMethod.html flash.net.URLRequestMethod
		 * 
		 * @throws ArgumentError is the given method is not valid.
		 */
		public function get method():String
		{
			return _method_str;
		};
		
		public function set method(method_str:String):void
		{
			if (method_str == URLRequestMethod.GET || method_str == URLRequestMethod.POST)
			{
				_method_str = method_str;
			} else
			{
				throw new ArgumentError("SocketHTTPRequest: invalid method given, use values stored in the URLRequestMethod class");
			};
		};
		
		/**
		 * Gives the port from the URL
		 */
		public function get port():int
		{
			return _port_int;
		};	
		
		/**
		 * Gives the baseURL from the url, this could be seen as the server name.<br />
		 * <br />
		 * <code>http://www.mywebsite.com:8080/test/?id=100</code> will result in <code>www.mywebsite.com</code>
		 * as base url.
		 */
		public function get baseURL():String
		{
			return _baseURL_str;
		};
		
		/**
		 * Gives the extendedURL from the url, this is all extra information besides the
		 * server and port<br />
		 * <br />
		 * <code>http://www.mywebsite.com:8080/test/?id=100</code> will result in <code>/test/?id=100</code>
		 * as extended url.
		 */
		public function get extendedURL():String
		{
			return _extendedURL_str;
		};
	};
};