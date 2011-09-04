#!/usr/bin/env ruby
### http://www.maloninc.com/

# Copyright(c) 2011 Hiroyuki Nakamura
#
# Permission is hereby granted, free of  charge, to any person obtaining a copy
# of  this code, to  deal in  the code  without restriction,  including without
# limitation  the rights  to  use, copy,  modify,  merge, publish,  distribute,
# sublicense, and/or sell copies of the code, and to permit persons to whom the
# code is furnished to do so, subject to the following conditions:
#
#        The above copyright notice and this permission notice shall be
#        included in all copies or substantial portions of the code.
#
# THE  CODE IS  PROVIDED "AS  IS",  WITHOUT WARRANTY  OF ANY  KIND, EXPRESS  OR
# IMPLIED,  INCLUDING BUT  NOT LIMITED  TO THE  WARRANTIES  OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE  AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
# AUTHOR  OR  COPYRIGHT  HOLDER BE  LIABLE  FOR  ANY  CLAIM, DAMAGES  OR  OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF  OR IN CONNECTION WITH  THE CODE OR THE  USE OR OTHER  DEALINGS IN THE
# CODE.
#

require 'openssl'
require 'webrick'
require 'plist'
require 'erb'
require 'uuid'

server = WEBrick::HTTPServer.new(
  :Port            => 8888
)
trap("INT"){ server.shutdown }

server.mount_proc("/") { |req, res|
  res['Content-Type'] = "text/html"
  user_agent = req.header["user-agent"][0]
  if user_agent =~ /iPhone/i or user_agent =~ /iPad/i
    res.body = <<WELCOME_MESSAGE
    <style>
      body { margin:40px 40px;font-family:Helvetica;}
      h1 { font-size:80px; }
      p { font-size:60px; }
      a { text-decoration:none; }
    </style>

    <h1 >UDID Collector</h1>
    <p>
      This is UDID Collector.
      To start UDID collection, click <a href="/enroll">enroll</a>
    </p>
WELCOME_MESSAGE
  else
    @table = []
    open("udid-list.csv") {|file|
      while l = file.gets
        fields = l.split(',')
        @table.push({"timestamp" => fields[0],
                     "udid"      => fields[1],
                     "imei"      => fields[2]
                    })
      end
    }
    f = open('pc.html')
    erb = ERB.new(f.read)
    res.body = erb.result
    f.close
  end
}

server.mount_proc("/enroll") { |req, res|
  res['Content-Type'] = "application/x-apple-aspen-config"
  f = open('init.mconfig')
  @host = req.request_uri.host
  @port = req.request_uri.port
  @chalenge = UUID.create_random.to_s
  @uuid = UUID.create_random.to_s
  erb = ERB.new(f.read)
  res.body = erb.result
  f.close
}

server.mount_proc("/profile") { |req, res|
  p7sign = OpenSSL::PKCS7.new(req.body)
  store = OpenSSL::X509::Store.new
  p7sign.verify(nil, store, nil, OpenSSL::PKCS7::NOVERIFY)
  plist = Plist::parse_xml(p7sign.data)
  # p plist
  f = open("udid-list.csv", "a")
  f.puts "#{DateTime.now.to_s},#{plist["UDID"]},#{plist["IMEI"]}"
  f.close
}

server.mount_proc("/download") { |req, res|
  res['Content-Type'] = "text/csv"
  f = open('udid-list.csv')
  res.body = f.read
  f.close
}

server.mount_proc("/clear") { |req, res|
  # make the csv file empty
  f = open('udid-list.csv', "w")
  f.close
  res.set_redirect(WEBrick::HTTPStatus::SeeOther, '/')
}

server.start
