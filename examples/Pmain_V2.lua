-- 引入skynet核心库，这是使用skynet框架的必要步骤
local skynet = require "skynet"
-- 引入skynet的socket模块，用于网络通信功能
local socket = require "skynet.socket"

-- 定义连接处理函数，当有新客户端连接到服务器时会调用此函数
-- fd: 文件描述符，用于标识这个连接
-- addr: 客户端的地址信息，通常是IP:端口格式
function connect(fd, addr)
    -- 打印连接信息，显示哪个客户端已连接
    print(fd.." connected addr:"..addr)
    -- 启用该连接，使其可以接收数据
    -- 这一步非常重要，否则无法从连接中读取数据
    socket.start(fd)
    
    -- 进入消息处理循环，不断从客户端读取数据
    while true do
        -- 从连接中读取数据，如果客户端未发送数据则会阻塞等待
        local readdata = socket.read(fd)
        
        -- 如果读取到数据（不是nil），则处理这些数据
        if readdata ~= nil then
            -- 打印接收到的数据
            print(fd.." recv "..readdata)
            -- 将数据原样发送回客户端（这就是echo服务的核心）
            socket.write(fd, readdata)
        -- 如果读取到nil，表示连接已断开
        else
            -- 打印关闭信息
            print(fd.." close ")
            -- 关闭socket连接，释放资源
            socket.close(fd)
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