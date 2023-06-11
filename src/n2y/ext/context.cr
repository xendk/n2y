class HTTP::Server
  class Context
    def redirect(url : String | URI, status_code : Int32 = 302, *, body : String? = nil, close : Bool = true)
      @response.headers.add "Location", url.to_s
      @response.status_code = status_code
      @response.print(body) if body
      @response.close if close
    end
  end
end
