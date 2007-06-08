package fly.net
{
	import flash.events.EventDispatcher;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.net.URLRequest;
	import flash.net.URLLoaderDataFormat;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.net.URLVariables;
	import fly.net.HTTP_SEPARATOR;
	import flash.errors.IOError;

	/**
	 * Dispatched when the socket is closed.
	 */
	[Event(name="close", type="flash.events.Event")]
	
	/**
	 * Dispatched when the data has completed loading
	 */
	[Event(name="complete", type="flash.events.Event")]
	
	/**
	 * Dispatched when the socket is connected.
	 */
	[Event(name="open", type="flash.events.Event")]
	
	/**
	 * Dispatched when a socket throws an ioError
	 */
	[Event(name="ioError", type="flash.events.IOErrorEvent")]
	
	/**
	 * Dispatched when the socket throws a security error
	 */
	[Event(name="securityError", type="flash.events.SecurityErrorEvent")]
	
	/**
	 * Note that the progress event gives strange results for chunked data
	 * If the data received from the server is send chunked it will send progress 
	 * events for each separate chunk. That meanse that bytesLoaded and bytesTotal
	 * will count for the chunk that is currently being processed.
	 */
	[Event(name="progress", type="flash.events.ProgressEvent")]
	
	/**
	 * Dispatched if the header is received from the server
	 */
	[Event(name="httpStatus", type="flash.events.HTTPStatusEvent")]

	/**
	 * This class can in most cases be used as a replacement for the URLLoader class.
	 * It allows you to do things that are not possible with the URLLoader class:
	 * 
	 * - Authenticating without showing an authentication window on each request
	 * - Adding request headers that are not forbidden by the URLLoader class
	 * - Uploading files to a server that uses http authentication
	 * - Copying bytes (for example from images downloaded using this loader)
	 * 
	 * Note that to authenticate you need to include an authentication header. An 
	 * authentication header looks like this:
	 * 
	 * "Authorization: Basic" + Base64.encode(username + ":" + password))
	 * 
	 * If the data from the server does not contain a Content-Length header and the 
	 * Transfer-Encoding header is not set to chunked, results will be unexpected.
	 * 
	 */
	public class SocketURLLoader extends EventDispatcher
	{
		static private const _defaultPort_int:int = 80;
		
		private var _socket:Socket;
		private var _socketHTTPRequest:SocketHTTPRequest;
		
		private var _socketData:ByteArray;
		private var _headerFound_bool:Boolean;
		private var _contentLength_num:Number;
		private var _contentStart_num:Number;
		private var _contentIsChunked_bool:Boolean;
		
		private var _data:*;
		private var _bytesLoaded_uint:uint;
		private var _bytesTotal_uitn:uint;

		/**
		 * The format of the data that is retrieved from the request.
		 * 
		 * @see flash.net.URLLoaderDataFormat
		 */
		public var dataFormat:String;
		
		/**
		 * The reqeust is given to the load method if given. Defaults the dataFormat
		 * property to URLLoaderDataFormat.TEXT.
		 * 
		 * @see load
		 */
		public function SocketURLLoader(request:Object = null)
		{
			dataFormat = URLLoaderDataFormat.TEXT;
			
			_socket = new Socket();
			_socket.addEventListener(Event.CLOSE, _socketCloseHandler);
			_socket.addEventListener(Event.CONNECT, _socketConnectHandler);
			_socket.addEventListener(IOErrorEvent.IO_ERROR, _socketIOErrorHandler);
			_socket.addEventListener(ProgressEvent.SOCKET_DATA, _socketDataHandler);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _socketSecurityErrorHandler);
			
			if (request)
			{
				load(request);
			};
		};
		
		/**
		 * If the given request is of type URLRequest, the reqeust is converted to an instance of 
		 * SocketHTTPRequest.
		 * 
		 * If the socket is still open it will close the socket.
		 * 
		 * If no port could be extraced from the url, port 80 is used.
		 * 
		 * @param request An instance of URLRequest, SocketHTTPRequest or SocketHTTPFileRequest.
		 * 
		 * @throws ArgumentError if the request is not of type URLRequest, SocketHTTPRequest or SocketHTTPFileRequest
		 */
		public function load(request:Object):void
		{
			if (request is URLRequest)
			{
				_socketHTTPRequest = SocketHTTPRequest.createInstanceFromURLRequest(request as URLRequest);
			} else if (request is SocketHTTPRequest || request is SocketHTTPFileRequest)
			{
				_socketHTTPRequest = request as SocketHTTPRequest;
			} else
			{
				throw new ArgumentError("SocketURLLoader: the method load accepts only requests of the types 'URLRequest', 'SocketHTTPRequest' or 'SocketHTTPFileRequest'");
			};
			
			var port_int:int = _socketHTTPRequest.port ? _socketHTTPRequest.port : _defaultPort_int;
			
			close();
			
			_socket.connect(_socketHTTPRequest.baseURL, port_int);
		};
		
		/**
		 * If the socket is connected it will be closed.
		 * 
		 * @param dispatchEvent_bool if set to true a close event is dispatched.
		 */
		public function close(dispatchEvent_bool:Boolean = false):void
		{
			if (_socket.connected)
			{
				_socket.close();
				if (dispatchEvent_bool)
				{
					_socketCloseHandler(null);
				};
			};
		};
		
		/**
		 * @private
		 * 
		 * Resets all variables
		 */
		private function _reset():void
		{
			_socketData = new ByteArray();
			_headerFound_bool = false;
			_contentIsChunked_bool = false;
			_contentLength_num = NaN;
			_contentStart_num = NaN;
			_data = null;
		};
		
		/**
		 * @private
		 * 
		 * Sends the actual request
		 */
		private function _sendRequest():void
		{
			_reset();
			
			var encodedBytes:ByteArray = _socketHTTPRequest.constructRequest();
			_socket.writeBytes(encodedBytes);

			_socket.flush()				
		};
		
		/**
		 * @private
		 * 
		 * tries to find the header in the _socketData, if its found the _headerFound_bool and _contentStart_num
		 * variable are set. If the header contains a Content-Length entry the _contentLength_num variable is 
		 * also set.
		 * 
		 * Will dispatch an HTTPStatus event.
		 */
		private function _gatherHeader():void
		{
			_socketData.position = 0;
			var data_str:String = _socketData.readUTFBytes(_socketData.bytesAvailable);
			var headerEndIndex_int:int = data_str.indexOf(HTTP_SEPARATOR + HTTP_SEPARATOR);
			if (headerEndIndex_int > -1)
			{
				_headerFound_bool = true;
				
				var header:HTTPResponseHeader = new HTTPResponseHeader(data_str.substr(0, headerEndIndex_int));

				var httpStatusEvent:HTTPStatusEvent = new HTTPStatusEvent(HTTPStatusEvent.HTTP_STATUS, false, false, header.status);
				dispatchEvent(httpStatusEvent);
				
				var header_obj:Object = header.headerObject;
				
				if (header_obj.hasOwnProperty("Content-Length"))
				{
					_contentLength_num = Number(header_obj["Content-Length"]);
				} else if (header_obj.hasOwnProperty("Transfer-Encoding") && header_obj["Transfer-Encoding"] == "chunked")
				{
					_contentIsChunked_bool = true;
				};
				_contentStart_num = headerEndIndex_int + 4;
			};
			
		};
		
		/**
		 * @private
		 * 
		 * This method is used is the header contained a Content-Length entry. If the socket has enough 
		 * bytes available the data is parsed into the correct dataFormat, a complete event is 
		 * dispatched and the socket is closed. Else a progress event is dispatched.
		 */
		private function _gatherData():void
		{
			if (_contentLength_num > _socketData.bytesAvailable)
			{
				//waiting for more data
				var progressEvent:ProgressEvent = new ProgressEvent(ProgressEvent.PROGRESS, false, false, _socketData.bytesAvailable, _contentLength_num);
				dispatchEvent(progressEvent);
			} else
			{
				switch (dataFormat)
				{
					default:
					case URLLoaderDataFormat.TEXT:
						_data = _socketData.readUTFBytes(_contentLength_num);
						break;
					case URLLoaderDataFormat.VARIABLES:
						_data = new URLVariables(_socketData.readUTFBytes(_contentLength_num));
						break;
					case URLLoaderDataFormat.BINARY:
						var data:ByteArray = new ByteArray();
						_socketData.readBytes(data, 0, _contentLength_num);
						_data = data;
						break;
				};
				
				var completeEvent:Event = new Event(Event.COMPLETE);
				dispatchEvent(completeEvent);
				
				close(true);
			};
		};
		
		/**
		 * @private
		 * 
		 * This method is used if not Content-Length entry was found in the header and the Transfer-Encoding
		 * entry contained 'chunked'. If _contentLength_num has not beed set the length and start of the 
		 * content are determined.
		 * 
		 * If _contentLength_num is 0 all data has arrived, a complete event is dispatched and the socket is 
		 * closed. Else if _contentLength_num is less then the available bytes in the socket, a progress 
		 * event is dispatched.
		 * 
		 * If a chunk has arrived completely its added to the _data property.
		 */
		private function _gatherChunkedData():void
		{
			if (isNaN(_contentLength_num))
			{
				if (_socketData.bytesAvailable < 3)
				{
					//not enough bytes are available, lets wait
					return;
				};
				
				/*
					Get the size of the chunk
				*/
				var str:String = "";
				while (_socketData.readUTFBytes(2) != HTTP_SEPARATOR)
				{
					_socketData.position -= 2;
					str += _socketData.readUTFBytes(1);
				};
				_contentStart_num = _socketData.position;
				_contentLength_num = parseInt(str, 16);
			};
			
			if (!_contentLength_num)
			{
				//we are done, convert the data
				_data.position = 0;
				switch (dataFormat)
				{
					default:
					case URLLoaderDataFormat.TEXT:
						_data = _data.readUTFBytes(_data.bytesAvailable);
						break;
					case URLLoaderDataFormat.VARIABLES:
						_data = new URLVariables(_data.readUTFBytes(_data.bytesAvailable));
						break;
					case URLLoaderDataFormat.BINARY:
						//do nothing, the data is allready binary
						break;
				};
				
				var completeEvent:Event = new Event(Event.COMPLETE);
				dispatchEvent(completeEvent);
				
				close(true);
				
				return;					
			};
			
			if (_contentLength_num > _socketData.bytesAvailable)
			{
				//lets wait for more data
				var progressEvent:ProgressEvent = new ProgressEvent(ProgressEvent.PROGRESS, false, false, _socketData.bytesAvailable, _contentLength_num);
				dispatchEvent(progressEvent);
				
			} else
			{
				if (!_data)
				{
					/*
						if the data object is null, create it as a byte array as its 
						easy to append data to it
					*/
					_data = new ByteArray();
				};
				
				/*
					Read the chunk into data
				*/
				var data:ByteArray = _data as ByteArray;
				_socketData.readBytes(data, data.length, _contentLength_num);
				
				if (_socketData.readUTFBytes(2) != HTTP_SEPARATOR)
				{
					throw new IOError("SocketURLLoader: could not parse datastream, was expecting CRLF (Carriage return + Line feed).");
				};
				
				_contentLength_num = NaN;
				_contentStart_num = _socketData.position;
				
				/*
					Call this method again, there might be another chunk waiting in the _socketData
				*/
				_gatherChunkedData();
			};			
		};
		
		private function _socketCloseHandler(e:Event):void
		{
			var closeEvent:Event = new Event(Event.CLOSE);
			
			dispatchEvent(closeEvent);
		};
		
		/**
		 * @private
		 * 
		 * The socket is connected, dispatch an open event and send the request
		 */
		private function _socketConnectHandler(e:Event):void
		{
			var openEvent:Event = new Event(Event.OPEN);
			
			dispatchEvent(openEvent);
			
			_sendRequest();
		};
		
		/**
		 * @private
		 * 
		 * If the IOError is not handled throw an Error
		 */
		private function _socketIOErrorHandler(e:IOErrorEvent):void
		{
			if (hasEventListener(IOErrorEvent.IO_ERROR))
			{
				dispatchEvent(e);
			} else
			{
				throw new Error("SocketURLLoader: unhandled IOErrorEvent #" + e.text + ": " + e.text);
			};
		};
		
		/**
		 * @private
		 * 
		 * If the header was not found, try to find it by calling the _gatherHeader method,
		 * else, try to gather the data.
		 */
		private function _socketDataHandler(e:ProgressEvent):void
		{
			_socket.readBytes(_socketData, _socketData.length, _socket.bytesAvailable);
			
			if (!_headerFound_bool)
			{
				_gatherHeader();
			};

			if (_headerFound_bool)
			{
				_socketData.position = _contentStart_num;
				
				if (_contentIsChunked_bool)
				{
					_gatherChunkedData();
				} else
				{
					_gatherData();
				};
			};
		};
		
		/**
		 * @private
		 * 
		 * If the IOError is not handled throw an Error
		 */
		private function _socketSecurityErrorHandler(e:SecurityErrorEvent):void
		{
			if (hasEventListener(SecurityErrorEvent.SECURITY_ERROR))
			{
				dispatchEvent(e);
			} else
			{
				throw new Error("SocketURLLoader: unhandled SecurityError #" + e.text + ": " + e.text);
			};
		};
		
		/**
		 * Will contain the data as soon as the complete event has been dispatched
		 */
		public function get data():*
		{
			return _data;
		};
	};
};