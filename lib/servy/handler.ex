defmodule Servy.Handler do
    def handle(request) do
        request
        |> parse
        |> rewrite_path
        |> log
        |> route
        |> track
        |> format_response
    end

    def rewrite_path(%{path: "/wildlife"} = conv) do
        %{ conv | path: "/wildthings" }
    end

    def rewrite_path(conv), do: conv

    def log(conv), do: IO.inspect conv

    def parse(request) do
        [method, path, _] = 
            request 
            |> String.split("\n") 
            |> List.first
            |> String.split
        %{ 
            method: method,
            path: path,
            resp_body: "",
            status: nil 
        }
    end

    def route(%{method: "GET", path: "/wildthings"} = conv) do
        %{ conv | status: 200, resp_body: "Bears, Lions, Tigers" }
    end

    def route(%{method: "GET", path: "/bears"} = conv) do
        %{ conv | status: 200, resp_body: "Teddy, Smoking, Padding" }
    end

    def route(%{method: "GET", path: "/bears" <> id} = conv) do
        %{ conv | status: 200, resp_body: "Bear #{id}"}
    end

    def route(%{method: "GET", path: "/about"} = conv) do
        file = 
            Path.expand("../../pages", __DIR__)
            |> Path.join("about.html")
        
        case File.read(file) do
            {:ok, content} -> 
                %{ conv | status: 200, resp_body: content}
            {:error, :enoent} -> 
                %{ conv | status: 404, resp_body: "File not found!"}
            {:error, reason} -> 
                %{ conv | status: 500, resp_body: "File error: #{reason}"}
        end
    end

    def route(%{method: "DELETE", path: "/bears/" <> _id} = conv) do
        %{ conv | status: 403, resp_body: "Deleting a bear is forbidden!"}
    end

    def route(%{path: path} = conv) do
        %{ conv | status: 404, resp_body: "No #{path} here!" }
    end

    def track(%{status: 404, path: path} = conv) do
        IO.puts "Warning: #{path} is on the loose!"
        conv
    end

    def track(conv), do: conv
    
    def format_response(conv) do
        # TODO: Use values in the map to create an HTTP response string:
        """
        HTTP/1.1 #{conv.status} #{status_reason(conv.status)}
        Content-Type: text/html
        Content-Length: #{byte_size(conv.resp_body)}
        
        #{conv.resp_body}
        """
    end

    defp status_reason(code) do
        %{
          200 => "OK",
          201 => "Created",
          401 => "Unauthorized",
          403 => "Forbidden",
          404 => "Not Found",
          500 => "Internal Server Error"
        }[code]
    end
end



request = """
GET /wildthings HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

IO.puts Servy.Handler.handle(request)

request = """
GET /bears/1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

IO.puts Servy.Handler.handle(request)


request = """
GET /bigfoot HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

IO.puts Servy.Handler.handle(request)

request = """
DELETE /bears/1 HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

IO.puts Servy.Handler.handle(request)

request = """
GET /wildlife HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

IO.puts Servy.Handler.handle(request)

request = """
GET /about HTTP/1.1
Host: example.com
User-Agent: ExampleBrowser/1.0
Accept: */*

"""

IO.puts Servy.Handler.handle(request)