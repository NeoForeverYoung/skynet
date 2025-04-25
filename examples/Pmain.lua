-- 引入skynet核心库，这是使用skynet框架的必要步骤
local skynet = require "skynet"
-- 引入skynet的socket模块，用于网络通信功能
local socket = require "skynet.socket"

-- 定义一个表来存储所有已连接的客户端
-- 使用文件描述符(fd)作为键，这样可以方便地管理和访问客户端
local clients = {}

-- 定义连接处理函数，当有新客户端连接到服务器时会调用此函数
-- fd: 文件描述符，用于标识这个连接
-- addr: 客户端的地址信息，通常是IP:端口格式
function connect(fd, addr)
    --启用连接
    print(fd.." connected addr:"..addr)
    -- 启用该连接，使其可以接收数据
    socket.start(fd)
    
    -- 将新连接的客户端添加到clients表中
    -- 这里使用空表作为值，可以在需要时存储客户端相关信息
    clients[fd] = {}
    
    --消息处理循环
    while true do
        -- 从连接中读取数据，如果客户端未发送数据则会阻塞等待
        local readdata = socket.read(fd)
        
        --正常接收到数据时
        if readdata ~= nil then
            -- 打印接收到的数据
            print(fd.." recv "..readdata)
            
            -- 遍历所有已连接的客户端，将消息广播给所有人
            -- 这是聊天室的核心功能：一个人发送的消息，所有人都能看到
            for i, _ in pairs(clients) do --广播
                socket.write(i, readdata)
            end
        --断开连接时
        else
            -- 打印关闭信息
            print(fd.." close ")
            -- 关闭socket连接，释放资源
            socket.close(fd)
            -- 从clients表中移除这个客户端
            -- 这样就不会再给它发送消息了
            clients[fd] = nil
            -- 退出消息处理循环
            break
        end
    end
end
    
-- skynet.start是服务的入口函数，传入一个匿名函数作为服务的主体逻辑
skynet.start(function()
    -- 创建一个监听socket，指定监听地址和端口
    -- "0.0.0.0"表示监听所有网络接口，8888是端口号
    local listenfd = socket.listen("0.0.0.0", 8888)
    
    -- 启动监听socket，并设置connect作为新连接的处理函数
    -- 当有新客户端连接时，skynet会自动调用connect函数处理
    socket.start(listenfd, connect)
end)