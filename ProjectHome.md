This project is meant to extend the capabilities Adobe Flash Player 9 for HTTP/HTTPS related things.

Following are the objectives:-

  1. Support for HTTP Basic Authentication through HTTP/GET
  1. Way to get different HTTP status messages
  1. Add support for HTTPS

Background:-

One the classes is HTTPURLLoader, which was created to do HTTP Basic Authentication through HTTP/GET which is not doable with Adobe Flash Player 9 URLLoader API. For example, Bloglines API needs that kind of authentication.

HTTPURLLoader also provides different HTTP status messages and can be used for different HTTP methods.