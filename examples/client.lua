-- 设置Lua C扩展库的搜索路径
package.cpath = "luaclib/?.so"
-- 设置Lua脚本的搜索路径
package.path = "lualib/?.lua;examples/?.lua"

-- 检查Lua版本，确保使用Lua 5.4
if _VERSION ~= "Lua 5.4" then
	error "Use lua 5.4"
end

-- 导入必要的模块
local socket = require "client.socket"  -- 网络socket模块
local proto = require "proto"           -- 协议定义模块
local sproto = require "sproto"         -- 序列化协议模块

-- 创建协议主机和请求对象
-- host用于解析服务器到客户端(s2c)的消息
local host = sproto.new(proto.s2c):host "package"
-- request用于客户端向服务器(c2s)发送请求
local request = host:attach(sproto.new(proto.c2s))

-- 连接到服务器(127.0.0.1:8888)
local fd = assert(socket.connect("127.0.0.1", 8888))

-- 发送数据包函数
-- @param fd: socket文件描述符
-- @param pack: 要发送的数据包内容
local function send_package(fd, pack)
	-- 使用大端格式(>)打包数据，s2表示带2字节长度前缀的字符串
	local package = string.pack(">s2", pack)
	socket.send(fd, package)
end

-- 解包函数，从数据流中提取一个完整的数据包
-- @param text: 接收到的数据
-- @return: 提取出的数据包和剩余数据
local function unpack_package(text)
	local size = #text
	-- 检查数据是否至少包含2字节的长度信息
	if size < 2 then
		return nil, text
	end
	-- 解析前两个字节作为长度信息（大端格式）
	local s = text:byte(1) * 256 + text:byte(2)
	-- 检查数据是否完整
	if size < s+2 then
		return nil, text
	end

	-- 返回完整的数据包和剩余的数据
	return text:sub(3,2+s), text:sub(3+s)
end

-- 接收数据包函数
-- @param last: 上次接收但未处理完的数据
-- @return: 一个完整的数据包和剩余数据
local function recv_package(last)
	local result
	-- 尝试从上次剩余的数据中解包
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	-- 如果没有完整包，继续接收新数据
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"  -- 服务器关闭连接
	end
	-- 递归调用，尝试从合并后的数据中获取完整包
	return recv_package(last .. r)
end

-- 会话计数器，用于标识请求
local session = 0

-- 发送请求函数
-- @param name: 请求名称
-- @param args: 请求参数
local function send_request(name, args)
	session = session + 1
	-- 使用sproto序列化请求
	local str = request(name, args, session)
	-- 发送序列化后的请求
	send_package(fd, str)
	print("Request:", session)
end

-- 存储未处理完的数据
local last = ""

-- 打印请求信息的函数
-- @param name: 请求名称
-- @param args: 请求参数
local function print_request(name, args)
	print("REQUEST", name)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

-- 打印响应信息的函数
-- @param session: 会话ID
-- @param args: 响应参数
local function print_response(session, args)
	print("RESPONSE", session)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

-- 打印数据包内容函数
-- @param t: 包类型("REQUEST"或"RESPONSE")
-- @param ...: 包内容
local function print_package(t, ...)
	if t == "REQUEST" then
		print_request(...)
	else
		assert(t == "RESPONSE")
		print_response(...)
	end
end

-- 分发处理收到的数据包
local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		-- 如果没有完整的包，退出循环
		if not v then
			break
		end

		-- 分发处理收到的包，并打印内容
		print_package(host:dispatch(v))
	end
end

-- 主程序开始：发送初始化请求
-- 发送握手请求
send_request("handshake")
-- 设置一个键值对
send_request("set", { what = "hello", value = "world" })

-- 主循环
while true do
	-- 处理接收到的所有数据包
	dispatch_package()
	-- 读取标准输入命令
	local cmd = socket.readstdin()
	if cmd then
		if cmd == "quit" then
			-- 发送退出请求
			send_request("quit")
		else
			-- 发送获取请求
			send_request("get", { what = cmd })
		end
	else
		-- 无命令时短暂休眠，避免CPU占用过高
		socket.usleep(100)
	end
end
